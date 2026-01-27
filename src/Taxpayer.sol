pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import "./Lottery.sol";
import "./ERC165.sol";

interface ITaxpayer is ERC165 {
    // this function was added and is different than the original code since it lacked getters
    function get_spouse() external view returns (Taxpayer);
    function wonLottery() external;
    //We require new_spouse != address(0);
    function marry(address new_spouse) external;

    function divorce() external;
    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) external;

    function raiseOwnAllowance() external;

    function setTaxAllowance(uint256 ta) external;
    function get_counter() external view returns (bool);
    function getPoolAllowance() external view returns (uint256);
    function setPoolAllowance() external;
    function getTaxAllowance() external view returns (uint256);

    // function getAge() external view returns (uint256);
    // function isContract() external view returns (bool);
    //
    function joinLottery(address lot, uint256 r) external;
    function marry_me(Taxpayer _spouse) external;
    function revealLottery(address lot, uint256 r) external;
    function getYearsSinceBirth() external view returns (uint256);

    function getLotteryWins() external view returns (uint256);
}

contract Taxpayer is ITaxpayer, ERC165Query {
    event AssertionFailed(string reason);
    int256 immutable secondsFromUnix;
    uint256 constant oldAge = 1;
    bool isMarried;

    bool iscontract;

    mapping(address => Lottery) lottery;
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

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(ERC165).interfaceId || interfaceID == type(ITaxpayer).interfaceId;
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
        require(doesContractImplementInterface(address(_spouse), type(ITaxpayer).interfaceId));

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
        require(doesContractImplementInterface(new_spouse, type(ITaxpayer).interfaceId));
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
        require(address(lottery[msg.sender]) != address(0));

        lottery_wins += 1;
        tax_allowance += 2000;
        pool_tax_allowance += 2000;
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
            assert(Taxpayer(spouse).getPoolAllowance() == pool_tax_allowance);
        }
        // else {
        //     pool_tax_allowance = pool_tax_allowance % (tax_allowance + 1);
        // }
    }

    // function getAge() public view returns (uint256) {
    //     return age;
    // }

    function setTaxAllowance(uint256 ta) public {
        require(doesContractImplementInterface(msg.sender, type(ITaxpayer).interfaceId));
        require(spouse != address(0));
        require(msg.sender == spouse);

        // This assures me that my spouse actually called the function
        // We should think about the lottery require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
        //

        tax_allowance = ta;
        if (Taxpayer(spouse).getTaxAllowance() + ta != (pool_tax_allowance)) {
            emit AssertionFailed("You and your wife tried to cheat");
        }
    }

    function getTaxAllowance() public view returns (uint256) {
        return tax_allowance;
    }

    function joinLottery(address lot, uint256 r) public {
        Lottery l = Lottery(lot);
        rev = r;
        l.commit(keccak256(abi.encode(r)));
        // the attribute is unsecure since it can be read from everyone
        // the owner can exploit this feature to win himself every single time
    }

    function revealLottery(address lot, uint256 r) public {
        Lottery l = Lottery(lot);
        rev = 0;
        l.reveal(r);
    }
}
