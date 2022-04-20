// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBBone is IERC20 {
    function payStakingReward(address _to, uint256 _amount) external;

    function payMatchReward(address _to, uint256 _amount) external;

    function addLiquidity(uint256 balanceAvax) external;
}
