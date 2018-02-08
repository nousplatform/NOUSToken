pragma solidity ^0.4.18;


import "./BaseSaleAgent.sol";
import "../CrowdSale.sol";


contract ReserveBaunty is BaseSaleAgent {

    event FinaliseICO();

    function ReserveBaunty(
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

    function globalFinalizationStartBonusPayable() onlyOwner {
        CrowdSale.finalizeICO();
        FinaliseICO();
    }

    /**
    * @dev bonus payout
    */
    function payoutBonuses() onlyOwner {
        CrowdSale.payDelayBonuses(startTime);
    }

    /**
    * @dev if they ICO did not reach the goal
    */
    /*function claimRefund() public {
        uint256 _value = nousTokenSale.claimRefund(msg.sender);
        Refund(this, msg.sender, _value);
    }*/

}
