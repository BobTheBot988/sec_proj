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

    constructor() {
        for (uint256 index = 0; index < N_OF_TAXPAYER; index++) {
            taxpayer.push(new Taxpayer(address(0), address(0)));
        }
        // taxpayer[0].marry(address(taxpayer[1]));
        // taxpayer[0].setTaxAllowance(1000000);
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

    function checkAllowance(Taxpayer t1) internal {
        if (t1.getTaxAllowance() > t1.getPoolAllowance()) {
            emit AssertionFailed("Too much money saved in taxes");
        }
        Taxpayer sp = t1.get_spouse();

        if (address(sp) != address(0)) {
            if (t1.getPoolAllowance() != sp.getPoolAllowance()) {
                emit AssertionFailed("The pool allowance must be equal for both spouses");
            }
            if ((t1.getTaxAllowance() + sp.getTaxAllowance()) > t1.getPoolAllowance()) {
                emit AssertionFailed("Too much money saved in taxes but both");
            }
        }
    }

    function echidna_is_tax_allowance_good() public {
        for (uint256 index = 0; index < taxpayer.length; index++) {
            emit Message(Strings.toString(index));
            checkAllowance(taxpayer[index]);
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

