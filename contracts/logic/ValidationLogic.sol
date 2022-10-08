// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { Error } from "../helper/Error.sol";

library ValidationLogic {
  using SafeMath for uint256;

  uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 2 ether;

  function withdrawValidation(
    uint256 _amount,
    address _asset,
    uint256 _userBalanceSupplied,
    uint256 _userBalanceBorrowed,
    address _oracle,
    uint256 _totalCollateral,
    uint256 _totalDebt
  ) external view returns (bool) {
    require(_amount != 0, Error.INVALID_AMOUNT);
    require(_amount <= _userBalanceSupplied, Error.NOT_ENOUGH_MONEY);
    uint256 amountToDecreaseInETH = IPriceOracle(_oracle)
      .getAssetPrice(_asset)
      .mul(_amount)
      .div(10**18);

    uint256 collateralAfterDecrease = _userBalanceSupplied.sub(
      amountToDecreaseInETH
    );

    if (collateralAfterDecrease <= 0) return false;

    uint256 healthFactorAfterWithdraw = collateralAfterDecrease.div(
      _userBalanceBorrowed
    );

    return (
      (healthFactorAfterWithdraw >=
        ValidationLogic.HEALTH_FACTOR_LIQUIDATION_THRESHOLD)
    );
  }
}
