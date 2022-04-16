// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";

contract BBone is ERC20, Ownable, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IJoeRouter02 public immutable joeRouter;
    address public immutable joePair;

    mapping(address => bool) private allowedMinters;

    modifier onlyAllowedMinter() {
        require(hasRole(MINTER_ROLE, _msgSender()), "Caller is not a minter");
        _;
    }

    constructor(address _router) public ERC20("Bobtail Bone", "BBone") {
        IJoeRouter02 _joeRouter = IJoeRouter02(_router);
        // Create a uniswap pair for this new token
        joePair = IJoeFactory(_joeRouter.factory()).createPair(
            address(this),
            _joeRouter.WAVAX()
        );
        // set the rest of the contract variables
        joeRouter = _joeRouter;
    }

    function allowMinter(address _address) public {
        _setupRole(MINTER_ROLE, _address);
    }

    //to recieve ETH from swapRouter when swaping
    receive() external payable {}

    function mint(address _account, uint256 _amount)
        external
        onlyAllowedMinter
    {
        _mint(_account, _amount);
    }
}
