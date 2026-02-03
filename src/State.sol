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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
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

    function proxy_startlottery() external {
        // emit AssertionFailed("Suca");
        Lottery(lottery).startLottery();
    }

    function proxy_endlottery() external {
        bytes32 n = keccak256(abi.encode(block.number));
        bytes32 seed = keccak256(abi.encodePacked(address(this), n));

        Lottery(lottery).setSealedSeed(seed);

        t.test_blocks_forward(2); // NOTE: make block.number go forward by 2
        // t.test_vesting(2 days); // NOTE: make block.number go forward by 2
        Lottery(lottery).endLottery(n);
    }

    function addTaxpayer(address p1, address p2, int256 dob) public onlyOwner returns (Taxpayer) {
        require(taxpayer[p1] == true || p1 == address(0));
        require(taxpayer[p2] == true || p2 == address(0));

        Taxpayer t = new Taxpayer(p1, p2, dob);
        taxpayer[address(t)] = true;
        return t;
    }
}
