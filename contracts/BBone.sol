// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./libraries/ReentrancyGuard.sol";

import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";

// solhint-disable mark-callable-contracts, indent

/// @title BBone token (BBone)
/// @author 0xPandita
/// @notice Reward token for Bobtail.games, this token cannot be
/// bought, only sold and is rewarded by staking or playing.

contract BBone is ERC20, Ownable, ReentrancyGuard {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The TraderJoe router to add liquidity
    IJoeRouter02 private immutable joeRouter;

    /// @notice The pair BBone-WAVAX created at deploy
    address public immutable joePair;

    constructor(address _router) ERC20("Bobtail Bone", "BBone") {
        _mint(msg.sender, 1_000_000 * 10**decimals());

        IJoeRouter02 _joeRouter = IJoeRouter02(_router);

        // Create a TraderJoe pair
        joePair = IJoeFactory(_joeRouter.factory()).createPair(
            address(this),
            _joeRouter.WAVAX()
        );
        // Add TraderJoe pair to disallow buying
        swapPairs[joePair] = true;
        // set the rest of the contract variables
        joeRouter = _joeRouter;
    }

    /*///////////////////////////////////////////////////////////////
                STAKING/MATCH MANAGER SETUP/CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The staking manager is allowed to pay rewards
    address public stakingManager;

    /// @notice The match manager is allowed to pay rewards
    address public matchManager;

    /// @notice This is called only on deployment and can't be called again
    function initialSetup(address _staking, address _matchManager)
        external
        onlyOwner
    {
        // Only allow setup one time
        require(address(0) == stakingManager, "Setup failed");
        stakingManager = _staking;
        matchManager = _matchManager;
    }

    /// @notice Set staking manager
    function setStakingManager(address _address) external onlyOwner {
        stakingManager = _address;
    }

    /// @notice Set staking manager
    function setMatchManager(address _address) external onlyOwner {
        matchManager = _address;
    }

    /*///////////////////////////////////////////////////////////////
                    LIQUIDITY CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Contracts that allowed to add liquidity
    mapping(address => bool) private bobtailContracts;

    /// @notice LP pairs to disallow buys
    mapping(address => bool) private swapPairs;

    /// @notice Add contract allowed to add liquidity
    function addBobtailContract(address _address, bool _status)
        external
        onlyOwner
    {
        bobtailContracts[_address] = _status;
    }

    /// @notice Add LP pair to swapPairs to prevent buying
    function addSwapPair(address _address, bool _status) external onlyOwner {
        swapPairs[_address] = _status;
    }

    /*///////////////////////////////////////////////////////////////
                    LIQUIDITY LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @notice This is called by Bobtail token and NFT contracts allowed to add liquidity.
    function addLiquidity(uint256 balanceAvax) external nonReentrant {
        // Only allowed matchManager
        require(bobtailContracts[msg.sender], "Caller is not bobtail contract");
        // The necessary avax balance must be sent before calling this
        require(address(this).balance >= balanceAvax, "Not enough balance");
        // Create swap path
        address[] memory path = new address[](2);
        path[0] = joeRouter.WAVAX();
        path[1] = address(this);
        // Calculate the amount of BBone to add to liquidity
        uint256[] memory amounts = joeRouter.getAmountsOut(balanceAvax, path);
        // Mint the amount of BBone to this contract
        _mint(address(this), amounts[1]);
        // add liquidity to DEX
        // approve transfer BBone to TraderJoe router to cover all possible scenarios
        _approve(address(this), address(joeRouter), amounts[1]);
        // add the liquidity
        joeRouter.addLiquidityAVAX{value: balanceAvax}(
            address(this),
            amounts[1],
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    /*///////////////////////////////////////////////////////////////
                    STAKING AND MATCH REWARD LOGIC
    //////////////////////////////////////////////////////////////*/

    //TODO
    /// @notice Pay staking rewards
    function payStakingReward(address _to, uint256 _amount)
        external
        nonReentrant
    {
        // Only allow stakingManager
        require(stakingManager == msg.sender, "Caller is not stakingManager");
        require(_amount > 0, "Incorrect amount");
        // Mint the amount required
        _mint(_to, _amount);
    }

    /// @notice Pay rewards for match
    function payMatchReward(address _to, uint256 _amount)
        external
        nonReentrant
    {
        // Only allow matchManager
        require(matchManager == msg.sender, "Caller is not matchManager");
        // Mint the amount required
        _mint(_to, _amount);
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

    /// @dev Required for the contract to receive unwrapped AVAX.
    receive() external payable {}
}
