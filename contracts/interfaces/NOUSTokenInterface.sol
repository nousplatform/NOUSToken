pragma solidity ^0.4.0;


contract NOUSTokenInterface {

    uint256 public totalSupply;

    function transferOwnership(address newOwner) public;

    function mint(address _to, uint256 _amount) public returns (bool);

    function finishMinting() public returns (bool);

    function transfer(address to, uint256 value) public returns (bool);

    function setDougAddress(address _dougAddr) returns (bool result);

}
