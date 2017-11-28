pragma solidity ^0.4.11;


import "./SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NousplatformCrowdSale.sol";

import "./NOUSCrowdsale.sol";
import "./NOUSReservFund.sol";
import "./NOUSPreorder.sol";


contract NOUSPresale is SalesAgent {

    using SafeMath for uint;

    function NOUSPresale(address _saleContractAddress) {
        nousTokenSale = NousplatformCrowdSale(_saleContractAddress);
    }

    function() payable external {
        require(msg.value > 0);
        require(nousTokenSale.validateStateSaleContract(this));

        uint256 weiAmount = msg.value;
        uint256 rate = nousTokenSale.getSaleContractTokensRate(this);
        assert(rate != 0);
        // calculate tokens - get bonus rate
        uint256 tokens = weiAmount.mul(rate);
        bool success = nousTokenSale.buyTokens.value(msg.value)(msg.sender, tokens);

        if (!success) {
            msg.sender.transfer(msg.value);
            // return back if not
            TokenValidateRefund(this, msg.sender, msg.value);
        } else {
            TokenPurchase(this, msg.sender, msg.value, tokens);
        }
    }

}
