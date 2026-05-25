// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;
import "../src/Taxpayer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "../src/State.sol";
import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";

contract TaxpayerTest is Test, SymTest {
    uint256 constant oldAge = 65;
    using Strings for uint256;

    Taxpayer[] taxpayer;
    uint256 internal constant N_OF_TAXPAYER = 3;
    State s;

    function setUp() public {
        s = new State();
        taxpayer.push(s.addTaxpayer(address(0), address(0), 0));
        taxpayer.push(s.addTaxpayer(address(0), address(0), 0));
        taxpayer.push(s.addTaxpayer(address(0), address(0), -1265385612));
    }

    function forEach(function(Taxpayer) internal constraint) internal {
        for (uint256 index = 0; index < N_OF_TAXPAYER; index++) {
            vm.startPrank(address(taxpayer[index]));
            constraint(taxpayer[index]);
            vm.stopPrank();
        }
    }

    function checkMarried(Taxpayer t1) internal view {
        Taxpayer spouse = t1.get_spouse();
        if (address(spouse) == address(0)) return;
        assert(address(spouse.get_spouse()) == address(t1));
    }

    function test_invariant_both_married() public {
        forEach(checkMarried);
    }

    function checkAllowance(Taxpayer t1) internal view {
        vm.assume(t1.getTaxAllowance() <= t1.getPoolAllowance());

        Taxpayer sp = t1.get_spouse();

        if (address(sp) != address(0)) {
            assert(t1.getPoolAllowance() == sp.getPoolAllowance());

            assert((t1.getTaxAllowance() + sp.getTaxAllowance()) == t1.getPoolAllowance());
        }
    }

    function test_invariant_is_tax_allowance_good() public {
        forEach(checkAllowance);
    }

    function checkAgeAllowance(Taxpayer t1) internal view {
        uint256 my_mod = 0;
        uint256 my_num = 5000;
        if ((t1.getYearsSinceBirth() >= oldAge) && t1.get_counter()) {
            my_mod += 2000;
        }
        my_mod += (t1.getLotteryWins() * 2000);
        Taxpayer sp = t1.get_spouse();
        if (address(sp) != address(0)) {
            my_num = my_num * 2;
            if (sp.getYearsSinceBirth() >= oldAge && sp.get_counter()) {
                my_mod += 2000;
            }

            my_mod += (sp.getLotteryWins() * 2000);
        }
        assert(t1.getPoolAllowance() == (my_num + my_mod));
    }

    function test_invariant_is_aged_tax_allowance_good() public {
        forEach(checkAgeAllowance);
    }

    // function echidna_is_tax_allowance_good() public {
    //     for (uint256 index = 0; index < taxpayer.length; index++) {
    //         emit Message(Strings.toString(index));
    //         checkAllowance(taxpayer[index]);
    //     }
    // }

    // function isMarriedGood(Taxpayer t1) internal view returns (bool ret) {
    //     Taxpayer spouse = t1.get_spouse();
    //     if (address(spouse) == address(0)) {
    //         return true;
    //     }
    //     ret = address(spouse.get_spouse()) == address(t1);
    // }
    //
    // function invariant_are_both_married() public view returns (bool) {
    //     for (uint256 index = 0; index < taxpayer.length; index++) {
    //         if (!isMarriedGood(taxpayer[index])) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    // function invariant_no_pedo() public view returns (bool) {}

    // === Bounded action tests (Halmos + Foundry) ===

    enum TaxActionType {
        MARRY,
        DIVORCE,
        TRANSFER,
        RAISE,
        NOOP
    }

    struct TaxAction {
        uint8 actionType;
        uint256 targetIdx;
        uint256 auxIdx; // spouse index for MARRY
        uint256 amount; // amount for TRANSFER
    }

    // --- Execution helpers ---

    function _tryMarry(uint256 idx, uint256 spouseIdx) internal {
        vm.startPrank(address(taxpayer[idx]));
        taxpayer[idx].marry(address(taxpayer[spouseIdx]));
        vm.stopPrank();
    }

    function _tryDivorce(uint256 idx) internal {
        address sp = address(taxpayer[idx].get_spouse());
        if (sp == address(0)) return;
        vm.startPrank(sp);
        Taxpayer(sp).divorce();
        vm.stopPrank();
    }

    function _tryTransfer(uint256 idx, uint256 amount) internal {
        vm.startPrank(address(taxpayer[idx]));
        taxpayer[idx].transferAllowance(amount);
        vm.stopPrank();
    }

    function _tryRaise(uint256 idx) internal {
        vm.startPrank(address(taxpayer[idx]));
        taxpayer[idx].raiseOwnAllowance();
        vm.stopPrank();
    }

    // --- Foundry test execution (with revert handling) ---

    function _test_tryMarry(uint256 idx, uint256 spouseIdx) internal {
        vm.startPrank(address(taxpayer[idx]));
        if (idx == spouseIdx) {
            vm.expectRevert();
            taxpayer[idx].marry(address(taxpayer[spouseIdx]));
        } else {
            taxpayer[idx].marry(address(taxpayer[spouseIdx]));
        }
        vm.stopPrank();
    }

    function _test_tryDivorce(uint256 idx) internal {
        address sp = address(taxpayer[idx].get_spouse());
        if (sp == address(0)) return;
        vm.startPrank(sp);
        Taxpayer(sp).divorce();
        vm.stopPrank();
    }

    function _test_tryTransfer(uint256 idx, uint256 amount) internal {
        vm.startPrank(address(taxpayer[idx]));
        if (address(taxpayer[idx].get_spouse()) == address(0)) {
            vm.expectRevert();
            taxpayer[idx].transferAllowance(amount);
        } else {
            taxpayer[idx].transferAllowance(amount);
        }
        vm.stopPrank();
    }

    function _test_tryRaise(uint256 idx) internal {
        vm.startPrank(address(taxpayer[idx]));
        taxpayer[idx].raiseOwnAllowance();
        vm.stopPrank();
    }

    // --- Invariants (checked after each action) ---

    function _assertInvariants() internal view {
        for (uint256 i = 0; i < N_OF_TAXPAYER; i++) {
            Taxpayer t = taxpayer[i];

            // 1. Tax allowance never exceeds pool allowance
            assert(t.getTaxAllowance() <= t.getPoolAllowance());

            // 2. If married, spouse relationship is symmetric
            address sp = address(t.get_spouse());
            if (sp != address(0)) {
                assert(address(Taxpayer(sp).get_spouse()) == address(t));
                // 3. Married couple shares same pool
                assert(t.getPoolAllowance() == Taxpayer(sp).getPoolAllowance());
                // 4. Sum of tax allowances = pool
                assert(t.getTaxAllowance() + Taxpayer(sp).getTaxAllowance() == t.getPoolAllowance());
            }
        }
    }

    // --- Halmos entry point ---

    function check_SystemInvariants(TaxAction[6] memory actions) public {
        for (uint256 i = 0; i < actions.length; i++) {
            vm.assume(actions[i].actionType <= 4);

            TaxActionType act = TaxActionType(actions[i].actionType);
            uint256 idx = actions[i].targetIdx % N_OF_TAXPAYER;

            if (act == TaxActionType.MARRY) {
                uint256 spouseIdx = actions[i].auxIdx % N_OF_TAXPAYER;
                if (idx != spouseIdx) {
                    _tryMarry(idx, spouseIdx);
                }
            } else if (act == TaxActionType.DIVORCE) {
                _tryDivorce(idx);
            } else if (act == TaxActionType.TRANSFER) {
                _tryTransfer(idx, actions[i].amount);
            } else if (act == TaxActionType.RAISE) {
                _tryRaise(idx);
            }
            _assertInvariants();
        }
    }

    // --- Foundry entry point ---

    function test_SystemInvariants(TaxAction[6] memory actions) public {
        for (uint256 i = 0; i < actions.length; i++) {
            actions[i].actionType = uint8(bound(actions[i].actionType, 0, 4));

            TaxActionType act = TaxActionType(actions[i].actionType);
            uint256 idx = bound(actions[i].targetIdx, 0, N_OF_TAXPAYER - 1);

            if (act == TaxActionType.MARRY) {
                uint256 spouseIdx = bound(actions[i].auxIdx, 0, N_OF_TAXPAYER - 1);
                _test_tryMarry(idx, spouseIdx);
            } else if (act == TaxActionType.DIVORCE) {
                _test_tryDivorce(idx);
            } else if (act == TaxActionType.TRANSFER) {
                _test_tryTransfer(idx, actions[i].amount);
            } else if (act == TaxActionType.RAISE) {
                _test_tryRaise(idx);
            }
            _assertInvariants();
        }
    }
}

