pragma solidity ^0.4.18;


import "./token/MintableToken.sol";


/**
 * @title SampleCrowdsaleToken
 * @dev Very simple ERC20 Token that can be minted.
 * It is meant to be used in a crowdsale contract.
 */
contract Token is MintableToken {

    string public constant name = "NOUSTOKEN";

    string public constant symbol = "NST";

    uint32 public constant decimals = 18;

}
