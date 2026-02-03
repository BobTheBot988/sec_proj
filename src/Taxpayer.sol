pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./Lottery.sol";
import "./State.sol";

contract Taxpayer {
    event AssertionFailed(string reason);
    int256 immutable secondsFromUnix;
    uint256 constant oldAge = 65;
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
    modifier nonReentrant() {
        require(!lock);
        lock = true;
        _;
        lock = false;
    }

    //Parents are taxpayers
    constructor(address p1, address p2, int256 _secondsFromUnix) {
        state = msg.sender;
        // age = 0;
        secondsFromUnix = _secondsFromUnix;
        // isMarried = false;
        parent1 = p1;
        parent2 = p2;
        spouse = address(0);
        income = 0;
        tax_allowance = DEFAULT_ALLOWANCE;
        pool_tax_allowance = DEFAULT_ALLOWANCE;
        // Useless if we implement the ERC165 iscontract = true;
    }

    // this function was added and is different than the original code since it lacked getters
    function get_spouse() public view returns (Taxpayer) {
        // require(this.doesContractImplementInterface(spouse, type(ITaxpayer).interfaceId));
        require(spouse != address(0));
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

        // if (
        //     (spouse != address(0)) || (msg.sender != _spouse)
        //         || (!this.doesContractImplementInterface(_spouse, type(ITaxpayer).interfaceId))
        // ) return;
        //
        spouse = address(_spouse);
        // pool_tax_allowance = (pool_tax_allowance + Taxpayer(spouse).getTaxAllowance()) % 10001;
        Taxpayer(spouse).setPoolAllowance();
    }

    //We require new_spouse != address(0);
    function marry(address new_spouse) public nonReentrant {
        require(State(state).isTaxpayerValid(address(new_spouse)));
        require(spouse == address(0));
        require(new_spouse != address(0));
        require(address(new_spouse) != address(this));

        spouse = new_spouse;
        // pool_tax_allowance = (pool_tax_allowance + Taxpayer(spouse).getTaxAllowance()) % 10001;
        // isMarried = true;
        Taxpayer(new_spouse).marry_me(this);
        Taxpayer(spouse).setPoolAllowance();
        // assert(address(this) == address(Taxpayer(new_spouse).get_spouse()));
        if (address(this) != address(Taxpayer(new_spouse).get_spouse())) {
            emit AssertionFailed("Post condition violated: You did not marry your spouse");
        }
        if (Taxpayer(spouse).getPoolAllowance() != pool_tax_allowance) {
            emit AssertionFailed("The pool tax allowance must be the same in both spouses");
        }
    }

    function divorce_me() public {
        require(spouse != address(0));
        require(msg.sender == spouse);
        require(address(Taxpayer(spouse).get_spouse()) == address(0));
        spouse = address(0);

        if (getYearsSinceBirth() >= oldAge && counter) {
            tax_allowance = ALLOWANCE_OAP;
            pool_tax_allowance = ALLOWANCE_OAP;
        } else {
            tax_allowance = DEFAULT_ALLOWANCE;
            pool_tax_allowance = DEFAULT_ALLOWANCE;
        }
        tax_allowance += (2000 * lottery_wins);
        pool_tax_allowance += (2000 * lottery_wins);
    }

    function divorce() public {
        require(spouse != address(0));
        address tmp = spouse;
        spouse = address(0);

        if (getYearsSinceBirth() >= oldAge && counter) {
            tax_allowance = ALLOWANCE_OAP;
            pool_tax_allowance = ALLOWANCE_OAP;
        } else {
            tax_allowance = DEFAULT_ALLOWANCE;
            pool_tax_allowance = DEFAULT_ALLOWANCE;
        }

        tax_allowance += (2000 * lottery_wins);
        Taxpayer(tmp).divorce_me();
        // isMarried = false;
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        require(spouse != address(0));
        Taxpayer sp = Taxpayer(address(spouse));
        uint256 sp_tax_allowance = sp.getTaxAllowance();

        require(sp_tax_allowance + tax_allowance == (pool_tax_allowance));

        tax_allowance = tax_allowance - change;
        sp_tax_allowance = sp.getTaxAllowance();
        sp.setTaxAllowance(sp_tax_allowance + change);
        // we need to make the DEFAULT_ALLOWANCE dynamic
        if (sp.getTaxAllowance() + tax_allowance != (pool_tax_allowance)) {
            emit AssertionFailed("You tried to cheat the system, PREPARE TO DIE!!!");
        }
    }

    function getPoolAllowance() public view returns (uint256) {
        return pool_tax_allowance;
    }

    function setPoolAllowance() public {
        require(spouse != address(0));
        require(msg.sender == spouse);

        uint256 _pool_tax_allowance = 10000;

        _pool_tax_allowance += (2000 * lottery_wins);
        if (getYearsSinceBirth() >= oldAge && counter) {
            _pool_tax_allowance += 2000;
        }

        _pool_tax_allowance += (2000 * Taxpayer(spouse).getLotteryWins());
        if (Taxpayer(spouse).getYearsSinceBirth() >= oldAge && Taxpayer(spouse).get_counter()) {
            _pool_tax_allowance += 2000;
        }
        pool_tax_allowance = (_pool_tax_allowance);
    }

    function wonLottery() public {
        require(lottery != address(0));
        require(lottery == msg.sender);

        lottery_wins += 1;
        tax_allowance += 2000;
        pool_tax_allowance += 2000;
        lottery = address(0);
        if (spouse != address(0)) {
            Taxpayer(spouse).setPoolAllowance();
            if (Taxpayer(spouse).getPoolAllowance() != pool_tax_allowance) {
                emit AssertionFailed("The spouse has a diffent pool_tax_allowance");
            }
        }
    }

    function raiseOwnAllowance() public {
        require(getYearsSinceBirth() >= oldAge);
        require(counter == false);
        counter = true;

        tax_allowance += 2000;
        pool_tax_allowance = (pool_tax_allowance + 2000);

        if (spouse != address(0)) {
            Taxpayer(spouse).setPoolAllowance();
            if (Taxpayer(spouse).getPoolAllowance() != pool_tax_allowance) {
                emit AssertionFailed("The poll allowances do not match");
            }
        }
        // else {
        //     pool_tax_allowance = pool_tax_allowance % (tax_allowance + 1);
        // }
    }

    // function getAge() public view returns (uint256) {
    //     return age;
    // }

    function setTaxAllowance(uint256 ta) public {
        require(State(state).isTaxpayerValid(msg.sender));
        require(spouse != address(0));
        require(msg.sender == spouse);

        tax_allowance = ta;
        if (Taxpayer(spouse).getTaxAllowance() + ta != (pool_tax_allowance)) {
            emit AssertionFailed("You and your wife tried to cheat");
        }
    }

    function getTaxAllowance() public view returns (uint256) {
        return tax_allowance;
    }

    function joinLottery() public {
        Lottery Lot = State(state).getLottery();
        lottery = address(Lot);

        // emit AssertionFailed("joined");
        Lottery(Lot).commit();
        // emit AssertionFailed("joined");
    }

    // function revealLottery() public {
    //     Lottery(lottery).reveal();
    // }
}
