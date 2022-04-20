// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBBone.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";
import "hardhat/console.sol";

/// @title Bobtail token (Bobtail)
/// @author 0xPandita
/// @notice Governance and future gas token for subnet
contract Bobtail is ERC20, ERC20Permit, ERC20Votes, Ownable {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The TraderJoe router
    IJoeRouter02 private immutable joeRouter;

    /// @notice The BBone token used to add liquidity from taxed buys
    IBBone private immutable bboneToken;

    /// @notice The pair Bobtail-WAVAX created at deploy
    address public immutable joePair;

    constructor(address _router, address _bbone)
        ERC20("Bobtail.games", "BOBTAIL")
        ERC20Permit("Bobtail.games")
    {
        _mint(msg.sender, 87_000_000_000 * 10**decimals());
        IJoeRouter02 _joeRouter = IJoeRouter02(_router);

        // Create a uniswap pair for this new token
        joePair = IJoeFactory(_joeRouter.factory()).createPair(
            address(this),
            _joeRouter.WAVAX()
        );
        lpPairs[joePair] = true;

        // set the rest of the contract variables
        joeRouter = _joeRouter;
        bboneToken = IBBone(_bbone);
    }

    /*///////////////////////////////////////////////////////////////
                                FEE CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Fee percentage taken on buy and sell
    uint32 public feePercentage = 2; // 2%

    event FeePercentageUpdated(uint32 feePercentage);

    /// @notice Udate fee percentage only allow min=1% | max=9%
    /// fee above 9% doesn't make sense.
    function setFee(uint32 _feePercentage) external onlyOwner {
        require(
            _feePercentage > 0 && _feePercentage < 10,
            "Invalid fee: min 1% max 9%"
        );
        feePercentage = _feePercentage;
        emit FeePercentageUpdated(_feePercentage);
    }

    /*///////////////////////////////////////////////////////////////
                            MIN TOKENS CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Min tokens on contract to start a swap Bobtail->AVAX and add liquidity to bbone
    uint128 public minTokensBeforeSwap = 10;

    event MinTokensBeforeSwapUpdated(uint128 minTokensBeforeSwap);

    /// @notice Update min tokens to start a swap Bobtail->AVAX and add liquidity to bbone
    function setMinTokensBeforeSwap(uint32 _minTokensBeforeSwap)
        external
        onlyOwner
    {
        minTokensBeforeSwap = _minTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(_minTokensBeforeSwap);
    }

    /*///////////////////////////////////////////////////////////////
                            SWAP AND LIQUIFY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Take fee on swap and add liquidity to BBone
    bool public swapAndLiquifyEnabled;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    /// @notice Enable/disable take fee on swap and add liquidity to BBone
    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    /*///////////////////////////////////////////////////////////////
                            LP PAIRS CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice LP pairs to take fee on buy and sell
    mapping(address => bool) private lpPairs;

    event LpPairsUpdated(address pair, bool enabled);

    /// @notice Enable/disable LP pairs to take fee on buy and sell
    function setLpPair(address _pair, bool _enabled) external onlyOwner {
        lpPairs[_pair] = _enabled;
        emit LpPairsUpdated(_pair, _enabled);
    }

    /*///////////////////////////////////////////////////////////////
                           LOCK SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    bool private inSwapAndLiquify;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /*///////////////////////////////////////////////////////////////
                        TRANSFER AND TAKE FEE LOGIC
    //////////////////////////////////////////////////////////////*/

    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    /// @notice Override ERC20 _transfer to take fee
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        // Get balance of Bobtail in contract
        uint256 contractTokenBalance = balanceOf(address(this));
        // Check if contract balance is over the min number of tokens that
        // we need to initiate a swap + liquidity lock.
        bool overMinTokenBalance = contractTokenBalance >= minTokensBeforeSwap;
        // Also, don't get caught in a circular liquidity event.
        // Also, don't swap & liquify if sender is traderjoe pair and is disabled.
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !lpPairs[msg.sender] &&
            swapAndLiquifyEnabled
        ) {
            _swapAndLiquify(contractTokenBalance);
        }

        // take fee if is buying/selling and if is enabled swapAndLiquifyEnabled
        // and the lock swap is not active
        if (lpPairs[msg.sender] && swapAndLiquifyEnabled && !inSwapAndLiquify) {
            // calculate the number of Bobtail to take as a fee
            uint256 tokensToLock = (amount * feePercentage) / (10**2);
            // take the fee and send those tokens to this contract address
            // and then send the remainder of tokens to original recipient
            uint256 tokensToTransfer = amount - tokensToLock;
            super._transfer(from, address(this), tokensToLock);
            super._transfer(from, to, tokensToTransfer);
        } else {
            // Don't take fee
            super._transfer(from, to, amount);
        }
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        // split the contract balance into halves
        // uint256 half = contractTokenBalance / 2;

        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalance = address(bboneToken).balance;

        // swap tokens for ETH
        swapTokensForEth(contractTokenBalance);

        // how much AVAX and BBone did we just swap into?
        uint256 newBalanceAvax = address(bboneToken).balance - initialBalance;
        bboneToken.addLiquidity(newBalanceAvax);

        //TODO  emit SwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();

        _approve(address(this), address(joeRouter), tokenAmount);
        // make the swap
        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(bboneToken),
            block.timestamp
        );
    }

    /*///////////////////////////////////////////////////////////////
                FUNCTION OVERRIDES REQUIRED BY ERC20Votes
    //////////////////////////////////////////////////////////////*/
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20, ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
        internal
        override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    /*///////////////////////////////////////////////////////////////
                          RECIEVE AVAX LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Required for the contract to receive unwrapped AVAX.
    receive() external payable {}
}
