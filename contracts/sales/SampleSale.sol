pragma solidity ^0.4.11;


import "./BaseSaleAgent.sol";
import "../interface/CrowdSaleInterface.sol";


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
        bayToken();
    }

    function bayToken() payable external {
        require(availabilityCheckPurchase());
        require(checkValue(msg.value));

        uint256 weiAmount = msg.value;

        CrowdSaleInterface(dougSaleAddress).buyTokens.value(msg.value)(msg.sender, rate);
        TokenPurchase(msg.sender, msg.value, tokens);
    }

}
