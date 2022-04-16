function findStakedTokenFrom(address _address, uint256 _tokenId)
    private
    view
    returns (uint256 index)
{
    while (stakedTokenIdsForAddress[_address][index] != _tokenId) {
        unchecked {
            ++index;
        }
    }
    require(
        index < stakedTokenIdsForAddress[_address].length,
        "index out of bound"
    );
}

function isStaked(uint256 _tokenId) external view returns (bool) {
    return stakedTokens[_tokenId].staked;
}

function claimAll() external onlyEOA nonReentrant {
    uint256[] memory tokenIds = depositedTokensOf(msg.sender);
    withdraw(tokenIds, false);
}

//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

function exitCurrentMatchWithoutReward() public nonReentrant {
    uint256 matchId = currentMatchForAddress[msg.sender];
    if (matchId != 0) {
        matchs[matchId].players[msg.sender] = Player({
            joined: false,
            claimed: false,
            rank: 0,
            valueClaimed: 0,
            timestamp: block.timestamp,
            tokenId: 0
        });
        currentMatchForAddress[msg.sender] = 0;
    } else {
        revert("Not in match");
    }
}

function getMatch(uint256 _idMatch)
    public
    view
    returns (uint256 timestamp, uint256 maxDuration)
{
    timestamp = matchs[_idMatch].timestamp;
    maxDuration = matchDuration;
}
