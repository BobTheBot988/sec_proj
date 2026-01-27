// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;
import "../src/Taxpayer.sol";
import "../src/Lottery.sol";

contract Test {
    event AssertionFailed(string reason);
    event Message(string msg);
    uint256 constant oldAge = 1;

    Taxpayer[] taxpayer;

    function forEachTaxpayer(function(Taxpayer) internal a) internal {
        for (uint256 index = 0; index < N_OF_TAXPAYER; index++) {
            emit Message(Strings.toString(index));
            a(taxpayer[index]);
        }
    }

    function forEachLottery(function(Taxpayer) internal a) internal {
        for (uint256 index = 0; index < N_OF_LOTTERIES; index++) {
            emit Message(Strings.toString(index));
            a(taxpayer[index]);
        }
    }
}
