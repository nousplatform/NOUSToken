pragma solidity ^0.4.18;


import "./Crowdsale.sol";
import "./Bounty.sol";
import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/ERC20.sol";


contract AirdropTokens is Crowdsale, Bounty {

    /**
    * @notice Mass transfer
    * @param _batchOfAddresses list of addresses
    * @param _amountOf matching list of address balances
    */
    function deliverTokens(address[] _batchOfAddresses, uint256[] _amountOf) external onlyOwner {
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_batchOfAddresses[i], _amountOf[i]);
        }
    }

    /**
    * @notice Delivery tokens to client
    * @param _accountHolder user address
    * @param _amountOf balance to send out
    */
    function deliverTokenToClient(address _accountHolder, uint256 _amountOf) public onlyOwner {
        require(_amountOf > 0);
        require(_accountHolder != 0x0);

        uint256 _tokens = _amountOf.mul(EXPONENT);
        require(tokensAvailableSale >= token.totalSupply().add(_tokens));

        _processPurchase(_accountHolder, _tokens);
    }
}
