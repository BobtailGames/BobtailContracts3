// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "./libraries/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailStaking.sol";

import "./interfaces/IBBone.sol";

contract Matchs is ReentrancyGuard {
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

    IBBone public immutable bbone;
    uint256 public matchIdCounter;
    uint256 private matchDuration = 10 minutes; // 86400 Seconds = 24 hours

    uint256 public maxPlayersPerMatch = 100;

    uint256 public matchsPerRegionServer = 2;

    uint256 public totalRewardPerMatch = 337;
    address public mainSigner;

    // At the moment we only have one
    address public allowedNftContractAddress;
    IBobtailNFT private allowedNftContract;

    address public allowedStakingManagerAddress;
    IBobtailStaking private allowedStakingManager;

    mapping(string => bool) public serverRegions;

    mapping(string => mapping(uint256 => uint256)) public matchSlots; // Region->SlotId->MatchId
    mapping(uint256 => Match) public matchs;
    mapping(address => uint256) public currentMatchForAddress;
    mapping(uint256 => uint256) public currentMatchForToken;
    mapping(address => uint256) public lastMatchIdClaimedForAccount;
    mapping(uint256 => uint256) private portionRewardPerRank;

    modifier onlyEOA() {
        require(msg.sender.code.length == 0, "Only EOA");
        _;
    }

    event NewMatch(
        uint256 matchId,
        uint256 slot,
        uint256 timestamp,
        uint256 duration,
        uint256 maxPlayers
    );

    event NewAddressInMatch(address player, uint256 matchId, uint256 tokenId);
    event RewardClaimed(address player, uint256[] matchIds, uint256 reward);

    constructor(address _mainSigner, address _bbone) {
        mainSigner = _mainSigner;
        //Default regions
        serverRegions["NA"] = true;
        bbone = IBBone(_bbone);

        //Default rewards
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

    function initializeContract(
        address _contractAddress,
        address _stakingManager
    ) public {
        allowedStakingManagerAddress = _stakingManager;
        allowedStakingManager = IBobtailStaking(_stakingManager);
        allowedNftContractAddress = _contractAddress;
        allowedNftContract = IBobtailNFT(_contractAddress);
    }

    //**************************************************
    //***************EXTERNAL WRITE*********************
    //**************************************************

    //********************ADMIN**************************

    function setMatchDuration(uint256 _matchDuration) external {
        require(
            _matchDuration > 10 seconds && _matchDuration < 2 days,
            "Invalid duration"
        );
        matchDuration = _matchDuration;
    }

    function setMaxPlayersPerMatch(uint256 _maxPlayersPerMatch) external {
        require(
            _maxPlayersPerMatch > 0 && _maxPlayersPerMatch < 1500,
            "Invalid quantity"
        );
        maxPlayersPerMatch = _maxPlayersPerMatch;
    }

    function setMatchsPerRegion(uint256 _matchsPerRegionServer) external {
        require(
            _matchsPerRegionServer > 0 && _matchsPerRegionServer < 1000,
            "Invalid quantity"
        );
        matchsPerRegionServer = _matchsPerRegionServer;
    }

    function setServerRegion(string calldata _name, bool status) external {
        serverRegions[_name] = status;
    }

    function joinMatch(uint256 _tokenId, string calldata region)
        external
        onlyEOA
        nonReentrant
    {
        require(serverRegions[region], "Invalid region");

        // Invalid region TODO Test
        require(_tokenId != 0, "Invalid token id");
        // Only valid Id's
        require(_tokenId != 0, "Invalid token id");

        // _tokenId should be owned by sender
        require(
            allowedNftContract.ownerOf(_tokenId) == msg.sender,
            "Token not owned from sender"
        );

        // _tokenId should be staked
        (bool staked, ) = allowedStakingManager.isStaked(_tokenId);

        require(staked, "Token should be staked");

        uint256 matchIdToken = currentMatchForToken[_tokenId];
        if (matchIdToken != 0) {
            require(!isMatchActive(matchIdToken), "Currently in a match");
        }
        // require(!stakedTokens[_tokenId].inGame, "Token in game, can't join");
        uint256 matchId = currentMatchForAddress[msg.sender];
        if (matchId != 0) {
            require(!isMatchActive(matchId), "Currently in a match");
            matchId = 0;
        }
        matchId = getMatchSlot(region);
        require(matchId != 0, "No match available");
        currentMatchForToken[_tokenId] = matchId;
        matchs[matchId].playersAddress.push(msg.sender);
        matchs[matchId].players[msg.sender] = Player({
            joined: true,
            claimed: false,
            rank: 0,
            valueClaimed: 0,
            timestamp: block.timestamp,
            tokenId: _tokenId
        });
        currentMatchForAddress[msg.sender] = matchId;
        emit NewAddressInMatch(msg.sender, matchId, _tokenId);
    }

    function claimReward(
        uint256[] calldata _matchIds,
        uint256[] calldata _ranks,
        bytes32 r,
        bytes32 s,
        uint8 v
    ) external onlyEOA nonReentrant {
        //TODO time signature
        require(_matchIds.length > 0 && _ranks.length > 0, "Invalid request");
        require(_matchIds.length == _ranks.length, "Invalid request");
        bytes32 messageHash = keccak256(
            abi.encode(_matchIds, _ranks, msg.sender, address(this))
        ); // Get the message hash
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash) // Get the signer message hash
        );
        require(
            ecrecover(ethSignedMessageHash, v, r, s) == mainSigner,
            "Wrong signature"
        );
        uint256 totalReward;
        for (uint256 i = 0; i < _matchIds.length; ) {
            uint256 rank = _ranks[i];
            uint256 matchId = _matchIds[i];
            require(matchId > 0, "Match id invalid");
            require(rank > 0 && rank < 101, "Rank invalid");
            require(matchs[matchId].timestamp != 0, "Match isn't started");
            require(!isMatchActive(matchId), "Match is not finished");
            require(
                matchs[matchId].players[msg.sender].joined,
                "Address not in match"
            );
            //TODO test claim two times
            require(
                matchs[matchId].players[msg.sender].claimed == false,
                "Account and match reward claimed"
            );
            require(
                matchs[matchId].claimedRanks[rank] == 0,
                "Rank reward has been claimed"
            );
            uint256 reward = calculateReward(rank);
            matchs[matchId].claimedRanks[rank] = 1;
            totalReward += reward;
            matchs[matchId].players[msg.sender].claimed = true;
            matchs[matchId].players[msg.sender].valueClaimed = reward;
            matchs[matchId].players[msg.sender].rank = rank;
            unchecked {
                ++i;
            }
        }

        bbone.payMatchReward(msg.sender, totalReward);
        emit RewardClaimed(msg.sender, _matchIds, totalReward);
    }

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
        matchId = currentMatchForAddress[_address];
        if (matchId != 0) {
            inMatch = true;
            // matchInfo = matchs[matchId];
            finished = !isMatchActive(matchId);
            timestamp = matchs[matchId].timestamp;
            duration = matchs[matchId].duration;
        }
    }

    function activeMatchsCount(string calldata _region)
        external
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < matchsPerRegionServer; ) {
            uint256 matchIdTmp = matchSlots[_region][i];
            if (matchIdTmp != 0 && isMatchActive(matchIdTmp)) {
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        }
    }

    function activeMatchs(address _contractAddress, address _account)
        private
        view
        returns (uint256[] memory)
    {
        require(
            allowedNftContractAddress == _contractAddress,
            "Invalid contract"
        );

        uint256 balance = allowedNftContract.balanceOf(_account);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenId;
        uint256 found;
        while (found < balance) {
            if (allowedNftContract.ownerOf(tokenId) == _account) {
                tokenIds[found++] = tokenId;
            }
            tokenId++;
        }
        return tokenIds;
    }

    function getMatchSlot(string calldata region)
        private
        returns (uint256 matchId)
    {
        uint256 currentActiveMatchs;
        uint256 slot;
        bool slotAssigned = false;
        for (uint256 i = 0; i < matchsPerRegionServer; ) {
            uint256 matchIdTmp = matchSlots[region][i];
            if (matchIdTmp != 0 && isMatchActive(matchIdTmp)) {
                if (
                    matchs[matchIdTmp].playersAddress.length <
                    matchs[matchIdTmp].maxPlayers
                ) {
                    matchId = matchIdTmp;
                    break;
                }
                unchecked {
                    ++currentActiveMatchs;
                }
            } else {
                if (!slotAssigned) {
                    slot = i;
                    slotAssigned = true;
                }
            }
            unchecked {
                ++i;
            }
        }
        if (
            slotAssigned &&
            matchId == 0 &&
            currentActiveMatchs < matchsPerRegionServer
        ) {
            unchecked {
                ++matchIdCounter;
            }
            matchId = matchIdCounter;
            matchSlots[region][slot] = matchId;
            Match storage m = matchs[matchId];
            m.started = true;
            m.finished = false;
            m.timestamp = block.timestamp;
            m.duration = matchDuration;
            m.maxPlayers = maxPlayersPerMatch;
            m.slot = slot;
            emit NewMatch(
                matchId,
                slot,
                block.timestamp,
                matchDuration,
                maxPlayersPerMatch
            );
        }
    }

    function tokenInMatch(uint256 _tokenId) external view returns (bool) {
        uint256 matchIdToken = currentMatchForToken[_tokenId];
        if (matchIdToken != 0) {
            return isMatchActive(matchIdToken);
        }
        return false;
    }

    function isMatchActive(uint256 _matchId) private view returns (bool) {
        return
            (block.timestamp - matchs[_matchId].timestamp) <
            matchs[_matchId].duration;
    }

    function updateRewards(uint256[] calldata _portionRewardPerRank) public {
        require(
            _portionRewardPerRank.length == 10,
            "Length of array should be 10"
        );
        uint256 total = _portionRewardPerRank[0] +
            _portionRewardPerRank[1] +
            _portionRewardPerRank[2] +
            _portionRewardPerRank[3] +
            _portionRewardPerRank[4] +
            (_portionRewardPerRank[5] * 5) +
            (_portionRewardPerRank[6] * 10) +
            (_portionRewardPerRank[7] * 10) +
            (_portionRewardPerRank[8] * 10) +
            (_portionRewardPerRank[9] * 10);
        require(total == 10000, "Sum of rewards should be 10000");
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
    }

    /// @notice Calculate te reward of the match
    /// @dev Of all the totalRewardPerMatch a portion is distributed to the leaderboard based on the
    ///      rank in the matchId
    function calculateReward(uint256 _rank) private view returns (uint256) {
        uint256 portion;
        if (_rank >= 1 && _rank <= 5) {
            portion = portionRewardPerRank[_rank - 1]; //#1 to #5
        } else if (_rank >= 6 && _rank <= 10) {
            portion = portionRewardPerRank[5]; //#6 to #10
        } else if (_rank >= 11 && _rank <= 20) {
            portion = portionRewardPerRank[6]; //#11 to #20
        } else if (_rank >= 21 && _rank <= 30) {
            portion = portionRewardPerRank[7]; //#21 to #30
        } else if (_rank >= 31 && _rank <= 40) {
            portion = portionRewardPerRank[8]; //#31 to #40
        } else if (_rank >= 41 && _rank <= 50) {
            portion = portionRewardPerRank[9]; //#41 to #50
        }
        return (totalRewardPerMatch * portion) * (10**14);
    }
}
