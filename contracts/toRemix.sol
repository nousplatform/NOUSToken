pragma solidity ^0.4.4;


import "./sales/SampleSale.sol";
import "./sales/StartBonusSale.sol";
import "./sales/ReserveBaunty.sol";

import "./Token.sol";
import "./CrowdSale.sol";

import "./base/RefundVault.sol";
import "./base/BonusForAffiliate.sol";
import "./base/PaymentBounty.sol";
import "./lib/SafeMath.sol";


contract toRemix {

    using SafeMath for uint;

    function toRemix(){

    }
    function() payable {

    }

    function test(uint256 amount) constant returns(uint256){
        return amount * 1 ether;
    }

    function testdel(uint256 amount) constant returns(uint256){
        return this.balance / 1 ether;
    }

    function testdel2(uint256 amount) constant returns(uint256){
        return amount.div(1000000000000000000);
    }

    function etherr(uint256) constant returns(uint256){
        return 1 ether;
    }
}
