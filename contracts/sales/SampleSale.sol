pragma solidity ^0.4.18;


import "./BaseSaleAgent.sol";
import "../interfaces/CrowdSaleInterface.sol";


contract SampleSale is BaseSaleAgent {

    function SampleSale(
        address _dougSaleAddress,
        uint256 _tokensLimit,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate
    ) {
        setParamsSaleAgent(_dougSaleAddress, _tokensLimit, _minDeposit, _maxDeposit, _startTime, _endTime, _rate);
    }

    function() payable external {
        bayToken(msg.value);
    }

    function bayToken(uint256 _value) internal {
        require(availabilityCheckPurchase());
        require(checkValue(_value));

        uint256 weiAmount = msg.value;

        CrowdSale.buyTokens.value(_value)(msg.sender, rate);
        TokenPurchase(msg.sender, _value, _value.mul(rate));
    }

}
