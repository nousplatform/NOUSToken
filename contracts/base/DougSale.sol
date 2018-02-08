pragma solidity ^0.4.18;

contract DougSale {

    address public dougSale; // address Nous Sale contract

    modifier onlySaleAgent() {
        require(msg.sender == dougSale);
        _;
    }

    function setDougAddress(address _dougAddr) public returns(bool) {
        if(dougSale != 0x0 && msg.sender != dougSale) {
            return false;
        }
        dougSale = _dougAddr;
        return true;
    }
}
