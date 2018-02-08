pragma solidity ^0.4.18;


contract PaymentBountyInterface {

    function setPaymentBounty(
        address _walletAddress,
        bytes32 _name,
        uint256 _percent,
        uint256 _delay,
        uint256 _periodPathOfPay
    ) public;

    function reserveBonuses(uint256 _totalSupply) public returns (uint256);

    function payDelayBonuses(uint256 _startTime) public;

    function setDougAddress(address _dougAddr) returns (bool result);

}
