pragma solidity ^0.4.18;


import "./Crowdsale.sol";
import "./Bounty.sol";


contract AirdropTokens is Crowdsale, Bounty {

    constructor() Crowdsale {

    }

    // Deliver
    // @param _salesAgent addresses sale agent
    // @param _batchOfAddresses list of addresses
    // @param _amountOf matching list of address balances
    function deliverTokens(address[] _batchOfAddresses, uint256[] _amountOf) external onlyOwner {
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_batchOfAddresses[i], _amountOf[i]);
        }
    }

    // @param _accountHolder user address
    // @param _amountOf balance to send out
    function deliverTokenToClient(address _accountHolder, uint256 _amountOf) public onlyOwner {
        require(_amountOf > 0);
        require(_accountHolder != 0x0);
        require(tokensAvailableSale >= token.totalSupply().add(_tokenAmount));
        uint256 _tokens = _amountOf.mul(EXPONENT);

        _processPurchase(_accountHolder, _tokens);
    }
}
