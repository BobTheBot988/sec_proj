// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.22;
import "./Taxpayer.sol";
import "./Lottery.sol";
import "./Time.sol";

contract State {
    event AssertionFailed(string reason);
    mapping(address => bool) private taxpayer;
    Lottery private immutable lottery;
    address private immutable owner;
    TimeTest t = new TimeTest();

    constructor() {
        owner = msg.sender;
        Lottery l = new Lottery(1 seconds);
        lottery = l;
    }

    function isTaxpayerValid(address t) external view returns (bool) {
        return taxpayer[t];
    }

    function isLotteryValid(address l) external view returns (bool) {
        return address(lottery) == l;
    }

    function getLottery() external view returns (Lottery) {
        // emit AssertionFailed("getLottery");
        return lottery;
    }

    function proxy_startlottery() external onlyOwner {
        Lottery(lottery).startLottery();
    }

    function proxy_endlottery(uint256 _seed) external onlyOwner {
        bytes32 _sealedSeed = keccak256(abi.encodePacked(address(this), _seed));

        Lottery(lottery).setSealedSeed(_sealedSeed);

        t.test_blocks_forward(2); // NOTE: make block.number go forward by 2
        Lottery(lottery).endLottery(_seed);
    }

    function addTaxpayer(address p1, address p2, int256 dob) public onlyOwner returns (Taxpayer) {
        require(taxpayer[p1] == true || p1 == address(0));
        require(taxpayer[p2] == true || p2 == address(0));

        Taxpayer t = new Taxpayer(p1, p2, dob);
        taxpayer[address(t)] = true;
        return t;
    }
}
