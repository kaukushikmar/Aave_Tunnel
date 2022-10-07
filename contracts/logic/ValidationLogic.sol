// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IPriceOracle.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library ValidationLogic {
  using SafeMath for uint256;

  function withdrawValidation(
    address _pool,
    uint256 _amount,
    address _asset,
    address _oracle,
    uint256 _totalCollateral,
    uint256 _totalDebt
  ) external view returns (bool) {
    uint256 amountToDecreaseInETH = IPriceOracle(_oracle)
      .getAssetPrice(_asset)
      .mul(_amount)
      .div(10**18);

    uint256 collateralAfterDecrease = _totalCollateral.sub(
      amountToDecreaseInETH
    );

    if (collateralAfterDecrease <= 0) return false;

    uint256 healthFactorAfterWithdraw = collateralAfterDecrease.div(_totalDebt);
    uint256 healthFactorBefore = _totalCollateral.div(_totalDebt);

    return ((healthFactorBefore.sub(healthFactorAfterWithdraw)).mul(10) <= 1);
  }
}
