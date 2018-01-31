pragma solidity ^0.4.11;


import "./token/MintableToken.sol";


/**
 * @title Contract Nous token
 * @dev Very simple ERC20 Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract NOUSToken is MintableToken {

    string public constant name = "NOUSTOKEN";

    string public constant symbol = "NST";

    uint32 public constant decimals = 18;

}
