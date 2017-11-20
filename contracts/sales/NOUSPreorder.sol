pragma solidity ^0.4.11;


import "./SalesAgentProvider.sol";
import "../lib/SafeMath.sol";
import "../NOUSSale.sol";


contract NOUSPreorder is SalesAgentProvider {

    using SafeMath for uint;

    uint256 gasPrice;

    function NOUSPreorder(address _saleContractAddress, address _saleAgent) {
        nousTokenSale = NOUSSale(_saleContractAddress);
        saleAgentDb = SaleAgent(_saleAgent);
    }

    function() payable external {
        // The target ether amount
        gasPrice = tx.gasprice;
        require(nousTokenSale.validGasPrice(tx.gasprice));
        require(nousTokenSale.validateStateSaleContract(this));
        require(nousTokenSale.validateContribution(msg.value));
        require(msg.sender != 0x0);

        uint256 weiAmount = msg.value;

        uint256 rate = saleAgentDb.getSaleContractTokensRate(this);
        // calculate tokens - get bonus rate
        uint256 tokens = weiAmount.mul(rate);

        require(nousTokenSale.validPurchase(this, tokens));
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
