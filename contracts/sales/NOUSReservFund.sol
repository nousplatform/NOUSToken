pragma solidity ^0.4.11;


import "./SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NousplatformCrowdSale.sol";


contract NOUSReservFund is SalesAgent {

    using SafeMath for uint;

    function NOUSReservFund(address _saleContractAddress) {
        nousTokenSale = NousplatformCrowdSale(_saleContractAddress);
    }

    function globalFinalizationStartBonusPayable() onlyOwner {
        nousTokenSale.finalizeICO();
        FinaliseICO(this, msg.sender);
    }

    /**
    * @dev bonus payout
    */
    function payoutBonuses() onlyOwner {
        nousTokenSale.payDelayBonuses();
    }

    /**
    * @dev if they ICO did not reach the goal
    */
    /*function claimRefund() public {
        uint256 _value = nousTokenSale.claimRefund(msg.sender);
        Refund(this, msg.sender, _value);
    }*/


}
