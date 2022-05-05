// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBBone.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";
import "hardhat/console.sol";

/// @title Bobtail token (Bobtail)
/// @author 0xPandita
/// @notice Governance and future gas token for subnet
contract Bobtail is ERC20, Ownable {
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
        _mint(msg.sender, 1_000_000_000 * 10**decimals());
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
    function setLPPair(address _pair, bool _enabled) external onlyOwner {
        lpPairs[_pair] = _enabled;
        emit LpPairsUpdated(_pair, _enabled);
    }

    /*///////////////////////////////////////////////////////////////
                        LEVEL/EXP STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice LP pairs to take fee on buy and sell
    mapping(address => bool) private levelAndExp;

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
        address _from,
        address _to,
        uint256 _amount
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
            uint256 tokensToLock = (_amount * feePercentage) / (10**2);
            // take the fee and send those tokens to this contract address
            // and then send the remainder of tokens to original recipient
            uint256 tokensToTransfer = _amount - tokensToLock;
            super._transfer(_from, address(this), tokensToLock);
            super._transfer(_from, _to, tokensToTransfer);
        } else {
            // Don't take fee
            super._transfer(_from, _to, _amount);
        }

        updateTimeShare(_from);
        updateTimeShare(_to);
    }

    ///@dev instead of keeping time share balance, we could simply mint time share token
    ///but this would make every transfer consume a little more gas, and would be subjectively less clean
    struct TimeShare {
        uint256 lastBlockTimestamp;
        uint256 lastBalance;
    }

    mapping(address => TimeShare) public timeShares;

    //no need to log block number explicitly
    event UpdateTimeShare(address indexed owner, uint256 balance);

    ///@notice update time share balance available to _address at current block
    function updateTimeShare(address _address) internal {
        TimeShare storage timeShare = timeShares[_address];

        if (timeShare.lastBlockTimestamp != 0) {
            timeShare.lastBalance = timeShareBalanceOf(_address);
        }

        timeShare.lastBlockTimestamp = block.timestamp;

        emit UpdateTimeShare(_address, timeShare.lastBalance);
    }

    /**
      @notice get time share balance available to _address at current block
      @dev formula to calculate the amount of TST the address is entitled at block:
      x = last_updated_balance + holding_duration/blocks_in_year * days_in_year * percentage_of_tokens_owned
      where 
      holding_duration = block.number - last_updated_block_number
      percentage_of_tokens_owned = balance / total_supply 
      @return holdingDuration share balance
    */
    function timeShareBalanceOf(address _address)
        public
        view
        returns (uint256 holdingDuration)
    {
        TimeShare memory timeShare = timeShares[_address];

        holdingDuration = block.timestamp - timeShare.lastBlockTimestamp;
        uint256 percentageOfTokensOwned = totalSupply() / balanceOf(_address);

        uint256 tmp = holdingDuration * balanceOf(_address) * 365 * 10e17;
        /*
        
        timeShare.lastBalance.add(
            block
                .number
                .sub(timeShare.lastBlockNumber)
                .mul(balances[_address])
                .mul(daysInYear)
                .mul(10e17)
                .div(blocksInYear.mul(totalSupply_))
        );
        */
        // return tmp / totalSupply();
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
        bboneToken.addLiquidity(newBalanceAvax, IBBone.LiquidityType.SWAP);

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
                          RECIEVE AVAX LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Required for the contract to receive unwrapped AVAX.
    receive() external payable {}
}
