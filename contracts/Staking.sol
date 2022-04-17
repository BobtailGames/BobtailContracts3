import "./libraries/ReentrancyGuard.sol";
import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailMatchManager.sol";
import "./interfaces/IBBone.sol";

// solhint-disable mark-callable-contracts

contract Staking is ReentrancyGuard {
    //We only have one at the moment
    address public allowedNftContractAddress;

    IBobtailNFT private allowedNftContract;
    address public matchManagerAddress;
    IBobtailMatchManager private matchManager;

    struct StakeEntity {
        bool staked;
        uint256 timestampStake;
        uint256 block;
    }

    mapping(uint256 => StakeEntity) public stakedItems;

    mapping(address => uint256) public stakingCountForAddress;
    uint256 public maxStakingTokensPerAccount = 10;
    uint256 public rewardPerMinute = 1 ether; // Default 1 BBone

    IBBone public immutable bbone;

    constructor(
        address _bbone,
        address _nftContract,
        address _matchManager
    ) {
        bbone = IBBone(_bbone);
        allowedNftContractAddress = _nftContract;
        allowedNftContract = IBobtailNFT(_nftContract);
        matchManagerAddress = _matchManager;
        matchManager = IBobtailMatchManager(_matchManager);
    }

    modifier onlyEOA() {
        require(msg.sender.code.length == 0, "Only EOA");
        _;
    }

    function stake(uint256[] calldata _tokenIds) external onlyEOA nonReentrant {
        // Tokens to stake should be greater or equal to balance
        require(
            allowedNftContract.balanceOf(msg.sender) >= _tokenIds.length,
            "Not enough balance"
        );
        // Only allow a limited amount of tokens to stake = maxStakingTokensPerAccount
        require(
            (stakingCountForAddress[msg.sender] + _tokenIds.length) <=
                maxStakingTokensPerAccount,
            "Max tokens staked for account"
        );

        for (uint256 i = 0; i < _tokenIds.length; ) {
            // Only allow tokens owned from sender
            require(
                msg.sender == allowedNftContract.ownerOf(_tokenIds[i]),
                "Sender must be owner"
            );

            StakeEntity memory token = stakedItems[_tokenIds[i]];
            // Only allow unstaked tokens
            require(!token.staked, "Token currently staked");
            // Only allow if the tokens has been revealed(90 seconds after mint)
            require(
                allowedNftContract.isRevealed(_tokenIds[i]),
                "Token should be revealed"
            );

            stakedItems[_tokenIds[i]].staked = true;
            stakedItems[_tokenIds[i]].timestampStake = block.timestamp;

            // Used for gas efficiency
            unchecked {
                ++stakingCountForAddress[msg.sender];
                ++i;
            }
        }
    }

    function withdraw(uint256[] memory _tokenIds, bool _unstake)
        external
        onlyEOA
        nonReentrant
    {
        uint256 totalReward;
        for (uint256 i = 0; i < _tokenIds.length; ) {
            // Get info of staked token
            StakeEntity memory stakedToken = stakedItems[_tokenIds[i]];
            require(stakedToken.staked, "Token not staked");
            // The token should be staked for at least 63 seconds to prevent exploits
            require(
                (block.timestamp - stakedToken.timestampStake) >= 63,
                "Need 63 sec staked claim/unstake"
            );
            // Calculate the reward for this token
            totalReward += stakingReward(_tokenIds[i]);
            // Get current level and experence of the token
            (uint8 level, uint8 exp) = allowedNftContract.getLevelAndExp(
                _tokenIds[i]
            );
            if (_unstake) {
                require(
                    !matchManager.tokenInMatch(_tokenIds[i]),
                    "Token in match can't unstake"
                );
                // Update staking status
                stakedItems[_tokenIds[i]].staked = false;
                stakedItems[_tokenIds[i]].timestampStake =
                    block.timestamp +
                    90000 days;
                unchecked {
                    --stakingCountForAddress[msg.sender];
                }
            } else {
                // Update staking timestamp
                stakedItems[_tokenIds[i]].timestampStake = block.timestamp;
            }

            allowedNftContract.setLevelAndExp(_tokenIds[i], level, exp);
            unchecked {
                ++i;
            }
        }
        bbone.mint(msg.sender, totalReward);
    }

    /// @notice Calculate the reward of BBone for a staked NFT
    function stakingReward(uint256 _tokenId) public view returns (uint256) {
        require(_tokenId != 0, "Invalid token id");
        require(allowedNftContract.isRevealed(_tokenId), "Token unrevealed");
        StakeEntity memory token = stakedItems[_tokenId];
        require(token.staked, "Token not staked");
        // Get elapsed time since staking checkpoint
        uint256 elapsed = block.timestamp - token.timestampStake;
        // Get level
        (uint8 level, ) = allowedNftContract.getLevelAndExp(_tokenId);
        // For every minute elapsed multiply by rewardPerMinute
        uint256 reward = rewardPerMinute * (elapsed / 60 seconds);
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

    function isStaked(uint256 _tokenId)
        external
        view
        returns (bool staked, uint256 timestampStake)
    {
        staked = stakedItems[_tokenId].staked;
        timestampStake = stakedItems[_tokenId].timestampStake;
    }
}
