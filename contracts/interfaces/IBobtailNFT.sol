import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IBobtailNFT is IERC721 {
    struct NftEntity {
        uint8 lvl;
        uint8 exp;
        // bool staked;
        // uint256 id;
        // uint256 matchId;
        uint256 timestampMint;
        // uint256 timestampStake;
        uint256 block;
    }

    struct NftEntityExtended {
        uint8 lvl;
        uint8 exp;
        uint8 revealed;
        uint256 skin;
        uint256 face;
        uint256 rarity;
        // uint256 id;
        uint256 timestampMint;
        // uint256 timestampStake;
        uint256 pendingReward;
    }

    function tokenInfo(uint256 _tokenId)
        external
        view
        returns (NftEntity memory);

    function isRevealed(uint256 _tokenId) external view returns (bool);

    function getLevelAndExp(uint256 _tokenId)
        external
        view
        returns (uint8 level, uint8 exp);

    function setLevelAndExp(
        uint256 _tokenId,
        uint8 _lvl,
        uint8 _exp
    ) external returns (bool);
}
