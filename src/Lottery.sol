pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED
import "./Taxpayer.sol";

import "./ERC165.sol";

interface ILottery is ERC165 {
    //If the lottery has not started, anyone can invoke a lottery.
    function startLottery() external;

    //A taxpayer send his own commitment.
    function commit(bytes32 y) external;

    //A valid taxpayer who sent his own commitment, sends the revealing value.
    function reveal(uint256 rev) external;

    //Ends the lottery and compute the winner.
    function endLottery() external;
}

contract Lottery is ILottery, ERC165Query {
    modifier onlyBy(address _account) {
        require(msg.sender == _account);
        _;
    }

    address owner;
    mapping(address => bytes32) commits;
    // mapping(address => uint256) reveals;
    address[] revealed;

    uint256 total_revealed;
    uint256 startTime;
    uint256 revealTime;
    uint256 endTime;
    uint256 period;

    // bool iscontract;
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(ERC165).interfaceId
            || interfaceID == type(ITaxpayer).interfaceId ^ type(ILottery).interfaceId;
    }

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
        //startTime current time. Users send their committed value
        startTime = block.timestamp;
        //revealTime  time for revealing. User reveal their value
        revealTime = startTime + period;
        //endTime a winner can be computed
        endTime = revealTime + period;
    }

    //A taxpayer send his own commitment.
    function commit(bytes32 y) public {
        require(block.timestamp >= startTime);
        require(block.timestamp < revealTime);
        require(block.timestamp < endTime);
        commits[msg.sender] = y;
    }

    //A valid taxpayer who sent his own commitment, sends the revealing value.
    function reveal(uint256 rev) public {
        require(block.timestamp >= revealTime);
        require(block.timestamp < endTime);
        require(doesContractImplementInterface(msg.sender, type(ITaxpayer).interfaceId));
        require(commits[msg.sender] != 0);
        require(keccak256(abi.encode(rev)) == commits[msg.sender]);
        revealed.push(msg.sender);

        unchecked {
            total_revealed += rev;
        }

        // reveals[msg.sender] = uint256(rev);
    }

    //Ends the lottery and compute the winner.
    // The owner could never end the lottery

    function endLottery() public onlyBy(owner) {
        // Block time stamp is not safe since the verifier could lie
        require(block.timestamp >= endTime);

        uint256 total = 0;
        uint256 winnerIndex = total_revealed % revealed.length;
        address winnerAddress = revealed[winnerIndex];

        // for (uint256 i = 0; i < revealed_len; i++) {
        //     total += reveals[revealed[i]];
        // }

        // Taxpayer(revealed[total % revealed.length]).setTaxAllowance();
        // Taxpayer(revealed[total % revealed.length]).setTaxAllowance();

        ITaxpayer(winnerAddress).wonLottery();
        startTime = 0;
        revealTime = 0;
        endTime = 0;
    }

    // function isContract() public view returns (bool) {
    //     return iscontract;
    // }
}
