pragma solidity ^0.4.11;


import './ERC20Basic.sol';
import '../lib/SafeMath.sol';


/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
	using SafeMath for uint256;

	mapping(address => uint256) balances;

	bool public endICO = false;

	event TransferStart();

	modifier canTransfer(){
		require(endICO);
		_;
	}

	/**
	* @dev transfer token for a specified address
	* @param _to The address to transfer to.
	* @param _value The amount to be transferred.
	*/
	function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
		require(_to != address(0));

		// SafeMath.sub will throw if there is not enough balance.
		balances[msg.sender] = balances[msg.sender].sub(_value);
		balances[_to] = balances[_to].add(_value);
		Transfer(msg.sender, _to, _value);
		return true;
	}

	/**
	* @dev Gets the balance of the specified address.
	* @param _owner The address to query the the balance of.
	* @return An uint256 representing the amount owned by the passed address.
	*/
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	function finishICO() public returns (bool) {
		endICO = true;
		TransferStart();
		return true;
	}

}
