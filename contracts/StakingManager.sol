// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailMatchManager.sol";
import "./interfaces/IBBone.sol";

// solhint-disable mark-callable-contracts

/// @title Bobtail Staking Manager 1.0 (StakingManager)
/// @author 0xPandita
/// @notice This contract controls the staking status for the Bobtail.games NFT
/// tokens and allows to claim the reward based on the time staked, this contract
/// only allow one ERC721 contract(FlappyAVAX) and will be updated(replaced) in
/// the future for a version 2.0 currently in development.
/// All of the administrative functions use a timelock, for more info check our
/// white paper

contract StakingManager is Ownable {
    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    /// @notice The allowed NFT contract(FlappyAVAX) to check current status of a token
    IBobtailNFT public immutable flappyAvax;

    /// @notice The bbone contract to claim reward
    IBBone public immutable bbone;

    constructor(address _bbone, address _flappyAvax) {
        bbone = IBBone(_bbone);
        flappyAvax = IBobtailNFT(_flappyAvax);
    }

    /*///////////////////////////////////////////////////////////////
                        MATCH MANAGER CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The Bobtail MatchManager to check if a token is in match
    /// and prevent unstaking
    IBobtailMatchManager public matchManager;

    /// @notice Emitted when the MatchManager is updated.
    event MatchManagerUpdated(address matchDuration);

    /// @notice Set the match manager
    function setMatchManager(address _matchManager) external onlyOwner {
        // Update match manager
        matchManager = IBobtailMatchManager(_matchManager);
        emit MatchManagerUpdated(_matchManager);
    }

    /*///////////////////////////////////////////////////////////////
                            REWARD CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The reward to be claimed in BBone for each minute of the staked token
    /// example with default values 10 minutes=10 BBone
    uint256 public rewardPerMinute = 1 ether; // Default 1 BBone

    /// @notice Emitted when the reward per minute is updated.
    event RewardPerMinuteUpdated(uint256 rewardPerMinute);

    /// @notice Set new reward per minute
    function setRewardPerMinute(uint256 _rewardPerMinute) public onlyOwner {
        // Only allow a range between 1 and 1000 to prevent exploits
        require(
            _rewardPerMinute > 0 && _rewardPerMinute < 1000, // TODO MAX
            "Invalid value"
        );
        // Update the reward
        rewardPerMinute = _rewardPerMinute;
        emit RewardPerMinuteUpdated(_rewardPerMinute);
    }

    /*///////////////////////////////////////////////////////////////
                            STAKING CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Max allowed staking tokens per account
    uint256 public maxStakingTokensPerAccount = 10;

    /// @notice Emitted when the max allowed staked tokens is updated.
    event MaxStakingTokensPerAccountUpdated(uint256 maxStakingTokensPerAccount);

    /// @notice Set max staking tokens
    function setMaxStakingTokensPerAccount(uint256 _maxStakingTokensPerAccount)
        public
        onlyOwner
    {
        // Only allow a range between  1 and 49
        require(
            _maxStakingTokensPerAccount > 0 && _maxStakingTokensPerAccount < 50,
            "Invalid value"
        );
        // Update max staking tokens per account
        maxStakingTokensPerAccount = _maxStakingTokensPerAccount;
        emit MaxStakingTokensPerAccountUpdated(_maxStakingTokensPerAccount);
    }

    /*///////////////////////////////////////////////////////////////
                       STAKING/UNSTAKING/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a list of NFT token ids owned by sender
    /// @param _tokenIds An array of token ids to stake
    function stake(uint256[] calldata _tokenIds) external {
        /// Only allow a limited amount of tokens to stake = maxStakingTokensPerAccount
        require(
            (stakingCountForAddress[msg.sender] + _tokenIds.length) <
                maxStakingTokensPerAccount + 1,
            "Max tokens staked for account"
        );
        /// Loop for each token id
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            /// Only allow tokens owned from sender
            require(
                msg.sender == flappyAvax.ownerOf(_tokenIds[i]),
                "Sender must be owner"
            );
            /// Check if is staked and only allow unstaked tokens
            require(
                !stakedItems[_tokenIds[i]].staked,
                "Token currently staked"
            );
            /// Only continue if the token has been revealed(90 seconds after mint)
            require(
                flappyAvax.isRevealed(_tokenIds[i]),
                "Token should be revealed"
            );
            /// Store staking status for token id
            stakedItems[_tokenIds[i]].staked = true;
            /// Store staking timestamp token id
            stakedItems[_tokenIds[i]].timestampStake = block.timestamp;
            unchecked {
                /// Add 1 to staking count for address
                ++stakingCountForAddress[msg.sender];
            }
        }
    }

    /// @notice Withdraw reward and/or unstake tokens
    /// @param _tokenIds An array of token ids to stake
    /// @param _unstake If the tokens should be unstaked
    /// or only claim the reward
    function withdrawOrClaim(uint256[] memory _tokenIds, bool _unstake)
        external
    {
        //TODO Test withdraw for unowned token
        /// Total reward to claim
        uint256 totalReward;
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            /// Only allow tokens owned from sender
            require(
                msg.sender == flappyAvax.ownerOf(_tokenIds[i]),
                "Sender must be owner"
            );
            /// Get info of staked token in memory
            StakeEntity memory stakedToken = stakedItems[_tokenIds[i]];
            /// Only allow staked tokens
            require(stakedToken.staked, "Token not staked");
            /// The token should be staked for at least 63 seconds to prevent exploits
            require(
                (block.timestamp - stakedToken.timestampStake) >= 63,
                "Need 63 sec staked claim/unstake"
            );
            /// Get the calculated reward for this staked token and sum it to total to claim
            totalReward += stakingReward(_tokenIds[i]);
            /// Get actual level and experience of the token, as the token is staked
            /// the lvl and exp returned is in memory and will be stored at the end of this
            /// iteration
            (uint8 level, uint8 exp) = flappyAvax.getLevelAndExp(_tokenIds[i]);
            /// If the token needs to be unstaked store the state
            if (_unstake) {
                /// If the token is in a match can't be unstaked
                require(
                    !matchManager.tokenInMatch(_tokenIds[i]),
                    "Token in match can't unstake"
                );
                // Update staking status
                stakedItems[_tokenIds[i]].staked = false;
                // Set the staking checkpoint to years in the future to prevent exploits
                stakedItems[_tokenIds[i]].timestampStake =
                    block.timestamp +
                    900000 days;
                unchecked {
                    // Subtract 1 from staking count for address
                    --stakingCountForAddress[msg.sender]; // Gas optimization
                }
            } else {
                // If the token will not be unstaked update staking checkpoint
                // to count staking rewards after claim
                stakedItems[_tokenIds[i]].timestampStake = block.timestamp;
            }
            // Update the level and exp of the token id
            flappyAvax.setLevelAndExp(_tokenIds[i], level, exp);
        }
        // Finally the total reward of BBone is minted and transfered to sender
        if (totalReward > 0) {
            bbone.payStakingReward(msg.sender, totalReward);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            REWARD LOGIC
    //////////////////////////////////////////////////////////////*/
    /// @notice Calculate the reward of BBone for a staked NFT
    /// @dev This function is public for display purposes only,
    /// it is not used in storage functions.
    function stakingReward(uint256 _tokenId) public view returns (uint256) {
        require(_tokenId != 0, "Invalid token id");
        /// Only allow calculation of revealed tokens
        require(flappyAvax.isRevealed(_tokenId), "Token unrevealed");
        /// Get info of staked token in memory
        StakeEntity memory token = stakedItems[_tokenId];
        /// Only allow calculation of staked tokens
        require(token.staked, "Token not staked");
        /// Get elapsed time since staking checkpoint
        uint256 elapsed = block.timestamp - token.timestampStake;
        /// Get current level
        (uint8 level, ) = flappyAvax.getLevelAndExp(_tokenId);
        /// For every minute elapsed multiply by rewardPerMinute
        uint256 reward = rewardPerMinute * (elapsed / 1 minutes);
        /// If level is equal or greather than 100 the bonus is 100%,
        /// else 1 level = 1% reward, is coded like this to prevent exploits
        uint256 bonus;
        if (level >= 100) {
            bonus = (reward / 100) * 100;
        } else {
            bonus = (reward / 100) * level;
        }
        return bonus + reward;
    }

    /*///////////////////////////////////////////////////////////////
                            STAKED TOKENS STORAGE
    //////////////////////////////////////////////////////////////*/

    /// A struct containing the status of staking for a token
    /// @param staked if it's staked or not.
    /// @param timestampStake The checkpoint when it's staked or reward claimed.
    struct StakeEntity {
        bool staked;
        uint256 timestampStake;
    }

    /// @notice Maps token id to stake data.
    mapping(uint256 => StakeEntity) public stakedItems;

    /// @notice Maps address to staking count.
    mapping(address => uint256) public stakingCountForAddress;

    /// @notice Check if an address has staked tokens
    /// @dev This function for display purposes only,
    /// it is not used in storage functions.
    function isAddressStaking(address _address)
        external
        view
        returns (bool staked)
    {
        /// Get an array of staked tokens for address
        uint256[] memory tokenIds = _stakedTokensOf(_address);
        return tokenIds.length > 0;
    }

    /// @notice Check if a token is staked
    /// @return staked if it's staked or not.
    /// @return timestampStake The checkpoint when it's staked or reward claimed.
    function isStaked(uint256 _tokenId)
        external
        view
        returns (bool staked, uint256 timestampStake)
    {
        /// Get info of staked token in memory
        StakeEntity memory token = stakedItems[_tokenId];
        staked = token.staked;
        timestampStake = token.timestampStake;
    }

    /// @notice Staked tokens ids owned by account, it's not
    /// used in write operations just externally for read-only operations.
    function stakedTokensOf(address _account)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        /// Get array of staked tokens ids for response
        tokenIds = _stakedTokensOf(_account);
    }

    /// @notice Staked tokens with extended info owned by account, it's not
    /// used in write operations just externally for read-only operations.
    function stakedTokensWithInfoOf(address _account)
        external
        view
        returns (IBobtailNFT.NftEntityExtended[] memory)
    {
        /// Get array of staked tokens ids
        uint256[] memory tokenIds = _stakedTokensOf(_account);
        /// Get array of extended info based on passed ids
        return flappyAvax.getTokensInfo(tokenIds);
    }

    /// @notice Staked token ids of account, it's not used in write operations just externally
    /// for read-only operations.
    function _stakedTokensOf(address _account)
        private
        view
        returns (uint256[] memory)
    {
        /// Get list of tokens owned by account
        uint256[] memory tokenIdsOwned = flappyAvax.tokensOf(_account);

        /// Get staked token count for address
        uint256 stakedCount = stakingCountForAddress[_account];
        if (stakedCount > 0) {
            /// Create a result memory array with the size of staked tokens count
            uint256[] memory tokenIds = new uint256[](stakedCount);
            /// Temp index to store current index of staked tokens result
            uint256 tempIndex;
            /// Iterate for each token owned
            for (uint256 i = 0; i < tokenIdsOwned.length; ++i) {
                /// Check if is staked
                if (stakedItems[tokenIdsOwned[i]].staked) {
                    /// Add staked token id to array result
                    tokenIds[tempIndex] = tokenIdsOwned[i];
                    unchecked {
                        /// Add 1 to tempIndex of result
                        ++tempIndex; // gas optimization
                    }
                }
            }
            return tokenIds;
        }
        /// Return empty array
        return new uint256[](0);
    }
}
