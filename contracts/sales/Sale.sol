pragma solidity ^0.4.18;


import "./BaseSaleAgent.sol";
import "../interfaces/CrowdSaleInterface.sol";

//"0x7204b06b4c344bd969457462f4d9e933650049c0"10000,1,3,1518190980,1518196200,7400

contract Sale is BaseSaleAgent {

    function Sale(
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

    function bayToken() payable {
        require(availabilityCheckPurchase());
        require(checkValue(msg.value));
        CrowdSale.buyTokens.value(msg.value)(msg.sender, rate);
        TokenPurchase(msg.sender, msg.value, msg.value.mul(rate));
    }

}
