pragma solidity ^0.4.18;


import "./Crowdsale.sol";
import "./Bounty.sol";


contract AirdropTokens is Crowdsale, Bounty {

    // Deliver
    // @dev Function to send NOUS to presale investors
    // Can only be called while the presale is not over.
    // @param _salesAgent addresses sale agent
    // @param _batchOfAddresses list of addresses
    // @param _amountOf matching list of address balances
    function deliverPresaleTokens(address[] _batchOfAddresses, uint256[] _amountOf) external onlyOwner {
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_batchOfAddresses[i], _amountOf[i]);
        }
    }

    // @dev Logic to transfer presale tokens
    // Can only be called while the there are leftover presale tokens to allocate. Any multiple contribution from
    // the same address will be aggregated.
    // @param _accountHolder user address
    // @param _amountOf balance to send out
    function deliverTokenToClient(address _accountHolder, uint256 _amountOf) public onlyOwner {
        require(_accountHolder != 0x0);
        uint256 _tokens = _amountOf.mul(EXPONENT);

        _processPurchase(_accountHolder, _tokens);
    }
}
