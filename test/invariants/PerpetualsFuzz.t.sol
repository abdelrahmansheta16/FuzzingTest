// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {VM} from "forge-std/Vm.sol";
import {MinimumPerps} from "../../src/MinimumPerps.sol";

contract PerpetualsFuzz {
  VM vm = VM(address(0));

  function testOpenInterest() public {
    MinimumPerps perp = new MinimumPerps("Perp", "PUSD", address(0), address(0), address(0), 0);

    // Generate random values for deposited liquidity and collateral price
    uint256 depositedLiquidity = vm.randomUint(100);
    uint256 collateralPrice = vm.randomUint(100);

    // Set deposited liquidity and collateral price in the contract
    perp.mint(address(this), depositedLiquidity);

    // Open long positions to reach near 50% of deposited liquidity
    uint256 openInterestTarget = depositedLiquidity * collateralPrice / 2;
    uint256 remainingOI = openInterestTarget;
    while (remainingOI > 0) {
      uint256 size = vm.randomUint(remainingOI);
      perp.increasePosition(true, size, 0);
      remainingOI -= size;
    }

    // Check if open interest is less than or equal to the target
    assert(perp.openInterestLong() <= openInterestTarget);
  }

  function testCollateralWithdrawal() public {
    MinimumPerps perp = new MinimumPerps("Perp", "PUSD", address(0), address(0), address(0), 0);

    // Generate random values for deposited collateral
    uint256 depositedCollateral = vm.randomUint(100);

    // Deposit collateral
    perp.mint(address(this), depositedCollateral);

    // Attempt to withdraw more than deposited amount
    vm.expectRevert("InsufficientCollateralForLoss");
    perp.withdraw(address(this), depositedCollateral + 1);
  }

  function testMinimumMargin() public {
    MinimumPerps perp = new MinimumPerps("Perp", "PUSD", address(0), address(0), address(0), 10); // Minimum margin = 10%

    // Generate random values for deposited liquidity and collateral price
    uint256 depositedLiquidity = vm.randomUint(100);
    uint256 collateralPrice = vm.randomUint(100);

    // Set deposited liquidity and collateral price in the contract
    perp.mint(address(this), depositedLiquidity);

    // Calculate minimum required collateral based on deposited liquidity and margin
    uint256 minCollateral = depositedLiquidity * collateralPrice / 100; // 100 = 100%

    // Open long positions to reach near minimum required collateral
    uint256 remainingCollateral = minCollateral;
    while (remainingCollateral > 0) {
      uint256 size = vm.randomUint(remainingCollateral);
      perp.increasePosition(true, size, 0);
      remainingCollateral -= size;
    }

    // Check if user's collateral is less than minimum requirement
    vm.expectRevert("InsufficientCollateral");
    perp.increasePosition(true, 1, 0); // Try to open a small additional position
  }
  
    // **clear screen**
}
