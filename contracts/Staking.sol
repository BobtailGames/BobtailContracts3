// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/ReentrancyGuard.sol";
import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailMatchManager.sol";
import "./interfaces/IBBone.sol";

// solhint-disable mark-callable-contracts

contract Staking is ReentrancyGuard, Ownable {
    modifier onlyEOA() {
        require(msg.sender.code.length == 0, "Only EOA");
        _;
    }

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    //We only have one at the moment
    IBobtailNFT public allowedNftContract;
    IBobtailMatchManager immutable matchManager;

    IBBone public immutable bbone;

    constructor(address _bbone, address _matchManager) {
        bbone = IBBone(_bbone);
        matchManager = IBobtailMatchManager(_matchManager);
    }

    /*///////////////////////////////////////////////////////////////
                                INITIALIZATION
    //////////////////////////////////////////////////////////////*/

    function initializeContract(address _nftContract) public {
        allowedNftContract = IBobtailNFT(_nftContract);
    }

    /*///////////////////////////////////////////////////////////////
                            REWARD CONFIGURATION
    //////////////////////////////////////////////////////////////*/
    uint256 public rewardPerMinute = 1 ether; // Default 1 BBone

    event RewardPerMinuteUpdated(uint256 rewardPerMinute);

    /// @notice Emitted after a successful harvest.
    function setRewardPerMinute(uint256 _rewardPerMinute) public onlyOwner {
        require(
            _rewardPerMinute > 0 && _rewardPerMinute < 100, // TODO MAX
            "Invalid value"
        );
        rewardPerMinute = _rewardPerMinute;
        emit RewardPerMinuteUpdated(_rewardPerMinute);
    }

    /*///////////////////////////////////////////////////////////////
                            STAKING CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Max allowed staking tokens for account
    uint256 public maxStakingTokensPerAccount = 10;
    event MaxStakingTokensPerAccountUpdated(uint256 maxStakingTokensPerAccount);

    /// @notice Emitted after a successful harvest.
    function setMaxStakingTokensPerAccount(uint256 _maxStakingTokensPerAccount)
        public
        onlyOwner
    {
        require(
            _maxStakingTokensPerAccount > 0 && _maxStakingTokensPerAccount < 50,
            "Invalid value"
        );
        maxStakingTokensPerAccount = _maxStakingTokensPerAccount;
        emit MaxStakingTokensPerAccountUpdated(_maxStakingTokensPerAccount);
    }

    /*///////////////////////////////////////////////////////////////
                       STAKING/UNSTAKING/WITHDRAW LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Deposit a list of token ids owned by sender
    function stake(uint256[] calldata _tokenIds) external onlyEOA nonReentrant {
        // Only allow a limited amount of tokens to stake = maxStakingTokensPerAccount
        require(
            (stakingCountForAddress[msg.sender] + _tokenIds.length) <
                maxStakingTokensPerAccount + 1,
            "Max tokens staked for account"
        );
        // Loop to deposit tokens
        for (uint256 i = 0; i < _tokenIds.length; ) {
            // Only allow tokens owned from sender
            require(
                msg.sender == allowedNftContract.ownerOf(_tokenIds[i]),
                "Sender must be owner"
            );
            // Check if is staked and only allow unstaked tokens
            require(
                !stakedItems[_tokenIds[i]].staked,
                "Token currently staked"
            );
            // Only continue if the token has been revealed(90 seconds after mint)
            require(
                allowedNftContract.isRevealed(_tokenIds[i]),
                "Token should be revealed"
            );
            // Store staking status for token id
            stakedItems[_tokenIds[i]].staked = true;
            // Store staking timestamp token id
            stakedItems[_tokenIds[i]].timestampStake = block.timestamp;
            unchecked {
                // Add 1 to staking count for address
                ++stakingCountForAddress[msg.sender]; // Gas optimization
                ++i; // Gas optimization
            }
        }
    }

    /// @notice Withdraw reward and/or unstake tokens
    function withdraw(uint256[] memory _tokenIds, bool _unstake)
        external
        onlyEOA
        nonReentrant
    {
        //TODO Test withdraw for unowned token
        // Total reward to pay
        uint256 totalReward;
        for (uint256 i = 0; i < _tokenIds.length; ) {
            // Only allow tokens owned from sender
            require(
                msg.sender == allowedNftContract.ownerOf(_tokenIds[i]),
                "Sender must be owner"
            );
            // Get info of staked token
            StakeEntity memory stakedToken = stakedItems[_tokenIds[i]];
            // Only allow staked tokens
            require(stakedToken.staked, "Token not staked");
            // The token should be staked for at least 63 seconds to prevent exploits
            require(
                (block.timestamp - stakedToken.timestampStake) >= 63,
                "Need 63 sec staked claim/unstake"
            );
            // Get the reward for this staked token and add it to total
            totalReward += stakingReward(_tokenIds[i]);
            // Get actual level and experience of the token, as the token is staked
            // the lvl and exp returned will be stored at the end
            (uint8 level, uint8 exp) = allowedNftContract.getLevelAndExp(
                _tokenIds[i]
            );
            // If is needed to unstake store status of the token
            if (_unstake) {
                // If the token is in a match can't be unstaked
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
            // The level and exp of the token id is updated
            allowedNftContract.setLevelAndExp(_tokenIds[i], level, exp);
            unchecked {
                ++i; // gas optimization
            }
        }
        // Finally the total reward of BBone is minted and transfered to sender
        if (totalReward > 0) {
            bbone.payStakingReward(msg.sender, totalReward);
        }
    }

    /// @notice Calculate the reward of BBone for a staked NFT
    function stakingReward(uint256 _tokenId) public view returns (uint256) {
        require(_tokenId != 0, "Invalid token id");
        // Only allow calculation of revealed tokens
        require(allowedNftContract.isRevealed(_tokenId), "Token unrevealed");
        StakeEntity memory token = stakedItems[_tokenId];
        // Only allow calculation of revealed tokens
        require(token.staked, "Token not staked");
        // Get elapsed time since staking checkpoint
        uint256 elapsed = block.timestamp - token.timestampStake;
        // Get current level
        (uint8 level, ) = allowedNftContract.getLevelAndExp(_tokenId);
        // For every minute elapsed multiply by rewardPerMinute
        uint256 reward = rewardPerMinute * (elapsed / 1 minutes);
        uint256 bonus;
        // If level is equal or greather than 100 the bonus is 100%, else 1 level = 1% reward
        // is coded like this to prevent any exploit
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
    struct StakeEntity {
        bool staked;
        uint256 timestampStake;
    }

    /// @notice Maps token id to stake data.
    mapping(uint256 => StakeEntity) public stakedItems;

    /// @notice Maps address to staking count.
    mapping(address => uint256) public stakingCountForAddress;

    /// @notice Check if a token is staked
    function isStaked(uint256 _tokenId)
        external
        view
        returns (bool staked, uint256 timestampStake)
    {
        staked = stakedItems[_tokenId].staked;
        timestampStake = stakedItems[_tokenId].timestampStake;
    }

    /// @notice Staked tokens ids owned by account, it's not
    /// used in write operations just externally for read-only operations.
    function stakedTokensOf(address _account)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        // Get array of staked tokens ids for response
        tokenIds = _stakedTokensOf(_account);
    }

    /// @notice Staked tokens with extended info owned by account, it's not
    /// used in write operations just externally for read-only operations.
    function stakedTokensWithInfoOf(address _account)
        external
        view
        returns (IBobtailNFT.NftEntityExtended[] memory)
    {
        // Get array of staked tokens ids
        uint256[] memory tokenIds = _stakedTokensOf(_account);
        // Get array of extended info based on passed ids
        return allowedNftContract.getTokensInfo(tokenIds);
    }

    /// @notice Staked token ids of account, it's not used in write operations just externally
    /// for read-only operations.
    function _stakedTokensOf(address _account)
        private
        view
        returns (uint256[] memory)
    {
        // Get list of tokens owned by account
        uint256[] memory tokenIdsOwned = allowedNftContract.tokensOf(_account);

        // Get staked token count for address
        uint256 stakedCount = stakingCountForAddress[_account];
        if (stakedCount > 0) {
            // Create a result memory array with the size of staked tokens count
            uint256[] memory tokenIds = new uint256[](stakedCount);
            // Temp index to store current index of staked tokens result
            uint256 tempIndex;
            // Iterate for each token owned
            for (uint256 i = 0; i < tokenIdsOwned.length; ) {
                // Check if is staked
                if (stakedItems[tokenIdsOwned[i]].staked) {
                    // Add staked token id to array result
                    tokenIds[tempIndex] = tokenIdsOwned[i];
                    unchecked {
                        // Add 1 to tempIndex of result
                        ++tempIndex; // gas optimization
                    }
                }
                unchecked {
                    ++i; // gas optimization
                }
            }
            return tokenIds;
        }
        return new uint256[](0);
    }
}
