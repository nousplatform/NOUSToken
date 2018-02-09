pragma solidity ^0.4.18;


import "../token/ERC20.sol";


contract TokenInterface is ERC20 {
    function mint(address _to, uint256 _amount) public returns (bool);
    function setDougAddress(address _dougAddr) returns (bool result);
    function finishMinting() public returns (bool);
}
