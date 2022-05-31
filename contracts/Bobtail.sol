// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBBone.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";
import "hardhat/console.sol";
import "@prb/math/contracts/PRBMathUD60x18.sol";

/// @title Bobtail token (Bobtail)
/// @author 0xPandita
/// @notice Governance and future gas token for subnet

// This is disabled because all the time function related have a minimum
// 60 seconds window to prevent exploits
// solhint-disable not-rely-on-time

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
    {
        _mint(msg.sender, 1_000_000_000 ether);
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

    /// @notice Fee percentage taken on buy and sell, this is added to $BBone liquidity
    uint32 public feePercentage = 2; // 2%

    event FeePercentageUpdated(uint32 feePercentage);

    /// @notice Udate fee percentage only allow min=1% and max=9%
    /// fee above 9% doesn't make sense.
    /// @param _feePercentage new fee percentage between 1 and 9
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
    /// @param _minTokensBeforeSwap New min tokens to start a swap
    function setMinTokensBeforeSwap(uint32 _minTokensBeforeSwap)
        external
        onlyOwner
    {
        // Update min tokens
        minTokensBeforeSwap = _minTokensBeforeSwap;
        emit MinTokensBeforeSwapUpdated(_minTokensBeforeSwap);
    }

    /*///////////////////////////////////////////////////////////////
                            SWAP AND LIQUIFY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Define whether the contract will use collected tax to provide
    /// liquidity onto the swap
    bool public swapAndLiquifyEnabled;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    /// @notice Enable or disable the feature to sent collected tokens from
    /// transaction fee to swap to provide liquidity
    /// @param _enabled enable or disable the feature
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
    /// @param _pair The address of the LP pair
    /// @param _enabled If true it will take fee on the pair
    function setLPPair(address _pair, bool _enabled) external onlyOwner {
        lpPairs[_pair] = _enabled;
        emit LpPairsUpdated(_pair, _enabled);
    }

    /*///////////////////////////////////////////////////////////////
                           LOCK SWAP LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Used by swapAndLiquify() method to signal whether we are already providing liquidity
    /// so that we don't fall into an infinite loop in that method
    bool private inSwapAndLiquify;

    /// @notice Modifier for preventing the contract from checking whether to provide liquidity
    /// when we are providing liquidity, this is used to prevent an infinite loop
    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    /*///////////////////////////////////////////////////////////////
                        LEVEL EXP STORAGE
    //////////////////////////////////////////////////////////////*/

    ///@dev instead of keeping time share balance, we could simply mint time share token
    ///but this would make every transfer consume a little more gas, and would be subjectively less clean
    struct ExpLevelData {
        uint256 lastTransferTimestamp;
        uint256 aditionalExp;
    }

    mapping(address => bool) public expAndLvlExcluded;
    mapping(address => ExpLevelData) public expAndLvl;

    event UpdateLevelExpTimestampFor(address indexed owner, uint256 timestamp);

    ///@notice Update last transfer timestamp for address
    ///@param _address Address to update date
    function updateLevelExpTimestampFor(address _address) internal {
        /// Don't allow from 0 address and excluded addresses
        if (_address != address(0) && !expAndLvlExcluded[_address]) {
            /// Store block timestamp
            expAndLvl[_address].lastTransferTimestamp = block.timestamp;
            emit UpdateLevelExpTimestampFor(_address, block.timestamp);
        }
    }

    /// @notice Get level and experience data for address
    /// @param _address The address to get data
    function levelExpDataFor(address _address)
        public
        view
        returns (
            uint256 experience,
            uint256 level,
            uint256 holdPercent,
            uint256 holdingDuration
        )
    {
        /// get current balance on memory
        uint256 balance = balanceOf(_address);
        /// get experience and level data for the address
        ExpLevelData memory expLvlData = expAndLvl[_address];

        /// If the balance is 0 or last transfer timestamp is 0 or
        /// the address is excluded we return 0
        if (
            balance == 0 ||
            expLvlData.lastTransferTimestamp == 0 ||
            expAndLvlExcluded[_address]
        ) {
            return (0, 0, 0, 0);
        }
        /// Get the holding duration = total seconds holding / 10 seconds
        holdingDuration = ((block.timestamp -
            expLvlData.lastTransferTimestamp) / 10 seconds);
        /// Get the holding percent of the account
        holdPercent = ((balance * 10e18) / totalSupply()) / 10e10;
        /// Sum hold percent and holding duration
        experience = holdPercent + holdingDuration;
        /// Level = 15 * √experience
        level = (15 * PRBMathUD60x18.sqrt(experience)) / 10e10;
    }

    /*///////////////////////////////////////////////////////////////
                        TRANSFER AND TAKE FEE LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Override ERC20 _transfer to take fee
    function _transfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal override {
        /// Get the amount of token collected from transaction fee and is now owned
        /// by this contract
        uint256 contractBobtailBalance = balanceOf(address(this));

        /// Check if contractBobtailBalance exceeds the minimum required to provide
        /// liquidity to swap
        bool overMinTokenBalance = contractBobtailBalance >=
            minTokensBeforeSwap;
        /// Initiate to provide liquidity if,
        /// 1. contractBobtailBalance exceeds the minimum required to provide liquidity to swap
        /// 2. We are not already providing liquidity as indicated by the inSwapAndLiquify
        /// (i.e. it should be false)
        /// 3. Sender is not a LP pair otherwise it may affect the swap itself
        /// 4. Contract is set to provide liquidity via the swapAndLiquifyEnabled flag
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !lpPairs[msg.sender] &&
            swapAndLiquifyEnabled
        ) {
            /// Add liquidity to swap
            _swapAndLiquify(contractBobtailBalance);
        }

        /// Take fee if is a LP pair and if is enabled swapAndLiquifyEnabled
        /// and the lock swap is not active
        if (lpPairs[msg.sender] && swapAndLiquifyEnabled && !inSwapAndLiquify) {
            /// calculate the number of Bobtail to take as a fee
            uint256 bobtailToLock = (_amount * feePercentage) / (10**2);
            /// take the fee and send those tokens to this contract address
            /// and then send the remainder of tokens to original recipient
            uint256 bobtailToTransfer = _amount - bobtailToLock;
            super._transfer(_from, address(this), bobtailToLock);
            super._transfer(_from, _to, bobtailToTransfer);
        } else {
            // Don't take fee
            super._transfer(_from, _to, _amount);
        }
        // Update timestamp of last transfer
        updateLevelExpTimestampFor(_from);
        updateLevelExpTimestampFor(_to);
    }

    function _swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {
        /// Capture the BBone contract current AVAX balance.
        /// This is so that we can capture exactly the amount of AVAX that the
        /// swap creates, and not make the liquidity event include any AVAX that
        /// has been manually sent to the contract
        uint256 initialBboneContractBalance = address(bboneToken).balance;
        /// swap BOBTAIL for AVAX
        _swapBobtailForAvax(contractTokenBalance);
        /// how much AVAX did we just swap into?
        uint256 newBalanceAvax = address(bboneToken).balance -
            initialBboneContractBalance;
        /// Call addLiquidity from the BBONE contract
        bboneToken.addLiquidity(newBalanceAvax, IBBone.LiquidityType.SWAP);
    }

    function _swapBobtailForAvax(uint256 _bobtailAmount) private {
        // Generate the TraderJoe pair path of Bobtail -> WAVAX
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();
        /// Approve the amount of bobtail to swap
        _approve(address(this), address(joeRouter), _bobtailAmount);
        // Make the swap
        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            _bobtailAmount,
            0, // accept any amount of AVAX
            path,
            address(bboneToken), // TODO Receiver of AVAX
            block.timestamp
        );
    }

    /*///////////////////////////////////////////////////////////////
                          RECIEVE AVAX LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Required for the contract to receive AVAX.
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
