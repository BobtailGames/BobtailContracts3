// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IBBone.sol";
import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailStaking.sol";

import "./libraries/Randomness.sol";

/*
@title NFT Minting 
@author 0xPanda
@notice Pending
*/
contract FlappyAVAX is ERC721, IBobtailNFT, Ownable {
    /*///////////////////////////////////////////////////////////////
                                 CONSTANTS
    //////////////////////////////////////////////////////////////*/
    uint8 public constant MAX_LEVELXP = 100;
    uint256 public constant MAX_SUPPLY = 1008;
    uint256 public constant MAX_MINTSPERTX = 1008;
    uint256 public constant MINT_PRICE_AVAX = 1 ether; // 1 AVAX
    uint256 public constant REVEAL_TIME = 90 seconds;
    uint256 public constant ONE_EXP_PER_TIME = 864 seconds;

    /*///////////////////////////////////////////////////////////////
                                IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    IBBone public immutable bbone;

    constructor(address _bbone) ERC721("FlappyAVAX", "FlappyAVAX") {
        // On launch it's hosted on a own server, after mint and reveal of all supply will be changed to IPFS
        // _setBaseURI("https://bobtail.games/ipfs/game1/");
        bbone = IBBone(_bbone);
    }

    /*///////////////////////////////////////////////////////////////
                        STAKING MANAGER CONFIGURATION
    //////////////////////////////////////////////////////////////*/

    /// @notice How much a match should last
    IBobtailStaking public stakingManager;

    event StakingManagerUpdated(address stakingManager);

    /// @notice Set staking manager
    function setStakingManager(address _stakingManager) external onlyOwner {
        // Update staking manager
        stakingManager = IBobtailStaking(_stakingManager);
        emit StakingManagerUpdated(_stakingManager);
    }

    /*///////////////////////////////////////////////////////////////
                             MINTING LOGIC
    //////////////////////////////////////////////////////////////*/
    uint256 public baseSupply;

    /**
    @notice Mint a NFT token with AVAX.
    */
    function mintWithAvax(address _for, uint256 _quantity) external payable {
        // Don't allow 0 quantity
        require(_quantity != 0, "Invalid quantity");
        // Only allow mint 30 per tx
        require(_quantity <= MAX_MINTSPERTX, "Invalid quantity, max mint p/tx");
        // Only allow mint 30 per tx
        require((baseSupply + _quantity) <= MAX_SUPPLY, "Insufficient supply");
        // Verify the amount of avax sent
        require(
            msg.value == (MINT_PRICE_AVAX * _quantity),
            "Incorrect amount of AVAX sent"
        );

        // Verify the amount of avax sent
        for (uint256 i = 0; i < _quantity; ) {
            // Sum 1 to supply
            baseSupply++;
            // Use baseSupply as token id
            uint256 tokenId = baseSupply;
            // Store Nft default data
            // stored for reveal purposes
            nfts[tokenId] = NftEntity({
                lvl: 1, // default level
                exp: 1, // default exp
                block: block.number, // stored for reveal purposes
                timestampMint: block.timestamp, // stored for reveal purposes
                revealed: 0,
                staked: 0,
                skin: 0,
                face: 0,
                rarity: 0,
                pendingReward: 0
            });
            // mint to address
            _safeMint(_for, tokenId);
            emit NewMint(tokenId, block.timestamp);
            unchecked {
                ++i; // gas optimization
            }
        }
        // Transfer AVAX to bbone contract
        payable(address(bbone)).transfer(msg.value);
        // Call to add AVAX sent and mint the required amount of
        // BBone and add AVAX-BBone in equal parts to liquidity
        bbone.addLiquidity(msg.value, IBBone.LiquidityType.MINTING);
    }

    event TokenRevealed(
        uint256 tokenId,
        uint256 skin,
        uint256 face,
        uint256 rarity
    );

    function doRevealFor(uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (
                block.timestamp > nfts[_tokenIds[i]].timestampMint &&
                (block.timestamp - nfts[_tokenIds[i]].timestampMint) >
                REVEAL_TIME
            ) {
                (uint8 rarity, uint8 skin, uint8 face) = getRevealInfo(
                    _tokenIds[i]
                );
                nftsRevealed[skin][face] = true;
                nfts[_tokenIds[i]].skin = skin;
                nfts[_tokenIds[i]].face = face;
                nfts[_tokenIds[i]].rarity = rarity;
                nfts[_tokenIds[i]].revealed = 1;
                emit TokenRevealed(_tokenIds[i], skin, face, rarity);
            }
        }
    }

    function isRevealed(uint256 _tokenId) external view returns (bool) {
        return nfts[_tokenId].revealed == 1;
    }

    mapping(uint8 => mapping(uint8 => bool)) nftsRevealed;

    function getRevealInfo(uint256 _tokenId)
        private
        view
        returns (
            uint8 rarity,
            uint8 skin,
            uint8 face
        )
    {
        uint256[] memory randomnessExpanded = Randomness.generate(
            nfts[_tokenId].block,
            _tokenId,
            62
        );
        rarity = uint8((randomnessExpanded[0] % 5) + 1);
        for (uint256 i = 0; i < 60; i++) {
            uint8 skinTmp = uint8((randomnessExpanded[1 + i] % 42) + 1);
            for (uint256 o = 0; o < 24; o++) {
                uint8 faceTmp = uint8((randomnessExpanded[2 + o] % 24) + 1);
                if (!nftsRevealed[skinTmp][faceTmp]) {
                    return (rarity, skinTmp, faceTmp);
                } else {
                    skinTmp += 1;
                    if (skinTmp < 43) {
                        if (!nftsRevealed[skinTmp][faceTmp]) {
                            return (rarity, skinTmp, faceTmp);
                        }
                    }
                    faceTmp += 1;
                    if (faceTmp < 25) {
                        if (!nftsRevealed[skinTmp][faceTmp]) {
                            return (rarity, skinTmp, faceTmp);
                        }
                    }
                }
            }
        }
        require(skin != 0 && face != 0, "No random data generated");
    }

    /*///////////////////////////////////////////////////////////////
                             TOKEN DATA 
    //////////////////////////////////////////////////////////////*/
    /// @notice Level, exp, and mint data
    mapping(uint256 => NftEntity) private nfts;

    /// @notice Returns the ids of tokens owned by a address we iterate all existing tokens to
    ///         make this function gas efficient, it's not used in write operations just externally
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (NftEntity memory)
    {
        return nfts[_tokenId];
    }

    /// @notice Returns the info from a token id with extended data
    /// it's not used in write operations to prevent bugs.
    function tokenInfoExtended(uint256 _tokenId)
        public
        view
        returns (NftEntity memory)
    {
        NftEntity memory token = nfts[_tokenId];
        // If token is revealed get reveal info
        if (token.revealed == 1) {
            if (token.staked == 1) {
                // If is staked get pending reward
                token.pendingReward = stakingManager.stakingReward(_tokenId);
            }
        }
        return token;
    }

    /// @notice Returns the ids of tokens owned by a address we iterate all existing tokens to
    ///         make this function gas efficient, it's not used in write operations just externally
    function tokensOf(address _account)
        external
        view
        returns (uint256[] memory tokenIds)
    {
        tokenIds = _findTokensOf(_account);
    }

    /// @notice Returns the ids of tokens owned by a address we iterate all existing tokens to
    ///         make this function gas efficient, it's not used in write operations just externally
    function tokensWithInfoOf(address _account)
        external
        view
        returns (NftEntity[] memory)
    {
        uint256[] memory tokenIds = _findTokensOf(_account);
        return getTokensInfo(tokenIds);
    }

    /// @notice Returns the ids of tokens owned by a address we iterate all existing tokens
    /// it's not used in write operations to prevent bugs.
    function _findTokensOf(address _account)
        private
        view
        returns (uint256[] memory)
    {
        uint256 balance = balanceOf(_account);
        // Token ids to return as result
        uint256[] memory tokenIds = new uint256[](balance);
        if (balance > 0) {
            // Current token id
            uint256 tokenId;
            // Tokens found count
            uint256 found;
            // Run loop from 0 while tokens found count is fewer than balance
            while (found < balance) {
                // If id exist and account is owner
                if (_exists(tokenId) && ownerOf(tokenId) == _account) {
                    // Sum 1 to found count and add tokenId to result
                    tokenIds[found++] = tokenId;
                }
                // Sum 1 to actual token id
                tokenId++;
            }
        }
        return tokenIds;
    }

    /// @notice Gets the current level and experience of a NFT
    function getLevelAndExp(uint256 _tokenId)
        public
        view
        returns (uint8 level, uint8 exp)
    {
        // get stored lvl and exp to sum new values if it's staking
        level = nfts[_tokenId].lvl;
        exp = nfts[_tokenId].exp;

        (bool staked, uint256 stakeTimestamp) = stakingManager.isStaked(
            _tokenId
        );

        // if it's staked calculate current lvl and exp
        if (staked) {
            // 864 seconds = 1 exp | 24 hours(86400 seconds) = 100 exp
            uint256 newExp = ((block.timestamp - stakeTimestamp) /
                ONE_EXP_PER_TIME) + exp;
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

    /// @notice Returns the token info with extended data it's not used in write operations to prevent bugs.
    function getTokensInfo(uint256[] memory _tokenIds)
        public
        view
        returns (NftEntity[] memory)
    {
        NftEntity[] memory tokens = new NftEntity[](_tokenIds.length);
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            // Get extended token data
            tokens[i] = tokenInfoExtended(_tokenIds[i]);
        }
        return tokens;
    }

    /*///////////////////////////////////////////////////////////////
                            LEVEL EXP STORAGE
    //////////////////////////////////////////////////////////////*/

    event LevelAndExpUpdated(uint256 tokenId, uint8 lvl, uint8 exp);

    /// @notice Store level and experience when token is withdraw
    function setLevelAndExp(
        uint256 _tokenId,
        uint8 _lvl,
        uint8 _exp
    ) external {
        // Only allow stakingManager
        require(
            msg.sender == address(stakingManager),
            "Sender should be stakingManager"
        );
        nfts[_tokenId].lvl = _lvl;
        nfts[_tokenId].exp = _exp;
        emit LevelAndExpUpdated(_tokenId, _lvl, _exp);
    }

    /*///////////////////////////////////////////////////////////////
                            LEVEL EXP STORAGE
    //////////////////////////////////////////////////////////////*/

    event NewMint(uint256 mintId, uint256 timestamp);

    /// @notice Only allow transfer of unstaked and revealed tokens
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _tokenId);

        // Only allow unstaked tokens
        require(nfts[_tokenId].staked == 0, "Can't transfer staked token");
        // If isn't minting
        if (_from != address(0)) {
            // Should be revealed
            require(nfts[_tokenId].revealed == 1, "Token should be revealed");
        }
    }
}
