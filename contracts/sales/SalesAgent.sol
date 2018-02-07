pragma solidity ^0.4.11;

import "../NousplatformCrowdSale.sol";
import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "";


contract SalesAgent is Ownable {



    event FinaliseSale(uint256 tokensMinted, uint256 weiAmount);

    /**
	* event for token purchase logging
	* @param beneficiary who got the tokens
	* @param value weis paid for purchase
	* @param amount amount of tokens purchased
	*/


    // refund token if not valid;
    event TokenValidateRefund(address _agent, address indexed beneficiary, uint256 value);

    event Contribute(address _agent, address _sender, uint256 _value);





    event Refund(address _agent, address _sender, uint256 _value);

    event TransferToDepositAddress(address _agent, address _sender, uint256 _value);

    event ReserveBonuses(address _agent, address _sender, uint256 _totalReserve);





}