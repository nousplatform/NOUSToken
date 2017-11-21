pragma solidity ^0.4.11;


import "./SalesAgent.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";

import "./NOUSCrowdsale.sol";
import "./NOUSReservFund.sol";
import "./NOUSPreorder.sol";


contract NOUSPresale is SalesAgent {

    using SafeMath for uint;

    uint256 gasPrice;

    function NOUSPresale(address _saleContractAddress) {
        nousTokenSale = NOUSSale(_saleContractAddress);
    }

    function() payable external {
        // The target ether amount
        gasPrice = tx.gasprice;
        require(nousTokenSale.validGasPrice(tx.gasprice));
        require(validateStateSaleContract(this));

        require(validateContribution(msg.value));

        require(msg.sender != 0x0);

        uint256 weiAmount = msg.value;

        uint256 rate = nousTokenSale.getSaleContractTokensRate(this);
        // calculate tokens - get bonus rate
        uint256 tokens = weiAmount.mul(rate);

        require(validPurchase(this, tokens));
        // require tokens

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
