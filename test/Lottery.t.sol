// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../src/Lottery.sol";
import "../src/Taxpayer.sol";
import "../src/State.sol";

import {Test} from "forge-std/Test.sol";
import {SymTest} from "halmos-cheatcodes/SymTest.sol";
import "../src/Time.sol";

contract LotteryTest is Test, SymTest {
    Taxpayer[] public players;
    uint16 constant NUM_PLAYERS = 2;
    State s;
    Lottery lot;
    uint16 N_OF_ROUNDS = 0;

    TimeTest immutable t = new TimeTest();

    function forEach(function(Taxpayer) internal constraint) internal {
        for (uint256 index = 0; index < players.length; index++) {
            constraint(players[index]);
        }
    }

    // Pass initial setup to the Lottery constructor
    //
    function setUp() public {
        // Create valid contract players
        s = new State();
        lot = s.getLottery();
        players.push(State(s).addTaxpayer(address(0), address(0), 0));
        players.push(State(s).addTaxpayer(address(0), address(0), 0));
        players.push(State(s).addTaxpayer(address(0), address(0), -1265385612));
    }

    function proxy_player_commit(Taxpayer p) internal {
        p.joinLottery();
    }

    function lottery_rounds(uint256 _seed) public {
        N_OF_ROUNDS += 1;
        s.proxy_startlottery();
        forEach(proxy_player_commit);

        t.test_vesting(1 days); // NOTE: This makes time pass by one day
        s.proxy_endlottery(_seed);

        t.test_blocks_forward(2); //NOTE: Makes the blocks go forward by n
    }

    function get_len() internal view returns (uint256 l) {
        l = players.length;
        for (uint256 index = 0; index < players.length; index++) {
            if (players[index].getYearsSinceBirth() >= 65) {
                l -= 1;
            }
        }
    }

    function check_safe_exp_value(Taxpayer p) internal view {
        vm.assume(address(p) != address(0));
        if (p.getYearsSinceBirth() >= 65) {
            return;
        }
        int256 exp_val = int256((N_OF_ROUNDS) * ((10 ** 18) / get_len()));
        int256 approx_exp_val = int256(p.getLotteryWins() * (10 ** 18));
        int256 delta = exp_val - approx_exp_val;

        if (delta < 0) {
            delta = -delta;
        }
        // if ( N_OF_ROUNDS >= 20){
        //   emit AssertionFailed("rounds!!!!");
        // }
        assert(delta <= 10 * (10 ** 18));
    }

    function test_invariant_fairness() public {
        forEach(check_safe_exp_value);
    }

    function age(Taxpayer p) internal view {
        bool i = lot.getTaxPayer(address(p));

        assert(!i || (p.getYearsSinceBirth() < 65));
    }

    function test_invariant_age() public {
        forEach(age);
    }

    // === Bounded action tests (Halmos + Foundry) ===

    enum LotActionType { START, COMMIT, END, WARP, NOOP }

    struct LotAction {
        uint8 actionType;
        uint256 playerIdx;
        uint256 seed;       // seed for END
        uint256 warpTime;   // time to warp for WARP
    }

    // --- Execution helpers ---

    function _tryStart() internal {
        s.proxy_startlottery();
    }

    function _tryCommit(uint256 idx) internal {
        uint256 i = idx % players.length;
        vm.prank(address(players[i]));
        players[i].joinLottery();
    }

    function _tryEnd(uint256 seed) internal {
        s.proxy_endlottery(seed);
    }

    function _tryWarp(uint256 time) internal {
        vm.warp(block.timestamp + time);
    }

    // --- Invariants (checked after each action) ---

    function _assertLotInvariants() internal view {
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i].getLotteryWins() > 0) {
                assert(players[i].getYearsSinceBirth() < 65);
            }
        }
    }

    // --- Halmos entry point ---

    function check_LotSystemInvariants(LotAction[4] memory actions) public {
        for (uint256 i = 0; i < actions.length; i++) {
            vm.assume(actions[i].actionType <= 4);

            LotActionType act = LotActionType(actions[i].actionType);

            if (act == LotActionType.START) {
                _tryStart();
            } else if (act == LotActionType.COMMIT) {
                _tryCommit(actions[i].playerIdx);
            } else if (act == LotActionType.END) {
                vm.warp(block.timestamp + 1 days);
                _tryEnd(actions[i].seed);
            } else if (act == LotActionType.WARP) {
                _tryWarp(actions[i].warpTime);
            }
            _assertLotInvariants();
        }
    }

    // --- Foundry entry point ---

    function test_LotSystemInvariants(LotAction[4] memory actions) public {
        for (uint256 i = 0; i < actions.length; i++) {
            actions[i].actionType = uint8(bound(actions[i].actionType, 0, 4));

            LotActionType act = LotActionType(actions[i].actionType);

            if (act == LotActionType.START) {
                _tryStart();
            } else if (act == LotActionType.COMMIT) {
                _tryCommit(actions[i].playerIdx);
            } else if (act == LotActionType.END) {
                vm.warp(block.timestamp + 1 days);
                _tryEnd(actions[i].seed);
            } else if (act == LotActionType.WARP) {
                _tryWarp(actions[i].warpTime);
            }
            _assertLotInvariants();
        }
    }

    // function echidna_test_fairness() public returns (bool) {
    //     lottery_rounds();
    //     for (uint256 index = 0; index < NUM_PLAYERS; index++) {
    //         safe_exp_value_bool(index);
    //     }
    //     return true;
    // }

    // Invariant 5: Unique Reveals (Optional Logic Check)
    // The `revealed` array implies successful reveals.
    // `total_revealed` must equal the sum of inputs.
    // While we can't sum easily in a view, we can check that `total_revealed > 0` if `revealed.length > 0`
    // assuming inputs are non-zero (though 0 is a valid uint256, it's rare in fuzzing to only hit 0).
    // function echidna_total_revealed_consistency() public view returns (bool) {
    //     if (lot.revealed.length > 0 && lot.total_revealed == 0) {
    //         // This is actually possible if someone reveals the number 0.
    //         // So we might just check that if revealed is empty, total is 0.
    //         return false;
    //     }
    //     if (lot.revealed.length == 0) {
    //         return lot.total_revealed == 0;
    //     }
    //     return true;
    // }
}
