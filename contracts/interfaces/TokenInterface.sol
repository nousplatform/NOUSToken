pragma solidity ^0.4.11;


import "../token/ERC20.sol";


contract TokenInterface is ERC20 {

    function transferOwnership(address newOwner) public;

    function mint(address _to, uint256 _amount) public returns (bool);

    function finishMinting() public returns (bool);

    function transfer(address to, uint256 value) public returns (bool);

    function setDougAddress(address _dougAddr) returns (bool result);

}
