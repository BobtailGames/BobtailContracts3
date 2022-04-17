interface IBobtailStaking {
    function stakingReward(address _nftContract, uint256 _tokenId)
        external
        view
        returns (uint256);

    function isStaked(uint256 _tokenId)
        external
        view
        returns (bool staked, uint256 timestampStake);
}
