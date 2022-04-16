// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IBBone.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoePair.sol";

import "./libraries/Randomness.sol";
import "./libraries/ReentrancyGuard.sol";

/*
@title NFT Minting
@author 0xPanda
@notice Pending
*/
contract FlappyAVAX is ERC721, ReentrancyGuard {
    struct NftEntity {
        uint8 lvl;
        uint8 exp;
        bool staked;
        uint256 id;
        uint256 matchId;
        uint256 timestampMint;
        uint256 timestampStake;
        uint256 block;
    }

    struct NftEntityExtended {
        uint8 lvl;
        uint8 exp;
        uint8 revealed;
        uint256 skin;
        uint256 face;
        uint256 rarity;
        uint256 id;
        uint256 timestampMint;
        uint256 timestampStake;
        uint256 pendingReward;
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
    struct Player {
        bool joined;
        bool claimed;
        uint256 rank;
        uint256 valueClaimed;
        uint256 timestamp;
        uint256 tokenId;
    }

    uint8 private constant MAX_LEVELXP = 100;
    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_MINTSPERTX = 50;
    uint256 private constant MINT_PRICE_AVAX = 1 ether; // 1 AVAX

    uint256 private constant REVEAL_TIME = 90 seconds;
    uint256 private constant ONE_EXP_PER_TIME = 864 seconds;

    uint256 public baseSupply;
    uint256 public rewardPerMinute = 1 ether; // Default 1 BBone
    uint256 public maxStakingTokensPerAccount = 10;

    uint256 public matchIdCounter;
    uint256 private matchDuration = 10 minutes; // 86400 Seconds = 24 hours

    uint256 public maxPlayersPerMatch = 100;

    uint256 public matchsPerRegionServer = 2;

    mapping(string => bool) public serverRegions;

    uint256 public totalRewardPerMatch = 337;
    address public mainSigner;

    mapping(uint256 => NftEntity) private nfts;
    mapping(address => uint256) public stakingCountForAddress;

    mapping(uint256 => uint256) private portionRewardPerRank;

    mapping(string => mapping(uint256 => uint256)) public matchSlots; // Region->SlotId->MatchId
    mapping(uint256 => Match) public matchs;
    mapping(address => uint256) public currentMatchForAddress;
    mapping(address => uint256) public lastMatchIdClaimedForAccount;

    IJoeRouter02 public immutable joeRouter;
    IJoePair public immutable pairBboneAvax;
    IBBone public immutable bbone;

    event NewMatch(
        uint256 matchId,
        uint256 slot,
        uint256 timestamp,
        uint256 duration,
        uint256 maxPlayers
    );
    event NewMint(uint256 mintId, uint256 timestamp);
    event NewAddressInMatch(address player, uint256 matchId, uint256 tokenId);
    event RewardClaimed(address player, uint256[] matchIds, uint256 reward);

    modifier onlyEOA() {
        require(msg.sender.code.length == 0, "Only EOA");
        _;
    }

    constructor(
        address _router,
        address _bbone,
        address _mainSigner,
        address _pairBboneAvax
    ) ERC721("FlappyAVAX", "FlappyAVAX") {
        // On launch it's hosted on a own server, after mint and reveal of all supply will be changed to IPFS
        // _setBaseURI("https://bobtail.games/ipfs/game1/");
        joeRouter = IJoeRouter02(_router);

        bbone = IBBone(_bbone);
        //Approve tranfer of BBone from this contract to TraderJoe Router
        //to add liquidity
        bbone.approve(_router, type(uint256).max);
        mainSigner = _mainSigner;
        pairBboneAvax = IJoePair(_pairBboneAvax);

        //Default regions
        serverRegions["NA"] = true;
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

    //********************NFTS**************************
    /**
    @notice Mint a NFT token with AVAX.
    @dev It needs to receive the amount of 1 avax(MINT_PRICE_AVAX)
    */
    function mintWithAvax(address _for, uint256 _quantity)
        external
        payable
        nonReentrant
        onlyEOA
    {
        // solhint-disable not-rely-on-time, statement-indent, indent,mark-callable-contracts, separate-by-one-line-in-contract

        require(_quantity != 0, "Invalid quantity");
        require(_quantity <= MAX_MINTSPERTX, "Invalid quantity, max mint p/tx");
        require((baseSupply + _quantity) <= MAX_SUPPLY, "Insufficient supply");
        require(
            msg.value == (MINT_PRICE_AVAX * _quantity),
            "Incorrect amount of AVAX sent"
        );
        for (uint256 i = 0; i < _quantity; ) {
            baseSupply++;
            uint256 tokenId = baseSupply;
            nfts[tokenId] = NftEntity({
                id: tokenId,
                timestampMint: block.timestamp,
                lvl: 1,
                exp: 1,
                staked: false,
                timestampStake: 0, //TODO
                block: block.number,
                matchId: 0
            });
            _safeMint(_for, tokenId);
            emit NewMint(tokenId, block.timestamp);
            unchecked {
                ++i; /// gas optimization
            }
        }
        address tokenA = joeRouter.WAVAX();
        address tokenB = address(bbone);

        (uint256 reserve0, uint256 reserve1, ) = pairBboneAvax.getReserves();
        address token0 = tokenA < tokenB ? tokenA : tokenB;
        (uint256 reserveA, uint256 reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
        uint256 amountB;
        if (reserveA == 0 && reserveB == 0) {
            amountB = 100 * msg.value;
        } else {
            amountB = (msg.value * reserveB) / reserveA;
        }
        bbone.mint(address(this), amountB);

        // swap half for BBone
        //uint256[] memory bboneSwapped = joeRouter.swapExactAVAXForTokens{
        //  value: sellAmount
        //}(0, path, address(this), block.timestamp);
        // add BBone swapped and avax to liquidity
        joeRouter.addLiquidityAVAX{value: msg.value}(
            tokenB,
            amountB, //bboneSwapped[1],
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    //********************STAKING**************************
    function stake(uint256[] calldata _tokenIds) external onlyEOA nonReentrant {
        // Tokens to stake should be greater or equal to balance
        require(
            balanceOf(msg.sender) >= _tokenIds.length,
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
                msg.sender == ownerOf(_tokenIds[i]),
                "Sender must be owner"
            );
            // Only allow unstaked tokens
            require(!nfts[_tokenIds[i]].staked, "Token currently staked");
            // Only allow if the tokens has been revealed(90 seconds after mint)
            require(isRevealed(_tokenIds[i]), "Token should be revealed");

            // Create checkpoint to calculate the rewards
            nfts[_tokenIds[i]].matchId = 0;
            nfts[_tokenIds[i]].timestampStake = block.timestamp;
            nfts[_tokenIds[i]].staked = true;

            // Store token id to staked ids for address
            // stakedTokenIdsForAddress[msg.sender].push(_nftTokenIds[i]);
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
            NftEntity memory stakedToken = nfts[_tokenIds[i]];
            require(stakedToken.staked, "Token not staked");
            // The token should be staked for at least 63 seconds to prevent exploits
            require(
                (block.timestamp - stakedToken.timestampStake) >= 63,
                "Need 63 sec staked claim/unstake"
            );
            // Calculate the reward for this token
            totalReward += stakingReward(_tokenIds[i]);
            // Get current level and experence of the token
            (uint8 level, uint8 exp) = getLevelAndExp(_tokenIds[i]);
            if (_unstake) {
                if (stakedToken.matchId != 0) {
                    require(
                        !isMatchActive(
                            matchs[stakedToken.matchId].timestamp,
                            matchs[stakedToken.matchId].duration
                        ),
                        "Token in match can't unstake"
                    );
                }
                // Update staking status
                nfts[_tokenIds[i]].staked = false;
                nfts[_tokenIds[i]].matchId = 0;
                nfts[_tokenIds[i]].timestampStake = block.timestamp + 9000 days;
                unchecked {
                    --stakingCountForAddress[msg.sender];
                }
            } else {
                // Update staking timestamp
                nfts[_tokenIds[i]].timestampStake = block.timestamp;
            }

            nfts[_tokenIds[i]].lvl = level;
            nfts[_tokenIds[i]].exp = exp;
            unchecked {
                ++i;
            }
        }
        bbone.mint(msg.sender, totalReward);
    }

    //********************MATCH**************************
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
        require(ownerOf(_tokenId) == msg.sender, "Token not owned from sender");
        // _tokenId should be staked
        NftEntity memory token = nfts[_tokenId];
        require(token.staked, "Token should be staked");
        if (token.matchId != 0) {
            require(
                !isMatchActive(
                    matchs[token.matchId].timestamp,
                    matchs[token.matchId].duration
                ),
                "Currently in a match"
            );
        }
        // require(!stakedTokens[_tokenId].inGame, "Token in game, can't join");
        uint256 matchId = currentMatchForAddress[msg.sender];
        if (matchId != 0) {
            require(
                !isMatchActive(
                    matchs[matchId].timestamp,
                    matchs[matchId].duration
                ),
                "Currently in a match"
            );
            matchId = 0;
        }
        matchId = getMatchSlot(region);
        require(matchId != 0, "No match available");
        nfts[_tokenId].matchId = matchId;
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
            require(
                !isMatchActive(
                    matchs[matchId].timestamp,
                    matchs[matchId].duration
                ),
                "Match is not finished"
            );
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

        bbone.mint(msg.sender, totalReward);
        emit RewardClaimed(msg.sender, _matchIds, totalReward);
    }

    //**************************************************
    //****************EXTERNAL READ*********************
    //**************************************************
    //********************NFTS**************************
    /// @notice Returns the ids of tokens owned by a address we iterate all existing tokens to
    ///         make this function gas efficient, it's not used in write operations just externally
    function tokensOf(address _account)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _tokensOf(_account);
    }

    function tokensWithInfoOf(address _account)
        external
        view
        returns (NftEntityExtended[] memory)
    {
        uint256[] memory tokenIds = _tokensOf(_account);
        return getTokensInfo(tokenIds);
    }

    //********************STAKING**************************
    function stakedTokensOf(address _account)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _stakedTokensOf(_account);
    }

    function stakedTokensWithInfoOf(address _account)
        external
        view
        returns (NftEntityExtended[] memory)
    {
        uint256[] memory tokenIds = _stakedTokensOf(_account);
        return getTokensInfo(tokenIds);
    }

    //********************MATCH**************************
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
            finished = !isMatchActive(
                matchs[matchId].timestamp,
                matchs[matchId].duration
            );
            timestamp = matchs[matchId].timestamp;
            duration = matchs[matchId].duration;
        }
    }

    //**************************************************
    //****************PUBLIC READ***********************
    //**************************************************
    //********************NFTS**************************
    function getTokenInfo(uint256 _tokenId)
        public
        view
        returns (NftEntityExtended memory)
    {
        (uint8 level, uint8 experience) = getLevelAndExp(_tokenId);
        NftEntityExtended memory token = NftEntityExtended({
            lvl: level,
            exp: experience,
            skin: 0,
            face: 0,
            rarity: 0,
            id: _tokenId,
            timestampMint: nfts[_tokenId].timestampMint,
            timestampStake: nfts[_tokenId].timestampStake,
            revealed: 0,
            pendingReward: 0
        });
        if (isRevealed(_tokenId)) {
            (uint256 rarity, uint256 skin, uint256 face) = getRevealInfo(
                _tokenId
            );
            token.revealed = 1;
            token.skin = skin;
            token.face = face;
            token.rarity = rarity;
            if (nfts[_tokenId].staked) {
                token.pendingReward = stakingReward(_tokenId);
            }
        }
        return token;
    }

    //**************************************************
    //******************INTERNAL************************
    //**************************************************
    //********************NFTS**************************
    /// @notice Only allow transfer of unstaked tokens
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _tokenId);
        require(!nfts[_tokenId].staked, "Can't transfer staked token");
        if (_from != address(0)) {
            require(isRevealed(_tokenId), "Token should be revealed");
        }
    }

    //**************************************************
    //***************PRIVATE READ***********************
    //**************************************************

    //********************NFTS**************************

    function _tokensOf(address _account)
        private
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_account);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenId;
        uint256 found;
        while (found < balance) {
            if (_exists(tokenId) && ownerOf(tokenId) == _account) {
                tokenIds[found++] = tokenId;
            }
            tokenId++;
        }
        return tokenIds;
    }

    /// @notice The tokens are revealed after 90 seconds of minting to make it hard
    ///         and expensive trying to trick the pseudo random number to get a better NFT
    function isRevealed(uint256 _tokenId) private view returns (bool) {
        return (block.timestamp - nfts[_tokenId].timestampMint) >= REVEAL_TIME;
    }

    function getRevealInfo(uint256 _tokenId)
        private
        view
        returns (
            uint256 rarity,
            uint256 skin,
            uint256 face
        )
    {
        //TODO Test randomness
        uint256[] memory randomnessExpanded = Randomness.generate(
            nfts[_tokenId].block + 2,
            3
        );
        return (
            (randomnessExpanded[2] % 5) + 1,
            (randomnessExpanded[0] % 42) + 1,
            (randomnessExpanded[1] % 24) + 1
        );
    }

    /// @notice Gets the current level and experience of a NFT
    function getLevelAndExp(uint256 _tokenId)
        private
        view
        returns (uint8 level, uint8 exp)
    {
        // get stored lvl and exp to sum new values if it's staking
        level = nfts[_tokenId].lvl;
        exp = nfts[_tokenId].exp;

        // if it's staked calculate lvl and exp
        if (nfts[_tokenId].staked) {
            // 864 seconds = 1 exp | 24 hours(86400 seconds) = 100 exp
            uint256 newExp = ((block.timestamp -
                nfts[_tokenId].timestampStake) / ONE_EXP_PER_TIME) + exp;
            // get the remainder of MAX_LEVELXP
            uint256 expSubtotal = (newExp % MAX_LEVELXP);
            // Convert total experience to level
            uint256 tempLevel = (newExp / uint256(MAX_LEVELXP)) + level;
            // if tempLevel is greather than MAX_LEVEL use MAX_LEVEL and MAX_LEVELXP to prevent any exploit
            if (tempLevel >= MAX_LEVELXP) {
                level = MAX_LEVELXP;
                exp = MAX_LEVELXP;
            } else {
                level = uint8(tempLevel);
                exp = uint8(expSubtotal);
            }
        }
        return (level, exp);
    }

    function getTokensInfo(uint256[] memory _tokenIds)
        private
        view
        returns (NftEntityExtended[] memory)
    {
        NftEntityExtended[] memory tokens = new NftEntityExtended[](
            _tokenIds.length
        );
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            tokens[i] = getTokenInfo(_tokenIds[i]);
        }
        return tokens;
    }

    function activeMatchs(address _account)
        private
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_account);
        uint256[] memory tokenIds = new uint256[](balance);
        uint256 tokenId;
        uint256 found;
        while (found < balance) {
            if (_exists(tokenId) && ownerOf(tokenId) == _account) {
                tokenIds[found++] = tokenId;
            }
            tokenId++;
        }
        return tokenIds;
    }

    //********************MATCH**************************

    function activeMatchsCount(string calldata _region)
        external
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < matchsPerRegionServer; ) {
            uint256 matchIdTmp = matchSlots[_region][i];
            if (
                matchIdTmp != 0 &&
                isMatchActive(
                    matchs[matchIdTmp].timestamp,
                    matchs[matchIdTmp].duration
                )
            ) {
                unchecked {
                    ++count;
                }
            }
            unchecked {
                ++i;
            }
        }
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
            if (
                matchIdTmp != 0 &&
                isMatchActive(
                    matchs[matchIdTmp].timestamp,
                    matchs[matchIdTmp].duration
                )
            ) {
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

    // TODO Unsafe
    function isMatchActive(uint256 _timestamp, uint256 _matchDuration)
        private
        view
        returns (bool)
    {
        return (block.timestamp - _timestamp) < _matchDuration;
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

    function _stakedTokensOf(address _account)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIdsOwned = _tokensOf(_account);

        uint256 stakedCount;
        for (uint256 i = 0; i < tokenIdsOwned.length; ) {
            if (nfts[tokenIdsOwned[i]].staked) {
                unchecked {
                    ++stakedCount;
                }
            }
            unchecked {
                ++i;
            }
        }
        uint256[] memory tokenIds = new uint256[](stakedCount);
        uint256 tempIndex;
        for (uint256 i = 0; i < tokenIdsOwned.length; ) {
            if (nfts[tokenIdsOwned[i]].staked) {
                tokenIds[tempIndex] = tokenIdsOwned[i];
                unchecked {
                    ++tempIndex;
                }
            }
            unchecked {
                ++i;
            }
        }
        return tokenIds;
    }

    /// @notice Calculate the reward of BBone for a staked NFT
    function stakingReward(uint256 _tokenId) private view returns (uint256) {
        require(_tokenId != 0, "Invalid token id");
        require(isRevealed(_tokenId), "Token unrevealed");
        require(nfts[_tokenId].staked, "Token not staked");
        // Get elapsed time since staking checkpoint
        uint256 elapsed = block.timestamp - nfts[_tokenId].timestampStake;
        // Get level
        (uint8 level, ) = getLevelAndExp(_tokenId);
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
}
