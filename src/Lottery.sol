// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.22;
import "./Taxpayer.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./State.sol";

import "./Time.sol";

contract Lottery {
    event AssertionFailed(string reason);
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    TimeTest immutable t = new TimeTest();
    address owner;
    mapping(address => bool) commits;
    // mapping(address => uint256) reveals;
    address[] taxpayer;
    bool seedSet = false;
    bytes32 sealedSeed;
    uint256 storedBlockNumber;
    uint256 startTime;
    uint256 endTime;
    uint256 period;

    modifier onlyAfter(uint256 _time) {
        require(block.timestamp >= _time);
        _;
    }

    function changeOwner(address _newOwner) public onlyBy(owner) {
        require(block.timestamp < endTime);
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    // Initialize the registry with the lottery period.
    // The owner should be set
    constructor(uint256 p) {
        require(p > 0);
        owner = msg.sender;
        period = p;
        startTime = 0;
        endTime = 0;
        // iscontract = true;
    }

    //If the lottery has not started, anyone can invoke a lottery.
    function startLottery() public onlyBy(owner) {
        require(startTime == 0);
        // commits = {};
        //startTime current time. Users send their committed value
        startTime = block.timestamp;
        //revealTime  time for revealing. User reveal their value
        //endTime a winner can be computed
        endTime = startTime + period;
    }

    //A taxpayer send his own commitment.
    function commit() public {
        // emit AssertionFailed("Commita");
        require(block.timestamp >= startTime);
        require(block.timestamp < endTime);
        require(State(owner).isTaxpayerValid(msg.sender));
        // require(Taxpayer(msg.sender).getYearsSinceBirth() < 65);
        
        commits[msg.sender] = true;
        taxpayer.push(msg.sender);
    }

    // Randomness provided by this is predicatable. Use with care!
    function get_random_number_stupid_pattern() internal returns (uint256) {
        // t.test_vesting(2 weeks);
        return uint256(blockhash(block.number - 1));
    }

    function setSealedSeed(bytes32 _sealedSeed) public onlyBy(owner) {
        require(!seedSet);
        sealedSeed = _sealedSeed;
        storedBlockNumber = block.number + 1;
        seedSet = true;
    }

    function get_random_number_safe_pattern(uint256 _seed) internal view returns (uint256) {
        require(seedSet);
        require(taxpayer.length > 0);
        // emit AssertionFailed(string.concat(
        //         "hash: ",
        //         Strings.toString(uint256(keccak256(abi.encodePacked(owner, _seed)))),
        //         " sealed_seed: ",
        //         Strings.toString(uint256(sealedSeed))
        //     ));
        require(storedBlockNumber < block.number);

        require(keccak256(abi.encodePacked(owner, _seed)) == sealedSeed);
        // Insert logic for usage of random number here;
        // betsClosed = false;
        return uint256(keccak256(abi.encodePacked(_seed, blockhash(storedBlockNumber))));
    }
    //A valid taxpayer who sent his own commitment, sends the revealing value.

    //Ends the lottery and compute the winner.
   // The owner could never end the lottery
    function getTaxPayer(address t) public view returns (bool){
       
      return commits[t] == true;
    }
    function endLottery(uint256 _seed) public onlyBy(owner) {
        // Block time stamp is not safe since the verifier could lie

        require(block.timestamp >= endTime);

        uint256 winnerIndex = get_random_number_safe_pattern(_seed) % taxpayer.length;
        address winnerAddress = taxpayer[winnerIndex];

        // for (uint256 i = 0; i < revealed_len; i++) {
        //     total += reveals[revealed[i]];
        // }

        Taxpayer(winnerAddress).wonLottery();
        seedSet = false;
        startTime = 0;

        endTime = 0;
        // The state pays
        for (uint256 index = 0; index < taxpayer.length; index++) {
            commits[taxpayer[index]] = false;
            taxpayer[index] = address(0);
        }
    }
}
