pragma solidity ^0.4.11;

import "../NOUSSale.sol";
import "../base/Ownable.sol";

contract SalesAgent is Ownable{

    //address saleContractAddress;
    // Main contract token address
	
    NOUSSale nousTokenSale; // contract nous sale

    /**
	* event for token purchase logging
	* @param beneficiary who got the tokens
	* @param value weis paid for purchase
	* @param amount amount of tokens purchased
	*/
	event TokenPurchase(address _agent, address indexed beneficiary, uint256 value, uint256 amount);

	// refund token if not valid;
	event TokenValidateRefund(address _agent, address indexed beneficiary, uint256 value);


    event Contribute(address _agent, address _sender, uint256 _value);
    event FinaliseSale(address _agent, address _sender, uint256 _value);
    event FinaliseICO(address _agent, address _sender);
    event Refund(address _agent, address _sender, uint256 _value);

    event TransferToDepositAddress(address _agent, address _sender, uint256 _value);
    event ReserveBonuses(address _agent, address _sender, uint256 _totalReserve);

	function finaliseFunding() onlyOwner {

		// Do some common contribution validation, will throw if an error occurs - address calling this should match the deposit address
		if (nousTokenSale.finalizeSaleContract(this)) {
			uint256 tokenMinted = nousTokenSale.getSaleContractTokensMinted(this);
			FinaliseSale(this, msg.sender, tokenMinted);
		}
	}

	/*function setSaleAddress(address _saleContractAddress) onlyOwner {
		nousTokenSale = NOUSSale(_saleContractAddress);
	}*/


}