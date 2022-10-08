// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/ILendingPoolAddressProvider.sol";
import "./interfaces/ILendingPool.sol";
import "./interfaces/IWeth.sol";
import "./interfaces/IERC20.sol";
import { IAToken } from "./interfaces/IAToken.sol";
import { IPriceOracle } from "./interfaces/IPriceOracle.sol";
import { ValidationLogic } from "./logic/ValidationLogic.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Error } from "./helper/Error.sol";
import "hardhat/console.sol";

/** @notice user can only supply weth and borrow weth */
contract AaveTunnel {
  using SafeMath for uint256;

  /** State Variable */
  uint256 _check = 1; // reentrancy check
  mapping(address => uint256) AmountSupplied;
  mapping(address => uint256) AmountBorrowed;

  ILendingPool immutable lendingPool;
  IAToken immutable aTokens;
  IWeth immutable weth;
  IPriceOracle immutable priceOracle;

  constructor(
    address _lendingPool,
    address _aTokens,
    address _weth,
    address _oracle
  ) {
    lendingPool = ILendingPool(_lendingPool);
    aTokens = IAToken(_aTokens);
    weth = IWeth(_weth);
    priceOracle = IPriceOracle(_oracle);
  }

  function supply(address _asset, uint256 _amount) external {
    IERC20 token = IERC20(_asset);

    require(token.balanceOf(msg.sender) >= _amount, "Insufficient balance");
    console.log("Passed the insufficient balance check");
    require(
      token.transferFrom(msg.sender, address(this), _amount),
      "Transfer failed"
    );

    uint256 initialPoolBalance = aTokens.balanceOf(address(this));
    console.log(initialPoolBalance);

    token.approve(address(lendingPool), _amount);
    lendingPool.deposit(_asset, _amount, address(this), 0);

    uint256 finalPoolBalance = aTokens.balanceOf(address(this));
    console.log(finalPoolBalance);
    AmountSupplied[msg.sender] = AmountSupplied[msg.sender].add(
      finalPoolBalance.sub(initialPoolBalance)
    );
  }

  // function supplyEth() external payable {
  //   require(msg.value > 0, "Not suppliet eth");
  //   weth.deposit{ value: msg.value }();

  //   uint256 initialPoolBalance = aTokens.balanceOf(address(this));

  //   require(weth.transfer(address(lendingPool), msg.value));

  //   uint256 finalPoolBalance = aTokens.balanceOf(address(this));
  //   AmountSupplied[msg.sender] += finalPoolBalance - initialPoolBalance;
  // }

  function withdraw(address _asset, uint256 _amount) external noRentry {
    require(AmountSupplied[msg.sender] >= _amount, Error.WITHDRAW_NOT_ALLOWED);

    // very primitive withdraw validate logic
    require(
      ValidationLogic.withdrawValidation(
        _amount,
        _asset,
        AmountSupplied[msg.sender],
        AmountBorrowed[msg.sender],
        address(priceOracle)
      ),
      Error.WITHDRAW_NOT_ALLOWED
    );

    uint256 initialPoolBalance = aTokens.balanceOf(address(this));

    uint256 withdrawAmount = lendingPool.withdraw(
      _asset,
      _amount,
      address(this)
    );

    uint256 finalPoolBalance = aTokens.balanceOf(address(this));

    AmountSupplied[msg.sender] += finalPoolBalance - initialPoolBalance;
    require(IERC20(_asset).transfer(msg.sender, withdrawAmount));
  }

  // /** @dev Function to withdraw eth by user if he/she has supplied eth/weth */
  // function withdrawEth(uint256 _amount) external noRentry {
  //   address _asset = address(weth);
  //   require(AmountSupplied[msg.sender] >= _amount, "Not enough to withdraw");
  //   uint256 withdrawAmount = lendingPool.withdraw(
  //     _asset,
  //     _amount,
  //     address(this)
  //   );

  //   AmountSupplied[msg.sender] -= withdrawAmount;
  //   require(weth.transfer(msg.sender, withdrawAmount));
  // }

  /** @dev user can only borrow if and only if he has supplied in this asset */
  function borrow(
    address _asset,
    uint256 _amount,
    uint256 _mode
  ) external noRentry {
    require(
      ValidationLogic.borrowValidation(
        _amount,
        AmountSupplied[msg.sender],
        AmountBorrowed[msg.sender]
      )
    );

    lendingPool.borrow(_asset, _amount, _mode, 0, address(this));
    require(IERC20(_asset).transfer(msg.sender, _amount));
  }

  function repay(
    address _asset,
    uint256 _amount,
    uint256 _mode
  ) external {
    // not checking if he repays more than total borrow after accrual
    IERC20 token = IERC20(_asset);
    require(token.transferFrom(msg.sender, address(this), _amount));

    token.approve(address(lendingPool), _amount);

    uint256 repaid = lendingPool.repay(_asset, _amount, _mode, address(this));
    require(repaid == _amount);
  }

  receive() external payable {}

  /** modifier */
  modifier noRentry() {
    require(_check == 1);
    _check = 2;
    _;
    _check = 1;
  }

  /** view functions */
  function getSuppliedAmount(address _user) external view returns (uint256) {
    return AmountSupplied[_user];
  }
}
