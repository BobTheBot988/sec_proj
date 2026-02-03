// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;

import "../src/Lottery.sol";
import "../src/Taxpayer.sol";
import "../src/State.sol";
import "../src/Time.sol";

contract TestLottery {
    event AssertionFailed(string reason);
    event Message(string msg);
    Taxpayer[] public players;
    uint256 constant NUM_PLAYERS = 2;
    State immutable s;
    Lottery immutable lot;
    uint16 constant N_OF_ROUNDS = 5;

    TimeTest immutable t = new TimeTest();

    // Pass initial setup to the Lottery constructor
    constructor() {
        // Create valid contract players
        s = new State();
        for (uint256 i = 0; i < NUM_PLAYERS; i++) {
            players.push(State(s).addTaxpayer(address(0), address(0), 0));
        }
    }

    // --- PROXY FUNCTIONS ---
    // These allow the fuzzer to orchestrate the players and the owner

    // function proxy_startLottery() public {
    //     // Mocking owner behavior (Lottery uses msg.sender check)
    //     // Since TestLottery inherits Lottery, we can set state or assume this contract is owner
    //     // if we deployed it. However, Lottery checks `onlyBy(owner)`.
    //     // We override owner for testing ease in constructor.
    //     lot.startLottery();
    // }
    //
    function proxy_player_commit(uint256 playerIndex) internal {
        uint256 idx = playerIndex % NUM_PLAYERS;
        players[idx].joinLottery();
    }
    //
    // function proxy_player_reveal(uint256 playerIndex) public {
    //     uint256 idx = playerIndex % NUM_PLAYERS;
    //     players[idx].doReveal();
    // }
    //
    // function proxy_endLottery() public {
    //     lot.endLottery();
    // }

    // --- INVARIANTS ---

    // Invariant 1: Time Consistency
    // If the lottery has started, the reveal and end times must be calculated correctly relative to period.
    // If it hasn't started, everything should be zero.
    // function echidna_state_times_consistent() public view returns (bool) {
    //     if (lot.startTime == 0) {
    //         return lot.revealTime == 0 && lot.endTime == 0;
    //     } else {
    //         return (lot.revealTime == lot.startTime + lot.period) && (lot.endTime == lot.revealTime + lot.period);
    //     }
    // }

    // Invariant 3: Revealed Integrity
    // Any address that ends up in the `revealed` array MUST have a corresponding commitment in `commits`.
    // It is illegal for a user to be marked as "revealed" if they never committed.
    // function echidna_revealed_users_must_have_committed() public view returns (bool) {
    //     for (uint256 i = 0; i < lot.revealed.length; i++) {
    //         address user = lot.revealed[i];
    //         if (lot.commits[user] == bytes32(0)) {
    //             return false;
    //         }
    //     }
    //     return true;
    // }

    // Invariant 4: No premature reveals
    // The `revealed` array should be empty if we are technically before the reveal phase.
    // Note: We check `revealTime` vs `startTime` logic.
    // If `revealed.length > 0`, we must be past `startTime`.
    // function echidna_no_reveal_before_start() public view returns (bool) {
    //     if (lot.startTime == 0) {
    //         return lot.revealed.length == 0;
    //     }
    //     return true;
    // }

    function player_round(uint256 idx) internal {
        proxy_player_commit(idx);
        // proxy_player_reveal(idx);
    }

    function lottery_rounds() internal {
        for (uint256 x = 0; x < N_OF_ROUNDS; x++) {
            // emit Message(Strings.toString(x));
            s.proxy_startlottery();

            for (uint256 index = 0; index < NUM_PLAYERS; index++) {
                player_round(index);
            }

            t.test_vesting(1 days); // NOTE: This makes time pass by one day
            s.proxy_endlottery();

            t.test_blocks_forward(2);
        }

        // emit AssertionFailed("Syca");
        // emit AssertionFailed("Suca");
    }

    function safe_exp_value_bool(uint256 player_idx) internal view returns (bool) {
        Taxpayer p = players[player_idx];
        int256 exp_val = int256(N_OF_ROUNDS * (10 ^ 18 / NUM_PLAYERS));
        int256 approx_exp_val = int256(p.getLotteryWins() * 10 ^ 18);
        int256 delta = exp_val - approx_exp_val;

        if (delta < 0) {
            delta = -delta;
        }

        return delta < (5 * 10 ^ 18);
    }

    function safe_exp_value(uint256 player_idx) internal {
        Taxpayer p = players[player_idx];
        int256 exp_val = int256((N_OF_ROUNDS + 1) * (10 ^ 18 / NUM_PLAYERS));
        int256 approx_exp_val = int256(p.getLotteryWins() * 10 ^ 18);
        int256 delta = exp_val - approx_exp_val;

        if (delta < 0) {
            delta = -delta;
        }

        if (delta > 5 * 10 ^ 18) {
            emit AssertionFailed(string.concat(
                    "The lottery is unfair, Expected val:",
                    Strings.toStringSigned(delta),
                    " Approx:",
                    Strings.toStringSigned(approx_exp_val),
                    " Delta:",
                    Strings.toStringSigned(delta)
                ));
        }
    }

    function invariant_test_fairness() public {
        lottery_rounds();

        for (uint256 index = 0; index < NUM_PLAYERS; index++) {
            safe_exp_value(index);
        }

        // emit AssertionFailed("Syca");
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
