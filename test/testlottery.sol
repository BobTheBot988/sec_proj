// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.33;
import "../src/Lottery.sol";

contract TestLottery is Lottery {
    constructor() public {}

    function invariant_() public view returns (bool) {
        return false;
    }
}
