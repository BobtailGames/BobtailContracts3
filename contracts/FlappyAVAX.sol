// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./interfaces/IBBone.sol";
import "./interfaces/IBobtailNFT.sol";
import "./interfaces/IBobtailStaking.sol";
import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoePair.sol";

import "./libraries/Randomness.sol";
import "./libraries/ReentrancyGuard.sol";

// solhint-disable not-rely-on-time, statement-indent, indent,mark-callable-contracts, separate-by-one-line-in-contract

/*
@title NFT Minting 
@author 0xPanda
@notice Pending
*/
contract FlappyAVAX is ERC721, ReentrancyGuard, IBobtailNFT {
    address public allowedStakerAddress;

    IBobtailStaking private allowedStaker;
    address public allowedGameChefAddress;

    uint8 private constant MAX_LEVELXP = 100;
    uint256 private constant MAX_SUPPLY = 10000;
    uint256 private constant MAX_MINTSPERTX = 50;
    uint256 private constant MINT_PRICE_AVAX = 1 ether; // 1 AVAX

    uint256 private constant REVEAL_TIME = 90 seconds;
    uint256 private constant ONE_EXP_PER_TIME = 864 seconds;

    uint256 public baseSupply;
    mapping(uint256 => NftEntity) private nfts;

    IJoeRouter02 public immutable joeRouter;
    IJoePair public immutable pairBboneAvax;
    IBBone public immutable bbone;

    event NewMint(uint256 mintId, uint256 timestamp);

    modifier onlyEOA() {
        require(msg.sender.code.length == 0, "Only EOA");
        _;
    }

    constructor(
        address _router,
        address _bbone,
        address _pairBboneAvax,
        address _allowedStakerAddress
    ) ERC721("FlappyAVAX", "FlappyAVAX") {
        // On launch it's hosted on a own server, after mint and reveal of all supply will be changed to IPFS
        // _setBaseURI("https://bobtail.games/ipfs/game1/");
        joeRouter = IJoeRouter02(_router);
        bbone = IBBone(_bbone);
        //Approve transfer of BBone from this contract to TraderJoe Router
        //to add liquidity
        bbone.approve(_router, type(uint256).max);
        pairBboneAvax = IJoePair(_pairBboneAvax);
        allowedStakerAddress = _allowedStakerAddress;
        allowedStaker = IBobtailStaking(_allowedStakerAddress);
    }

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
                timestampMint: block.timestamp,
                lvl: 1,
                exp: 1,
                block: block.number
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
        // add to liquidity BBone minted and avax sent
        joeRouter.addLiquidityAVAX{value: msg.value}(
            tokenB,
            amountB,
            0,
            0,
            address(this),
            block.timestamp
        );
    }

    //**************************************************
    //****************EXTERNAL READ*********************
    //**************************************************
    //********************NFTS**************************
    /// @notice Returns the ids of tokens owned by a address we iterate all existing tokens to
    ///         make this function gas efficient, it's not used in write operations just externally
    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (NftEntity memory)
    {
        return nfts[_tokenId];
    }

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

    function setLevelAndExp(
        uint256 _tokenId,
        uint8 _lvl,
        uint8 _exp
    ) external returns (bool) {
        nfts[_tokenId].lvl = _lvl;
        nfts[_tokenId].exp = _exp;
        return true;
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
            timestampMint: nfts[_tokenId].timestampMint,
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
            (bool staked, ) = allowedStaker.isStaked(_tokenId);
            if (staked) {
                token.pendingReward = allowedStaker.stakingReward(
                    address(this),
                    _tokenId
                );
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
        (bool staked, ) = allowedStaker.isStaked(_tokenId);
        require(!staked, "Can't transfer staked token");
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
            if (ownerOf(tokenId) == _account) {
                tokenIds[found++] = tokenId;
            }
            tokenId++;
        }
        return tokenIds;
    }

    /// @notice The tokens are revealed after 90 seconds of minting to make it hard
    ///         and expensive trying to trick the pseudo random number to get a better NFT
    function isRevealed(uint256 _tokenId) public view returns (bool) {
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
        public
        view
        returns (uint8 level, uint8 exp)
    {
        // get stored lvl and exp to sum new values if it's staking
        level = nfts[_tokenId].lvl;
        exp = nfts[_tokenId].exp;

        (bool staked, uint256 stakeTimestamp) = allowedStaker.isStaked(
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

    function _stakedTokensOf(address _account)
        private
        view
        returns (uint256[] memory)
    {
        uint256[] memory tokenIdsOwned = _tokensOf(_account);

        uint256 stakedCount;
        for (uint256 i = 0; i < tokenIdsOwned.length; ) {
            (bool staked, ) = allowedStaker.isStaked(tokenIdsOwned[i]);
            if (staked) {
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
            (bool staked, ) = allowedStaker.isStaked(tokenIdsOwned[i]);
            if (staked) {
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
}
