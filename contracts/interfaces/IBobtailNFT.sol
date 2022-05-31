// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity =0.8.12;
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
        uint8 revealed;
        uint8 staked;
        uint8 skin;
        uint8 face;
        uint8 rarity;
        uint256 pendingReward;
    }

    function isRevealed(uint256 _tokenId) external view returns (bool);

    function getLevelAndExp(uint256 _tokenId)
        external
        view
        returns (uint8 level, uint8 exp);

    function setLevelAndExp(
        uint256 _tokenId,
        uint8 _lvl,
        uint8 _exp
    ) external;

    function tokensOf(address _account)
        external
        view
        returns (uint256[] memory tokenIds);

    function getTokensInfo(uint256[] memory _tokenIds)
        external
        view
        returns (NftEntity[] memory);
}
