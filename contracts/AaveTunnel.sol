// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Wallet.sol";

interface IWallet {
  function supply(address _asset, uint256 _amount) external;
}

/** @notice user can only supply weth and borrow weth */
contract AaveTunnel {
  address immutable _walletLogic;
  uint256 _check = 1;
  mapping(address => bool) isSupplied;
  mapping(address => address) userToWallet;

  constructor(address _add) {
    _walletLogic = _add;
  }

  function supply(address _asset, uint256 _amount) external {
    if (isSupplied[msg.sender] == true) {
      IWallet wallet = IWallet(userToWallet[msg.sender]);
      wallet.supply(_asset, _amount);
    } else {
      Wallet wallet = new Wallet(_walletLogic);
      isSupplied[msg.sender] = true;
      userToWallet[msg.sender] = address(wallet);
      wallet.supply(_asset, _amount);
    }
  }

  // function supplyEth() external payable {
  //   require(msg.value > 0, "Not suppliet eth");
  //   weth.deposit{ value: msg.value }();

  //   uint256 initialPoolBalance = aTokens.balanceOf(address(this));

  //   require(weth.transfer(address(lendingPool), msg.value));

  //   uint256 finalPoolBalance = aTokens.balanceOf(address(this));
  //   AmountSupplied[msg.sender] += finalPoolBalance - initialPoolBalance;
  // }

  // function withdraw(address _asset, uint256 _amount) external noRentry {
  //   require(AmountSupplied[msg.sender] >= _amount, Error.WITHDRAW_NOT_ALLOWED);

  //   // very primitive withdraw validate logic
  //   require(
  //     ValidationLogic.withdrawValidation(
  //       _amount,
  //       _asset,
  //       AmountSupplied[msg.sender],
  //       AmountBorrowed[msg.sender],
  //       address(priceOracle)
  //     ),
  //     Error.WITHDRAW_NOT_ALLOWED
  //   );

  //   uint256 initialPoolBalance = aTokens.balanceOf(address(this));

  //   uint256 withdrawAmount = lendingPool.withdraw(
  //     _asset,
  //     _amount,
  //     address(this)
  //   );

  //   uint256 finalPoolBalance = aTokens.balanceOf(address(this));

  //   AmountSupplied[msg.sender] += finalPoolBalance - initialPoolBalance;
  //   require(IERC20(_asset).transfer(msg.sender, withdrawAmount));
  // }

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
  // function borrow(
  //   address _asset,
  //   uint256 _amount,
  //   uint256 _mode
  // ) external noRentry {
  //   require(
  //     ValidationLogic.borrowValidation(
  //       _amount,
  //       AmountSupplied[msg.sender],
  //       AmountBorrowed[msg.sender]
  //     )
  //   );

  //   lendingPool.borrow(_asset, _amount, _mode, 0, address(this));
  //   require(IERC20(_asset).transfer(msg.sender, _amount));
  // }

  // function repay(
  //   address _asset,
  //   uint256 _amount,
  //   uint256 _mode
  // ) external {
  //   // not checking if he repays more than total borrow after accrual
  //   IERC20 token = IERC20(_asset);
  //   require(token.transferFrom(msg.sender, address(this), _amount));

  //   token.approve(address(lendingPool), _amount);

  //   uint256 repaid = lendingPool.repay(_asset, _amount, _mode, address(this));
  //   require(repaid == _amount);
  // }

  // receive() external payable {}

  /** modifier */
  modifier noRentry() {
    require(_check == 1);
    _check = 2;
    _;
    _check = 1;
  }

  /** view functions */
  // function getSuppliedAmount(address _user) external view returns (uint256) {
  //   return AmountSupplied[_user];
  // }
}
