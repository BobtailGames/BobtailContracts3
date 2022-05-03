// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./libraries/ReentrancyGuard.sol";

import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailStaking.sol";

import "./interfaces/IBBone.sol";

/// @title Bobtail Match Manager 1.0 (MatchManager)
/// @author 0xPandita
/// @notice This contract controls the creation of matchs for the Bobtail.games NFT
/// tokens and pays the reward based on the time staked, this contract only allow
/// one ERC721 contract, this contract will be updated in the future for a version
/// 2.0 currently in developmnent

contract Matchs is ReentrancyGuard, Ownable {
    modifier onlyEOA() {
        require(msg.sender.code.length == 0, "Only EOA");
        _;
    }
    struct Player {
        bool joined;
        bool claimed;
        uint256 rank;
        uint256 valueClaimed;
        uint256 timestamp;
        uint256 tokenId;
    }

    struct Match {
        bool started;
        bool finished;
        uint256 timestamp;
        uint256 duration;
        uint256 maxPlayers;
        uint256 slot;
        address[] playersAddress;
        mapping(address => Player) players;
        mapping(uint256 => uint256) claimedRanks;
    }
    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    IBBone public immutable bbone;
    IBobtailNFT public immutable allowedNftContract;

    constructor(
        address _mainSigner,
        address _bbone,
        address _contractAddress
    ) {
        mainSigner = _mainSigner;
        //Default regions
        serverRegions["NA"] = true;

        bbone = IBBone(_bbone);

        allowedNftContract = IBobtailNFT(_contractAddress);

        //Default reward portions
        portionRewardPerRank[0] = 2200; //22% #1
        portionRewardPerRank[1] = 1300; //13% #2
        portionRewardPerRank[2] = 700; //7% #3
        portionRewardPerRank[3] = 500; //5% #4
        portionRewardPerRank[4] = 300; //3% #5
        portionRewardPerRank[5] = 250; //2.5% #6 to #10
        portionRewardPerRank[6] = 200; //2% #11 to #20
        portionRewardPerRank[7] = 100; //1% #21 to #30
        portionRewardPerRank[8] = 50; //0.5% #31 to #40
        portionRewardPerRank[9] = 25; //0.25% #41 to #50
    }

    /*///////////////////////////////////////////////////////////////
                        STAKING MANAGER CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice How much a match should last
    IBobtailStaking public stakingManager;

    event StakingManagerUpdated(address matchDuration);

    /// @notice Set staking manager
    function setStakingManager(address _stakingManager) external onlyOwner {
        // Update staking manager
        stakingManager = IBobtailStaking(_stakingManager);
        emit StakingManagerUpdated(_stakingManager);
    }

    /*///////////////////////////////////////////////////////////////
                                REWARD CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice The total reward distributed to players per match
    uint256 public totalRewardPerMatch = 337;

    /// @notice The signer for messages that allows claim reward of a match
    address public mainSigner;

    event PortionRewardPerRankUpdated(uint256[] portionRewardPerRank);

    /// @notice The portion related to the percentage to be paid from the reward
    mapping(uint256 => uint256) private portionRewardPerRank;

    /// @notice Set rewards per rank
    function setPortionRewardPerRank(uint256[] calldata _portionRewardPerRank)
        public
        onlyOwner
    {
        // This function is coded to work with a array of length=10
        require(
            _portionRewardPerRank.length == 10,
            "Length of array should be 10"
        );
        // We sum all new settings for ranks
        uint256 total = _portionRewardPerRank[0] + // #1
            _portionRewardPerRank[1] + // #2
            _portionRewardPerRank[2] + // #3
            _portionRewardPerRank[3] + // #4
            _portionRewardPerRank[4] + // #5
            (_portionRewardPerRank[5] * 5) + // #6 to #10
            (_portionRewardPerRank[6] * 10) + // #11 to #20
            (_portionRewardPerRank[7] * 10) + // #21 to #30
            (_portionRewardPerRank[8] * 10) + // #31 to #40
            (_portionRewardPerRank[9] * 10); // #41 to #50
        // The sum of all new setting should be 10000 = 100%
        require(total == 10000, "Sum of rewards should be 10000");

        // Only allow values lower than 5001 = 50%
        require(
            _portionRewardPerRank[0] < 5001 &&
                _portionRewardPerRank[1] < 5001 &&
                _portionRewardPerRank[2] < 5001 &&
                _portionRewardPerRank[3] < 5001 &&
                _portionRewardPerRank[4] < 5001 &&
                _portionRewardPerRank[5] < 5001 &&
                _portionRewardPerRank[6] < 5001 &&
                _portionRewardPerRank[7] < 5001 &&
                _portionRewardPerRank[8] < 5001 &&
                _portionRewardPerRank[9] < 5001,
            "Invalid value <5001"
        );
        // Store new portion reward
        portionRewardPerRank[0] = _portionRewardPerRank[0];
        portionRewardPerRank[1] = _portionRewardPerRank[1];
        portionRewardPerRank[2] = _portionRewardPerRank[2];
        portionRewardPerRank[3] = _portionRewardPerRank[3];
        portionRewardPerRank[4] = _portionRewardPerRank[4];
        portionRewardPerRank[5] = _portionRewardPerRank[5];
        portionRewardPerRank[6] = _portionRewardPerRank[6];
        portionRewardPerRank[7] = _portionRewardPerRank[7];
        portionRewardPerRank[8] = _portionRewardPerRank[8];
        portionRewardPerRank[9] = _portionRewardPerRank[9];
        emit PortionRewardPerRankUpdated(_portionRewardPerRank);
    }

    /*///////////////////////////////////////////////////////////////
                        MATCH DURATION CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice How much a match should last
    uint256 public matchDuration = 10 minutes;

    event MatchDurationUpdated(uint256 matchDuration);

    /// @notice Set match duration
    function setMatchDuration(uint256 _matchDuration) external onlyOwner {
        // Oly allow a range between 10 seconds and 2 days to prevent exploits
        require(
            _matchDuration > 10 seconds && _matchDuration < 2 days,
            "Invalid duration"
        );
        // Update match duration
        matchDuration = _matchDuration;
        emit MatchDurationUpdated(_matchDuration);
    }

    /*///////////////////////////////////////////////////////////////
                    MAX PLAYERS PER MATCH CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice Max players allowed to join a match
    uint256 public maxPlayersPerMatch = 100;

    event MaxPlayersPerMatchUpdated(uint256 maxPlayersPerMatch);

    /// @notice Set max players allowed to join a match
    function setMaxPlayersPerMatch(uint256 _maxPlayersPerMatch)
        external
        onlyOwner
    {
        /// @notice Only allow a range between 1 and 1500 to prevent exploits
        require(
            _maxPlayersPerMatch > 0 && _maxPlayersPerMatch < 1501,
            "Invalid quantity"
        );
        // Update max players
        maxPlayersPerMatch = _maxPlayersPerMatch;
        emit MaxPlayersPerMatchUpdated(maxPlayersPerMatch);
    }

    /*///////////////////////////////////////////////////////////////
                                REGION CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice How many matchs can be active at the same time for region
    uint256 public matchCountPerRegion = 2;

    mapping(string => bool) public serverRegions;

    function setMatchsPerRegion(uint256 _matchCountPerRegion) external {
        require(
            _matchCountPerRegion > 0 && _matchCountPerRegion < 1000,
            "Invalid quantity"
        );
        matchCountPerRegion = _matchCountPerRegion;
    }

    function setServerRegion(string calldata _name, bool status) external {
        serverRegions[_name] = status;
    }

    /*///////////////////////////////////////////////////////////////
                                MATCH SLOTS STORAGE
    //////////////////////////////////////////////////////////////*/
    /// @notice Map Region to slot index then match id Region->SlotId->MatchId
    /// this map is to lock the contract allowing only the permited max match count
    mapping(string => mapping(uint256 => uint256)) private matchSlots;

    /*///////////////////////////////////////////////////////////////
                                MATCH STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice Current match id counter
    uint256 public matchIdCounter;

    /// @notice Map match id to Match struct
    mapping(uint256 => Match) public matchs;

    /// @notice Map address to current match, is used to prevent
    /// joining simultaneous matchs
    mapping(address => uint256) public currentMatchForAddress;

    /// @notice Map NFT token id to current match, is used to prevent
    /// joining simultaneous matchs
    mapping(uint256 => uint256) public currentMatchForToken;

    /// @notice Map match id of the last claimed reward
    mapping(address => uint256) public lastMatchIdClaimedForAccount;

    event NewMatch(
        uint256 matchId,
        uint256 slot,
        uint256 timestamp,
        uint256 duration,
        uint256 maxPlayers
    );

    event NewAddressInMatch(address player, uint256 matchId, uint256 tokenId);

    event RewardClaimed(address player, uint256[] matchIds, uint256 reward);

    /*///////////////////////////////////////////////////////////////
                                MATCH LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Join a new match with a allowed NFT
    function joinMatch(uint256 _tokenId, string calldata region)
        external
        onlyEOA
        nonReentrant
    {
        // Only if StakingManager is set
        require(
            address(stakingManager) != address(0),
            "StakingManager not set"
        );
        // Only allowed regions
        require(serverRegions[region], "Invalid region");
        // Invalid region TODO Test
        // Only valid Id's
        require(_tokenId != 0, "Invalid token id");
        // _tokenId should be owned by sender
        require(
            allowedNftContract.ownerOf(_tokenId) == msg.sender,
            "Token not owned from sender"
        );

        // Check is if staked
        (bool staked, ) = stakingManager.isStaked(_tokenId);
        // Should be staked
        require(staked, "Token should be staked");

        // Get current match for the token
        uint256 matchIdToken = currentMatchForToken[_tokenId];
        // If match id isn't 0 check if the match is active
        if (matchIdToken != 0) {
            // The token can't joint a new match if it's currenlty in one
            require(!isMatchActive(matchIdToken), "Currently in a match");
        }

        // Get current match for the sender
        uint256 matchId = currentMatchForAddress[msg.sender];
        // If match id isn't 0 check if the match is active
        if (matchId != 0) {
            // The sender can't joint a new match if it's currenlty in one
            require(!isMatchActive(matchId), "Currently in a match");
        }
        // Get a free slot to join match if it's available
        matchId = getMatchSlot(region);
        // A matchId is required
        require(matchId != 0, "No match available");
        // Set current match for token
        currentMatchForToken[_tokenId] = matchId;
        // Set current match for sender
        currentMatchForAddress[msg.sender] = matchId;
        // Add sender to array storage for view purposes
        matchs[matchId].playersAddress.push(msg.sender);
        // Store default data for address
        matchs[matchId].players[msg.sender] = Player({
            tokenId: _tokenId, // NFT Id
            joined: true, // The addres has joined the match
            claimed: false, // Reward hasn't been claimed
            rank: 0, // Default rank
            valueClaimed: 0, //Default value claimed //TODO
            timestamp: block.timestamp // Timestamp of joining
        });
        emit NewAddressInMatch(msg.sender, matchId, _tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                                REWARD LOGIC
    //////////////////////////////////////////////////////////////*/

    /// @notice Claim reward(s) of BBone for finished match(s),
    /// this function receives a signed message from the trusted
    /// account to pay reward of the requested matchs, the match
    /// should be finished and reward unclaimed for match, rank
    /// and account
    function claimReward(
        uint256[] calldata _matchIds,
        uint256[] calldata _ranks,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external onlyEOA nonReentrant {
        //TODO time signature
        // _matchIds and _ranks should be greater than zero
        require(_matchIds.length > 0 && _ranks.length > 0, "Invalid request");
        // _matchIds and _ranks should be equal
        require(_matchIds.length == _ranks.length, "Invalid request");
        // Get the message hash
        bytes32 messageHash = keccak256(
            abi.encode(_matchIds, _ranks, msg.sender, address(this))
        );

        // Get the signer message hash
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        // Verify if it's signed with allowed address
        require(
            ecrecover(ethSignedMessageHash, v, r, s) == mainSigner,
            "Wrong signature"
        );
        // Total reward of BBone to be payed
        uint256 totalReward;
        for (uint256 i = 0; i < _matchIds.length; ) {
            // Only allow valid ids
            require(_matchIds[i] > 0, "Match id invalid");
            // Only allow valid ranks 1-100
            require(_ranks[i] > 0 && _ranks[i] < 101, "Rank invalid");
            // Check if match has started
            require(matchs[_matchIds[i]].timestamp != 0, "Match isn't started");
            // Check if match is active
            require(!isMatchActive(_matchIds[i]), "Match is not finished");
            // Check if sender has joined the match
            require(
                matchs[_matchIds[i]].players[msg.sender].joined,
                "Address not in match"
            );
            //TODO test claim two times
            // Only claim one time
            require(
                matchs[_matchIds[i]].players[msg.sender].claimed == false,
                "Account and match reward claimed"
            );
            // Only claim one time per rank
            require(
                matchs[_matchIds[i]].claimedRanks[_ranks[i]] == 0,
                "Rank reward has been claimed"
            );
            // Get reward based on signed rank
            uint256 reward = calculateReward(_ranks[i]);
            // Set sender for this match as claimed
            matchs[_matchIds[i]].players[msg.sender].claimed = true;
            // Set rank for this match as claimed
            matchs[_matchIds[i]].claimedRanks[_ranks[i]] = 1;
            // Store value claimed for this match and sender
            matchs[_matchIds[i]].players[msg.sender].valueClaimed = reward;
            // Store rank for this match and sender
            matchs[_matchIds[i]].players[msg.sender].rank = _ranks[i];
            totalReward += reward;
            unchecked {
                ++i; // Gas optimization
            }
        }
        if (totalReward > 0) {
            // Pay total reward of matchs
            bbone.payMatchReward(msg.sender, totalReward);
            emit RewardClaimed(msg.sender, _matchIds, totalReward);
        }
    }

    /// @notice Get current match for address, it's not used in write operations just externally
    function matchForAddress(address _address)
        external
        view
        returns (
            uint256 matchId,
            bool finished,
            uint256 timestamp,
            uint256 duration,
            bool inMatch
        )
    {
        // Get current match for address
        matchId = currentMatchForAddress[_address];
        // If match id isn't 0 return status of match
        if (matchId != 0) {
            inMatch = true; // Is in match
            finished = !isMatchActive(matchId); // If match is finished
            timestamp = matchs[matchId].timestamp; // Match timestamp start
            duration = matchs[matchId].duration; // Stored match duration
        }
    }

    /// @notice Get current active match count,  it's not used in write operations just externally
    function activeMatchsCount(string calldata _region)
        external
        view
        returns (uint256 count)
    {
        // Loop that runs to match count per region
        for (uint256 i = 0; i < matchCountPerRegion; ) {
            // Get match id of the slot in that region
            uint256 matchIdTmp = matchSlots[_region][i];
            // If isn't 0 and it's active add one to count
            if (matchIdTmp != 0 && isMatchActive(matchIdTmp)) {
                unchecked {
                    ++count; // Gas optimization
                }
            }
            unchecked {
                ++i; // Gas optimization
            }
        }
    }

    /// @notice Get or create a match slot if is available
    function getMatchSlot(string calldata region)
        private
        returns (uint256 matchId)
    {
        // Count of active matchs
        uint256 currentActiveMatchs;
        // Slot index
        uint256 slot;
        // If slot for match has been asigned to create a new match
        bool slotAssigned = false;
        for (uint256 i = 0; i < matchCountPerRegion; ) {
            // Get current match id of slot index in region
            uint256 matchIdTmp = matchSlots[region][i];
            // If match if isn't 0 and it's active check if allow new players
            if (matchIdTmp != 0 && isMatchActive(matchIdTmp)) {
                // Check if player count in match is lower than max players allowed
                // stored at match creation
                if (
                    matchs[matchIdTmp].playersAddress.length <
                    matchs[matchIdTmp].maxPlayers
                ) {
                    // Match isn't full assign match id and end loop to return match id
                    // as result
                    matchId = matchIdTmp;
                    break;
                }
                unchecked {
                    // Add 1 to active matchs
                    ++currentActiveMatchs; // Gas optimization
                }
            } else {
                if (!slotAssigned) {
                    // If slot assigned is false assign slot index
                    slot = i;
                    // Set slot assigned to true to prevent assign other slot index
                    slotAssigned = true;
                }
            }
            unchecked {
                ++i; // gas optimization
            }
        }
        // Create new match
        if (
            slotAssigned && // Only if a free slot has been assigned
            matchId == 0 && // And if match id is 0(A match for player isn't active)
            currentActiveMatchs < matchCountPerRegion // And if current active matchs is
            // less than allowed matchs
        ) {
            unchecked {
                // Add 1 to match counter
                ++matchIdCounter; // Gas optimization
            }
            // Assign id to new match to be returned as result
            matchId = matchIdCounter;
            // Store match id in region slot
            matchSlots[region][slot] = matchId;
            // Instantiate match to store
            Match storage m = matchs[matchId];
            m.started = true; // Set match started
            m.finished = false; // Match hasn't finished
            m.timestamp = block.timestamp; // Current timestamp
            m.duration = matchDuration; // Store match duration to prevent bugs if it's updated during match
            m.maxPlayers = maxPlayersPerMatch; // Store max players to prevent bugs if it's updated during match
            m.slot = slot; // Save slot of match
            emit NewMatch(
                matchId,
                slot,
                block.timestamp,
                matchDuration,
                maxPlayersPerMatch
            );
        }
    }

    /// @notice Check if a token is in a active match
    function tokenInMatch(uint256 _tokenId) external view returns (bool) {
        // Get current match stored for token
        uint256 matchIdForToken = currentMatchForToken[_tokenId];
        // If match id isn't 0 check if match is active
        if (matchIdForToken != 0) {
            return isMatchActive(matchIdForToken);
        }
        return false;
    }

    /// @notice Check if match is active
    function isMatchActive(uint256 _matchId) private view returns (bool) {
        // Get time elapsed since match start and compare to duration stored
        // at creation of match
        return
            (block.timestamp - matchs[_matchId].timestamp) <
            matchs[_matchId].duration;
    }

    /// @notice Calculate the reward for the rank of one match, Of all the totalRewardPerMatch a
    /// portion is distributed to the leaderboard based on the rank
    function calculateReward(uint256 _rank) private view returns (uint256) {
        // Get portion based on rank
        uint256 portion;
        if (_rank >= 1 && _rank <= 5) {
            //#1 to #5
            portion = portionRewardPerRank[_rank - 1];
        } else if (_rank >= 6 && _rank <= 10) {
            //#6 to #10
            portion = portionRewardPerRank[5];
        } else if (_rank >= 11 && _rank <= 20) {
            //#11 to #20
            portion = portionRewardPerRank[6];
        } else if (_rank >= 21 && _rank <= 30) {
            //#21 to #30
            portion = portionRewardPerRank[7];
        } else if (_rank >= 31 && _rank <= 40) {
            //#31 to #40
            portion = portionRewardPerRank[8];
        } else if (_rank >= 41 && _rank <= 50) {
            //#41 to #50
            portion = portionRewardPerRank[9];
        }
        // return reward to pay, portion shoudn't be greater than 5000=50%
        return (totalRewardPerMatch * portion) * (10**14);
    }
}
