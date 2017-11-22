pragma solidity ^0.4.11;

import "../NOUSSale.sol";
import "../base/Ownable.sol";
import "../lib/SafeMath.sol";


contract SalesAgent is Ownable {
    //address saleContractAddress;
    // Main contract token address
    using SafeMath for uint256;

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    NOUSSale nousTokenSale; // contract nous sale

    /**
	* event for token purchase logging
	* @param beneficiary who got the tokens
	* @param value weis paid for purchase
	* @param amount amount of tokens purchased
	*/
    event TokenPurchase(address _agent, address indexed beneficiary, uint256 value, uint256 amount);

    // refund token if not valid;
    event TokenValidateRefund(address _agent, address indexed beneficiary, uint256 value);

    event Contribute(address _agent, address _sender, uint256 _value);

    event FinaliseSale(address _agent, address _sender, uint256 _value);

    event FinaliseICO(address _agent, address _sender);

    event Refund(address _agent, address _sender, uint256 _value);

    event TransferToDepositAddress(address _agent, address _sender, uint256 _value);

    event ReserveBonuses(address _agent, address _sender, uint256 _totalReserve);

    function finaliseFunding() onlyOwner {

        // Do some common contribution validation, will throw if an error occurs - address calling this should match the deposit address
        if (nousTokenSale.finalizeSaleContract(this)) {
            uint256 tokenMinted = nousTokenSale.getSaleContractTokensMinted(this);
            FinaliseSale(this, msg.sender, tokenMinted);
        }
    }

    // @dev General validation for a sales agent contract receiving a contribution,
    // @dev additional validation can be done in the sale contract if required
    // @param _value The value of the contribution in wei
    // @return A boolean that indicates if the operation was successful.
    function validateContribution(uint256 _value) internal returns (bool) {
        return (_value > 0 && // value
        _value >= nousTokenSale.getSaleContractMinDeposit(this) && // Is it above the min deposit amount?
        _value <= nousTokenSale.getSaleContractMaxDeposit(this) &&
        nousTokenSale.weiRaised().add(_value) <= nousTokenSale.targetEthMax()
        );
    }

    // @dev Validate state contract
    function validateStateSaleContract() internal returns (bool) {
        return ( nousTokenSale.getSaleContractIsFinalised(this) == false && // No minting if the sale contract has finalised
        now > nousTokenSale.getSaleContractStartTime(this) &&
        now < nousTokenSale.getSaleContractEndTime(this)
        );
    }

    function validPurchase(address _agent, uint _tokens) internal returns (bool) {
        return ( _tokens > 0  &&
        nousTokenSale.getSaleContractTokensLimit(_agent) >= nousTokenSale.getSaleContractTokensMinted(_agent) && // within Tokens mined
        nousTokenSale.totalSupplyCap() >= nousTokenSale.getTokenTotalSupply().add(_tokens)
        );
    }

    // Deliver
    // @dev Function to send NOUS to presale investors
    // Can only be called while the presale is not over.
    // @param _salesAgent addresses sale agent
    // @param _batchOfAddresses list of addresses
    // @param _amountOf matching list of address balances
    function deliverPresaleTokens(address[] _batchOfAddresses, uint256[] _amountOf)
        external onlyOwner returns (bool success)
    {
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_batchOfAddresses[i], _amountOf[i]);
        }
        return true;
    }

    // @dev Logic to transfer presale tokens
    // Can only be called while the there are leftover presale tokens to allocate. Any multiple contribution from
    // the same address will be aggregated.
    // @param _accountHolder user address
    // @param _amountOf balance to send out
    function deliverTokenToClient(address _accountHolder, uint256 _amountOf)
    public onlyOwner returns (bool) {
        require(_accountHolder != 0x0);
        uint256 _tokens = _amountOf.mul(EXPONENT);
        require(validPurchase(this, _tokens));

        nousTokenSale.tokenMint(_accountHolder, _tokens);

        TokenPurchase(
            msg.sender,
            _accountHolder,
            0,
            _tokens
        );

        return true;
    }

    /*function setSaleAddress(address _saleContractAddress) onlyOwner {
        nousTokenSale = NOUSSale(_saleContractAddress);
    }*/


}