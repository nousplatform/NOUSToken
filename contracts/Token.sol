pragma solidity ^0.4.18;


import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/MintableToken.sol";
import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/PausableToken.sol";


contract TokenRecipient {
    function receiveApproval(address _from, uint _value) public;
}

interface TokenInterface {
    function mint(address _to, uint256 _amount) public returns (bool);
    function finishMinting() public returns (bool);
}


/**
 * @title SampleCrowdsaleToken
 * @dev Very simple ERC20 Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract Token is MintableToken, PausableToken {

    string public constant name = "Nousplatform";

    string public constant symbol = "NSU";

    uint32 public constant decimals = 18;

    /**
      * Set allowance for other address and notify
      *
      * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
      *
      * @param _spender The address authorized to spend
      * @param _value the max amount they can spend in EXPONENTS
      */
    function approveAndCall(address _spender, uint256 _value) public returns (bool) {
        TokenRecipient spender = TokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value);
            return true;
        }
    }
}
