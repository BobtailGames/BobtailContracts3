// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./interfaces/IJoeRouter02.sol";
import "./interfaces/IJoeFactory.sol";

contract Bobtail is Context, IERC20, Ownable, AccessControl {
    using SafeMath for uint256;

    mapping(address => uint256) private balances;

    mapping(address => mapping(address => uint256)) private allowances;

    IJoeRouter02 public immutable joeRouter;

    address public immutable joePair;

    IERC20 public immutable bboneToken;
    IERC20 public immutable wavax;

    // exlcude from fees and max transaction amount
    mapping(address => bool) private isExcludedFromFees;

    bool public swapAndLiquifyEnabled;
    uint256 private supply = 36_000_000 ether;

    event SwapAndLiquifyEnabledUpdated(bool enabled);

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    constructor(
        address _router,
        address _bbone
    ) public {
        bboneToken = IERC20(_bbone);

        balances[_msgSender()] = supply;
        emit Transfer(address(0), _msgSender(), supply);

        IJoeRouter02 _joeRouter = IJoeRouter02(_router);

        // Create a uniswap pair for this new token
        joePair = IJoeFactory(_joeRouter.factory()).createPair(
            address(this),
            _joeRouter.WAVAX()
        );
        wavax = IERC20(_joeRouter.WAVAX());

        // set the rest of the contract variables
        joeRouter = _joeRouter;
    }

    //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function name() public pure virtual returns (string memory) {
        return "Bobtail";
    }

    function symbol() public pure virtual returns (string memory) {
        return "BOBT";
    }

    function decimals() public pure virtual returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return supply;
    }

    function balanceOf(address _account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return balances[_account];
    }

    function transfer(address _recipient, uint256 _amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), _recipient, _amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    uint256 liquidityTx = 0;
    uint256 public previousBuyBackTime = block.timestamp; // to store previous buyback time
    uint256 public durationBetweenEachBuyback = 5 seconds; // duration betweeen each buyback

    bool swapping = false;

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        balances[sender] = balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );

        uint256 contractTokenBalance = balances[address(this)];
        if (
            liquidityTx >= 2 &&
            contractTokenBalance > 0 &&
            !swapping &&
            sender != joePair
        ) {
            swapping = true;
            liquidityTx = 0;
            swapAndLiquify(contractTokenBalance);
            swapping = false;
        }
        // && sender != owner() && recipient != owner()
        bool takeFee = !swapping;
        uint256 rxAmount = amount;
        if (takeFee) {
            takeFee = sender == joePair;
            if (takeFee) {
                takeFee = !(isExcludedFromFees[sender] ||
                    isExcludedFromFees[recipient]);
            }
        }
        if (takeFee) {
            takeFee = false;
            uint256 fee = amount.div(100).mul(2);
            rxAmount = amount.sub(fee);
            balances[address(this)] = balances[address(this)].add(fee);
            liquidityTx += 1;
        }

        balances[recipient] = balances[recipient].add(rxAmount);
        emit Transfer(sender, recipient, rxAmount);
    }

    function swapAndLiquify(uint256 amount) private {
        // split the amount into halves
        uint256 half = amount.div(2);
        // capture the contract's current ETH balance.
        // this is so that we can capture exactly the amount of ETH that the
        // swap creates, and not make the liquidity event include any ETH that
        // has been manually sent to the contract
        uint256 initialBalanceEth = address(this).balance;
        swapToETH(half);
        // how much ETH did we just swap into?

        uint256 newBalanceEth = address(this).balance.sub(initialBalanceEth);

        if (newBalanceEth > 0) {
            uint256 initialBalanceBbone = bboneToken.balanceOf(address(this));
            swapToBBone(half);
            uint256 newBalanceBbone = bboneToken.balanceOf(address(this)).sub(
                initialBalanceBbone
            );
            if (newBalanceBbone > 0) {
                // add liquidity to DEX
                addLiquidity(newBalanceBbone, newBalanceEth);
            }
        }
        /*
         */
    }

    function swapToETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();
        _approve(address(this), address(joeRouter), tokenAmount);

        // make the swap

        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function swapToBBone(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](3);
        path[0] = address(this);
        path[1] = joeRouter.WAVAX();
        path[2] = address(bboneToken);

        _approve(address(this), address(joeRouter), tokenAmount);

        // make the swap
        joeRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        bboneToken.approve(address(joeRouter), tokenAmount);

        // add the liquidity
        joeRouter.addLiquidityAVAX{value: ethAmount}(
            address(bboneToken),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            address(0),
            block.timestamp
        );
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
}
