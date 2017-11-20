pragma solidity ^0.4.11;


import "./SalesAgentProvider.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";
import "../base/SaleAgent.sol";


contract NOUSReservFund is SalesAgentProvider {

    using SafeMath for uint;

    function NOUSReservFund(address _saleContractAddress, address _saleAgent) {
        nousTokenSale = NOUSSale(_saleContractAddress);
        saleAgentDb = SaleAgent(_saleAgent);
    }

    function globalFinalizationStartBonusPayable() onlyOwner {
        nousTokenSale.finalizeICO(this);
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
    function claimRefund() public {
        uint256 _value = nousTokenSale.claimRefund(msg.sender);
        Refund(this, msg.sender, _value);
    }


}
