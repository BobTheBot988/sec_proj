// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;
import "../src/Taxpayer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract Test {
    event AssertionFailed(string reason);
    event Message(string msg);

    using Strings for uint256;

    Taxpayer[] taxpayer;
    uint256 internal constant N_OF_TAXPAYER = 10;

    constructor() public {
        for (uint256 index = 0; index < N_OF_TAXPAYER; index++) {
            taxpayer.push(new Taxpayer(address(0), address(0)));
        }
        // taxpayer[0].marry(address(taxpayer[1]));
    }

    function createOldTaxpayer() internal returns (Taxpayer) {}

    function checkMarried(Taxpayer t1) internal {
        Taxpayer spouse = t1.get_spouse();
        if (address(spouse) == address(0)) return;
        // emit AssertionFailed("The spouse is different");
        // assert(address(spouse.get_spouse()) == address(t1));
        if (address(spouse.get_spouse()) != address(t1)) {
            emit AssertionFailed("The spouse is different");
        }
    }

    function echidna_are_both_married() public {
        for (uint256 index = 0; index < taxpayer.length; index++) {
            emit Message(Strings.toString(index));
            checkMarried(taxpayer[index]);
        }
    }

    function isMarriedGood(Taxpayer t1) internal view returns (bool ret) {
        Taxpayer spouse = t1.get_spouse();
        if (address(spouse) == address(0)) {
            return true;
        }
        ret = address(spouse.get_spouse()) == address(t1);
    }

    function invariant_are_both_married() public view returns (bool) {
        for (uint256 index = 0; index < taxpayer.length; index++) {
            if (!isMarriedGood(taxpayer[index])) {
                return false;
            }
        }
        return true;
    }

    // function invariant_no_pedo() public view returns (bool) {}
}

