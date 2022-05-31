// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";
import "./interfaces/IBBone.sol";

/// @title BBone token (BBone)
/// @author 0xPandita
/// @notice Reward token for Bobtail.games, this token cannot be
/// bought, only sold and is rewarded by staking or playing on
/// the ecosystem.

// This is disabled because all the time function related have a minimum
// 60 seconds window to prevent exploits
// solhint-disable not-rely-on-time

//TODO remover saldo extra de bbone y avax
contract BBone is ERC20, Ownable, IBBone {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The TraderJoe router to add liquidity
    IJoeRouter02 private immutable joeRouter;

    /// @notice The pair BBone-WAVAX created at deploy
    address public immutable joePair;

    /// @param _joeRouter The TraderJoe router contract address
    constructor(address _joeRouter) ERC20("Bobtail Bone", "BBone") {
        /// 1 $BBone is minted to set price on TraderJoe
        _mint(msg.sender, 1 ether);

        /// TraderJoe router to add liquidity
        IJoeRouter02 joeRouterTmp = IJoeRouter02(_joeRouter);

        // Create a TraderJoe pair BBone-WAVAX
        joePair = IJoeFactory(joeRouterTmp.factory()).createPair(
            address(this),
            joeRouterTmp.WAVAX()
        );
        // Add TraderJoe pair to disallow buying
        swapPairs[joePair] = true;
        // TODO emit event
        // set the rest of the contract variables
        joeRouter = joeRouterTmp;
    }

    /*///////////////////////////////////////////////////////////////
                        STAKING MANAGER CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The StakingManager allowed to mint staking rewards
    address public stakingManager;

    event StakingManagerUpdated(address _stakingManager);

    /// @notice Set staking manager
    /// @param _stakingManager The StakingManager contract address
    function setStakingManager(address _stakingManager) external onlyOwner {
        // Update staking manager
        stakingManager = _stakingManager;
        emit StakingManagerUpdated(_stakingManager);
    }

    /*///////////////////////////////////////////////////////////////
                        MATCH MANAGER CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The MatchManager allowed to mint playing rewards
    address public matchManager;

    event MatchManagerUpdated(address _matchManager);

    /// @notice Set match manager
    /// @param _matchManager The match manager contract address
    function setMatchManager(address _matchManager) external onlyOwner {
        // Update match manager
        matchManager = _matchManager;
        emit MatchManagerUpdated(_matchManager);
    }

    /*///////////////////////////////////////////////////////////////
                    ADD LIQUIDITY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Contracts allowed to call addLiquidity
    mapping(address => bool) private bobtailContracts;

    event BobtailContractUpdated(address _address, bool _status);

    /// @notice Set contract allowed to add liquidity
    /// @param _address The contract address to set status
    /// @param _status true=allowed
    function setBobtailContract(address _address, bool _status)
        external
        onlyOwner
    {
        // Update bobtail contract status
        bobtailContracts[_address] = _status;
        emit BobtailContractUpdated(_address, _status);
    }

    /*///////////////////////////////////////////////////////////////
                    LP PAIRS CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice LP pairs to disallow buys
    mapping(address => bool) private swapPairs;

    event SwapPairUpdated(address _address, bool _status);

    /// @notice Set LP pair to swapPairs to prevent buying
    /// @param _address The contract address to set status
    /// @param _status true=allowed
    function setSwapPair(address _address, bool _status) external onlyOwner {
        // Update LP pair status
        swapPairs[_address] = _status;
        emit SwapPairUpdated(_address, _status);
    }

    /*///////////////////////////////////////////////////////////////
                    LIQUIDITY LOGIC
    //////////////////////////////////////////////////////////////*/

    event LiquidityAdded(
        uint256 amountToken,
        uint256 amountAVAX,
        uint256 liquidity,
        LiquidityType liquidityType
    );

    /// @notice This is called by Bobtail token and NFT contracts allowed to add liquidity.
    /// @param _amountAvax amount of AVAX to be added
    /// @param _liquidityType enum with different types to identify the source
    /// SWAP, MINTING, OTHER
    function addLiquidity(uint256 _amountAvax, LiquidityType _liquidityType)
        external
    {
        // Only allowed and trusted Bobtail contracts
        require(bobtailContracts[msg.sender], "Caller is not bobtail contract");
        // The necessary avax balance must be sent before calling this
        require(address(this).balance >= _amountAvax, "Not enough balance");
        // Create swap path
        address[] memory path = new address[](2);
        path[0] = joeRouter.WAVAX();
        path[1] = address(this);

        // Calculate the amount of BBone to add to liquidity
        uint256[] memory amounts = joeRouter.getAmountsOut(_amountAvax, path);
        // Mint the amount of BBone to this contract
        _mint(address(this), amounts[1]);
        // add liquidity to DEX
        // approve transfer BBone to TraderJoe router to cover all possible scenarios
        _approve(address(this), address(joeRouter), amounts[1]);
        // add the liquidity
        (uint256 amountToken, uint256 amountAVAX, uint256 liquidity) = joeRouter
            .addLiquidityAVAX{value: _amountAvax}(
            address(this),
            amounts[1],
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
        emit LiquidityAdded(amountToken, amountAVAX, liquidity, _liquidityType);
    }

    /*///////////////////////////////////////////////////////////////
                    STAKING AND MATCH REWARD LOGIC
    //////////////////////////////////////////////////////////////*/

    event PayStakingReward(address _to, uint256 _amount);
    event PayMatchReward(address _to, uint256 _amount);

    /// @notice Pay staking rewards, can only be called by StakingManager
    function payStakingReward(address _to, uint256 _amount) external {
        // Only allow stakingManager
        require(stakingManager == msg.sender, "Caller is not stakingManager");
        require(_amount > 0, "Incorrect amount");
        // Mint the amount required
        _mint(_to, _amount);
        emit PayStakingReward(_to, _amount);
    }

    /// @notice Pay rewards for match, can only be called from MatchManager
    function payMatchReward(address _to, uint256 _amount) external {
        // Only allow matchManager
        require(matchManager == msg.sender, "Caller is not matchManager");
        // Mint the amount required
        _mint(_to, _amount);
        emit PayMatchReward(_to, _amount);
    }

    /*///////////////////////////////////////////////////////////////
                        TRANSFER HOOKS 
    //////////////////////////////////////////////////////////////*/
    /// @notice Hook before each transfer to be sure nobody can buy the token
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20) {
        super._beforeTokenTransfer(from, to, amount);
        require(!swapPairs[msg.sender], "Can't transfer from swap pair");
    }

    /*///////////////////////////////////////////////////////////////
                          RECIEVE AVAX LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @dev Required for the contract to receive AVAX.
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}
