//SPDX-License-Identifier: MIT
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

contract WalletLib {
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

  function supply(
    address _asset,
    uint256 _amount,
    address _from
  ) public returns (bool) {
    IERC20 token = IERC20(_asset);

    token.approve(address(lendingPool), _amount);
    lendingPool.deposit(_asset, _amount, _from, 0);

    return true;
  }
}
