// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IBBone is IERC20 {
    function mint(address _account, uint256 _amount) external;
}
