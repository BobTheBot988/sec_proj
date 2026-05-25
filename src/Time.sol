// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";

contract TimeTest is Test {
    function test_vesting(uint256 timeToJump) external {
        timeToJump = bound(timeToJump, 1, 31535999);

        uint256 preTime = block.timestamp;
        vm.warp(block.timestamp + timeToJump);

        assert(block.timestamp > preTime);
    }

    function test_blocks_forward(uint64 n) external {
        vm.roll(block.number + n);
    }
}
