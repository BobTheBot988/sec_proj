pragma solidity ^0.8.22;
// SPDX-License-Identifier: UNLICENSED

import "./Lottery.sol";
import "./ERC165.sol";

interface ITaxpayer is ERC165 {
    // this function was added and is different than the original code since it lacked getters
    function get_spouse() external view returns (Taxpayer);

    //We require new_spouse != address(0);
    function marry(address new_spouse) external;

    function divorce() external;

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) external;

    function haveBirthday() external;

    function setTaxAllowance(uint256 ta) external;

    function getPoolAllowance() external view returns (uint256);
    function setPoolAllowance() external;
    function getTaxAllowance() external view returns (uint256);
    function getAge() external view returns (uint256);
    // function isContract() external view returns (bool);
    function joinLottery(address lot, uint256 r) external;
    function marry_me(Taxpayer _spouse) external;
    function revealLottery(address lot, uint256 r) external;
}

contract Taxpayer is ITaxpayer, ERC165Query {
    event AssertionFailed(string reason);
    uint256 age;
    uint256 constant oldAge = 1;
    bool isMarried;

    bool iscontract;

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

    uint256 rev;
    bool lock;

    modifier nonReentrant() {
        require(!lock);
        lock = true;
        _;
        lock = false;
    }

    //Parents are taxpayers
    constructor(address p1, address p2) {
        age = 0;
        isMarried = false;
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
        // emit AssertionFailed("Marry nono");
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
            emit AssertionFailed("MERDA ECHIDNA");
        }
    }

    function divorce_me() public {
        require(spouse != address(0));
        require(msg.sender == spouse);
        require(address(Taxpayer(spouse).get_spouse()) == address(0));
        spouse = address(0);
        if (age >= oldAge) {
            tax_allowance = ALLOWANCE_OAP;
            pool_tax_allowance = ALLOWANCE_OAP;
        } else {
            tax_allowance = DEFAULT_ALLOWANCE;
            pool_tax_allowance = DEFAULT_ALLOWANCE;
        }
    }

    function divorce() public {
        require(spouse != address(0));
        address tmp = spouse;
        spouse = address(0);

        if (age >= oldAge) {
            tax_allowance = ALLOWANCE_OAP;
            pool_tax_allowance = ALLOWANCE_OAP;
        } else {
            tax_allowance = DEFAULT_ALLOWANCE;
            pool_tax_allowance = DEFAULT_ALLOWANCE;
        }
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

        if (age >= oldAge) {
            _pool_tax_allowance += 2000;
        }
        if (Taxpayer(spouse).getAge() >= oldAge) {
            _pool_tax_allowance += 2000;
        }

        pool_tax_allowance = (_pool_tax_allowance);
    }

    function haveBirthday() public {
        age++;
        if (age == oldAge) {
            tax_allowance = ALLOWANCE_OAP;
            pool_tax_allowance = (pool_tax_allowance + 2000);
            if (spouse != address(0)) {
                Taxpayer(spouse).setPoolAllowance();
                assert(Taxpayer(spouse).getPoolAllowance() == pool_tax_allowance);
            } else {
                pool_tax_allowance = pool_tax_allowance % 7001;
            }
        }
    }

    function getAge() public view returns (uint256) {
        return age;
    }

    function setTaxAllowance(uint256 ta) public {
        require(doesContractImplementInterface(msg.sender, type(ITaxpayer).interfaceId));
        require(spouse != address(0));
        require(msg.sender == spouse);
        // This assures me that my spouse actually called the function
        // We should think about the lottery require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
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
        l.commit(keccak256(abi.encode(r)));
        rev = r;
    }

    function revealLottery(address lot, uint256 r) public {
        Lottery l = Lottery(lot);
        l.reveal(r);
        rev = 0;
    }
}
