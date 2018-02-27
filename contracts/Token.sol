pragma solidity ^0.4.18;


import "./token/MintableToken.sol";
import "./token/TokenRecipient.sol";


/**
 * @title SampleCrowdsaleToken
 * @dev Very simple ERC20 Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract Token is MintableToken {

    string public constant name = "NOUSTOKEN";

    string public constant symbol = "NST";

    uint32 public constant decimals = 18;

    /**
  * Set allowance for other address and notify
  *
  * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
  *
  * @param _spender The address authorized to spend
  * @param _value the max amount they can spend
  * @param _extraData some extra information to send to the approved contract
  */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }
}
