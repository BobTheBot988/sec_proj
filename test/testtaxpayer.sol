// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.33;
import "../src/Taxpayer.sol";

contract Test {
    Taxpayer[] taxpayer;
    uint256 internal constant N_OF_TAXPAYER = 10;

    constructor() public {
        for (uint256 index = 0; index < N_OF_TAXPAYER; index++) {
            taxpayer.push(new Taxpayer(address(0), address(0)));
        }
    }

    function createOldTaxpayer() internal returns (Taxpayer) {}

    function checkMarried(Taxpayer t1) internal view returns (bool) {}

    function invariant_are_both_married() public view returns (bool) {
        for (uint256 index = 0; index < taxpayer.length; index++) {
            checkMarried(taxpayer[index]);
        }
    }
    // function invariant_no_pedo() public view returns (bool) {}
}

