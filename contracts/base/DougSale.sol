pragma solidity ^0.4.0;

contract DougSale {

    address public dugSale; // address Nous Sale contract

    modifier onlySaleAgent() {
        require(msg.sender == dugSale);
        _;
    }

    function setDugSale(address _dugSale) public onlyOwner {
        require(_dugSale != 0x0);
        dugSale = _dugSale;
    }
}
