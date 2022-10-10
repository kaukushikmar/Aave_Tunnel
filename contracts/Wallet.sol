// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWalletLib {
  function supply(
    address _asset,
    uint256 _amount,
    address _from
  ) external returns (bool);
}

contract Wallet {
  uint256 public amountSupplied;
  uint256 public amountBorrowed;

  IWalletLib immutable walletLib;

  constructor(address _wallet) {
    walletLib = IWalletLib(_wallet);
  }

  function supply(address _asset, uint256 _amount) public {
    require(walletLib.supply(_asset, _amount, address(this)));
    amountSupplied += _amount;
  }

  function borrow() public {}
}
