pragma solidity ^0.4.0;


contract RefundVaultInterface {

    function deposit(address investor) public payable;

    function refund(address investor) public returns (uint256);

    function close() public;

    function withdraw(uint256 _amount) public;

    function enableRefunds() public;

}
