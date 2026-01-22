// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

contract FoundryTest is Test {
    address constant USER1 = address(0x10000);

    // TODO: Replace with your actual contract instance
    Test Target;

  function setUp() public {
      // TODO: Initialize your contract here
      Target = new Test();
  }

  function test_replay() public {
        _setUpActor(USER1);
        Target.haveBirthday();
        _delay(0x304a2, 0x7b0c);
    _setUpActor(USER1);
        Target.supportsInterface(hex"000670c7");
        _setUpActor(USER1);
        Target.marry(address(0x492934308e98b590a626666b703a6ddf2120e85e));
        _setUpActor(USER1);
        Target.echidna_are_both_married();
  }

  function _setUpActor(address actor) internal {
      vm.startPrank(actor);
      // Add any additional actor setup here if needed
  }

  function _delay(uint256 timeInSeconds, uint256 numBlocks) internal {
      vm.warp(block.timestamp + timeInSeconds);
      vm.roll(block.number + numBlocks);
  }
}
