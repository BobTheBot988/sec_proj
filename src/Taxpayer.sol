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

    function getTaxAllowance() external view returns (uint256);

    function isContract() external view returns (bool);

    function joinLottery(address lot, uint256 r) external;
    function marry_me(Taxpayer _spouse) external;
    function revealLottery(address lot, uint256 r) external;
}

contract Taxpayer is ITaxpayer, ERC165Query {
    event AssertionFailed(string reason);
    uint256 age;

    bool isMarried;

    bool iscontract;

    /* Reference to spouse if person is married, address(0) otherwise */
    address spouse;

    address parent1;
    address parent2;

    /* Constant default income tax allowance */
    uint256 constant DEFAULT_ALLOWANCE = 5000;

    /* Constant income tax allowance for Older Taxpayers over 65 */
    uint256 constant ALLOWANCE_OAP = 7000;

    /* Income tax allowance */
    uint256 tax_allowance;

    uint256 income;

    uint256 rev;

    //Parents are taxpayers
    constructor(address p1, address p2) {
        age = 0;
        isMarried = false;
        parent1 = p1;
        parent2 = p2;
        spouse = address(0);
        income = 0;
        tax_allowance = DEFAULT_ALLOWANCE;
        iscontract = true;
    }

    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == type(ERC165).interfaceId || interfaceID == type(ITaxpayer).interfaceId;
    }

    // this function was added and is different than the original code since it lacked getters
    function get_spouse() public view returns (Taxpayer) {
        // require(this.doesContractImplementInterface(spouse, type(ITaxpayer).interfaceId));
        return Taxpayer(spouse);
    }

    function marry_me(Taxpayer _spouse) public {
        // emit AssertionFailed("Marry_me NONO");
        require(spouse == address(0));
        require(msg.sender == address(_spouse));
        require(doesContractImplementInterface(address(_spouse), type(ITaxpayer).interfaceId));

        // if (
        //     (spouse != address(0)) || (msg.sender != _spouse)
        //         || (!this.doesContractImplementInterface(_spouse, type(ITaxpayer).interfaceId))
        // ) return;
        spouse = address(_spouse);
    }

    //We require new_spouse != address(0);
    function marry(address new_spouse) public {
        // emit AssertionFailed("Marry nono");
        require(doesContractImplementInterface(new_spouse, type(ITaxpayer).interfaceId));
        require(spouse == address(0));
        require(new_spouse != address(0));

        spouse = new_spouse;
        // isMarried = true;
        Taxpayer(new_spouse).marry_me(this);
        assert(address(this) == address(Taxpayer(new_spouse).get_spouse()));
    }

    function divorce_me() public {
        require(spouse != address(0));
        require(msg.sender == spouse);
        require(address(Taxpayer(spouse).get_spouse()) == address(0));
        spouse = address(0);
    }

    function divorce() public {
        require(spouse != address(0));
        address tmp = spouse;
        spouse = address(0);
        Taxpayer(tmp).divorce_me();
        // isMarried = false;
    }

    /* Transfer part of tax allowance to own spouse */
    function transferAllowance(uint256 change) public {
        tax_allowance = tax_allowance - change;
        Taxpayer sp = Taxpayer(address(spouse));
        sp.setTaxAllowance(sp.getTaxAllowance() + change);
    }

    function haveBirthday() public {
        age++;
    }

    function setTaxAllowance(uint256 ta) public {
        require(Taxpayer(msg.sender).isContract() || Lottery(msg.sender).isContract());
        tax_allowance = ta;
    }

    function getTaxAllowance() public view returns (uint256) {
        return tax_allowance;
    }

    function isContract() public view returns (bool) {
        return iscontract;
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
