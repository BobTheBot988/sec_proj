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
    uint16 N_OF_ROUNDS = 0;

    TimeTest immutable t = new TimeTest();

    // Pass initial setup to the Lottery constructor
    constructor() {
        // Create valid contract players
        s = new State();
        for (uint256 i = 0; i < NUM_PLAYERS; i++) {
            players.push(State(s).addTaxpayer(address(0), address(0), 0));
        }
    }

    function proxy_player_commit(uint256 playerIndex) internal {
        uint256 idx = playerIndex % NUM_PLAYERS;
        players[idx].joinLottery();
    }

    function player_round(uint256 idx) internal {
        proxy_player_commit(idx);
    }

    function lottery_rounds(uint256 _seed) public {
            N_OF_ROUNDS+=1;
            s.proxy_startlottery();

            for (uint256 index = 0; index < NUM_PLAYERS; index++) {
                player_round(index);
            }

            t.test_vesting(1 days); // NOTE: This makes time pass by one day
            s.proxy_endlottery(_seed);

            t.test_blocks_forward(2); //NOTE: Makes the blocks go forward by one
    }

    function safe_exp_value(uint256 player_idx) internal {
        Taxpayer p = players[player_idx];
        int256 exp_val = int256((N_OF_ROUNDS) * (( 10 ** 18 ) / NUM_PLAYERS));
        int256 approx_exp_val = int256(p.getLotteryWins() * ( 10 ** 18 ));
        int256 delta = exp_val - approx_exp_val;

        if (delta < 0) {
            delta = -delta;
        }
        // if ( N_OF_ROUNDS >= 20){
        //   emit AssertionFailed("rounds!!!!");
        // }
        if (delta > 10 * ( 10 ** 18 )) {
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
        for (uint256 index = 0; index < NUM_PLAYERS; index++) {
            safe_exp_value(index);
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
