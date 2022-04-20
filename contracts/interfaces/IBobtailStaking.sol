interface IBobtailStaking {
    function stakingReward(uint256 _tokenId) external view returns (uint256);

    function isStaked(uint256 _tokenId)
        external
        view
        returns (bool staked, uint256 timestampStake);
}
