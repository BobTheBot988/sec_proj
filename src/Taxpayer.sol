pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./Lottery.sol";
import "./State.sol";

contract Taxpayer {
    int256 immutable secondsFromUnix;
    uint8 constant oldAge = 65;
    bool isMarried;

    bool iscontract;
    address immutable state;
    address lottery = address(0);
    /* Reference to spouse if person is married, address(0) otherwise */
    address spouse;

    address immutable parent1;
    address immutable parent2;

    /* Constant default income tax allowance */
    uint256 constant DEFAULT_ALLOWANCE = 5000;

    /* Constant income tax allowance for Older Taxpayers over 65 */
    uint256 constant ALLOWANCE_OAP = 7000;

    /* Income tax allowance */
    uint256 tax_allowance;
    uint256 pool_tax_allowance;

    uint256 income;
    bool counter = false;
    uint256 rev;
    bool lock;
    uint256 lottery_wins = 0;
    int256 constant GREGORIAN_YEAR = 31556952; // 365.2425 Days
    // uint256 constant ASTRONOMICAL_YEAR = 31556926; // ~365.24219 Days

    function getYearsSinceBirth() public view returns (uint256) {
        int256 currentTime = int256(block.timestamp);
        int256 yrs = ((currentTime - secondsFromUnix) / GREGORIAN_YEAR);
        if (yrs < 0) {
            yrs = -yrs;
        }

        return uint256(yrs);
    }

    function getLotteryWins() public view returns (uint256) {
        return lottery_wins;
    }

    function getLottery() public view returns (Lottery) {
        require(lottery != address(0));
        return Lottery(lottery);
    }

    modifier nonReentrant() {
        require(!lock);
        lock = true;
        _;
        lock = false;
    }

    //Parents are taxpayers
    constructor(address p1, address p2, int256 _secondsFromUnix) {
        parent1 = p1;
        parent2 = p2;
        secondsFromUnix = _secondsFromUnix;
        state = msg.sender;
        tax_allowance = DEFAULT_ALLOWANCE;
        pool_tax_allowance = DEFAULT_ALLOWANCE;
    }

    // this function was added and is different than the original code since it lacked getters
    function get_spouse() public view returns (Taxpayer) {
        // require(this.doesContractImplementInterface(spouse, type(ITaxpayer).interfaceId));
        return Taxpayer(spouse);
    }

    function get_counter() public view returns (bool) {
        return counter;
    }

    function marry_me(Taxpayer _spouse) public nonReentrant {
        // emit AssertionFailed("Marry_me NONO");
        require(spouse == address(0));
        require(msg.sender == address(_spouse));
        require(address(_spouse) != address(this));
        require(State(state).isTaxpayerValid(address(_spouse)));
        spouse = address(_spouse);
    }

    //We require new_spouse != address(0);
    function marry(address new_spouse) public nonReentrant {
        require(State(state).isTaxpayerValid(address(new_spouse)));
        require(spouse == address(0));
        require(new_spouse != address(0));
        require(address(new_spouse) != address(this));

        Taxpayer(new_spouse).marry_me(Taxpayer(address(this)));

        assert(address(this) == address(Taxpayer(new_spouse).get_spouse()));

        spouse = new_spouse;
        pool_tax_allowance = tax_allowance + Taxpayer(new_spouse).getTaxAllowance();
        Taxpayer(new_spouse).setPoolAllowance();

        assert(Taxpayer(spouse).getPoolAllowance() == pool_tax_allowance);
    }

    function divorce_me() public {
        require(spouse != address(0));
        require(msg.sender == spouse);
        require(address(Taxpayer(spouse).get_spouse()) == address(0));
        spouse = address(0);
    }

    function divorce() public {
        require(spouse != address(0));
        address prevSpouse = spouse;
        spouse = address(0);
        Taxpayer(prevSpouse).divorce_me();
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        require(spouse != address(0));
        Taxpayer sp = Taxpayer(address(spouse));
        uint256 sp_tax_allowance = sp.getTaxAllowance();

        require(sp_tax_allowance + tax_allowance == (pool_tax_allowance));

        tax_allowance -= change;
        sp.setTaxAllowance(sp_tax_allowance + change);

        assert(sp.getTaxAllowance() + tax_allowance == (pool_tax_allowance));
    }

    function getPoolAllowance() public view returns (uint256) {
        return pool_tax_allowance;
    }

    function setPoolAllowance() public {
        require(spouse != address(0));
        require(msg.sender == spouse);

        pool_tax_allowance = tax_allowance + Taxpayer(spouse).getTaxAllowance();
    }

    function wonLottery() public {
        require(lottery != address(0));
        require(lottery == msg.sender);
        lottery_wins += 1;
        tax_allowance += 2000;
        pool_tax_allowance += 2000;
        if (spouse != address(0)) {
            Taxpayer(spouse).setPoolAllowance();
        }
    }

    function raiseOwnAllowance() public {
        require(getYearsSinceBirth() >= oldAge);
        require(counter == false);
        counter = true;
        tax_allowance += 2000;
        pool_tax_allowance += 2000;
        if (spouse != address(0)) {
            Taxpayer(spouse).setPoolAllowance();
        }
    }

    // function getAge() public view returns (uint256) {
    //     return age;
    // }

    function setTaxAllowance(uint256 ta) public {
        require(State(state).isTaxpayerValid(msg.sender));
        require(spouse != address(0));
        require(msg.sender == spouse);

        tax_allowance = ta;

        assert(Taxpayer(spouse).getTaxAllowance() + ta == (pool_tax_allowance));
    }

    function getTaxAllowance() public view returns (uint256) {
        return tax_allowance;
    }

    function joinLottery() public {
        require(State(state).isTaxpayerValid(address(this)));
        Lottery l = State(state).getLottery();
        lottery = address(l);
        l.commit();
    }

    // function revealLottery() public {
    //     Lottery(lottery).reveal();
    // }
}
