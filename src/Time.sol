// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;

interface IHevm {
    function warp(uint256) external;
    function roll(uint256) external;
}

contract TimeTest {
    IHevm vm = IHevm(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    function test_vesting(uint256 timeToJump) external {
        // Limit the jump to something reasonable, e.g., 1 year
        if (timeToJump > 31536000) return;

        uint256 preTime = block.timestamp;
        vm.warp(block.timestamp + timeToJump);

        assert(block.timestamp > preTime);
    }

    function test_blocks_forward(uint256 n) external {
        vm.roll(block.number + n);
    }
}
