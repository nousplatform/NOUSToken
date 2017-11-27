pragma solidity ^0.4.11;

import "../NOUSSale.sol";
import "../base/Ownable.sol";
import "../lib/SafeMath.sol";


contract SalesAgent is Ownable {
    //address saleContractAddress;
    // Main contract token address
    using SafeMath for uint256;

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    NOUSSale public nousTokenSale; // contract nous sale

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

    function finalise() onlyOwner {

        // Do some common contribution validation, will throw if an error occurs - address calling this should match the deposit address
        if (nousTokenSale.finalizeSale()) {
            uint256 tokenMinted = nousTokenSale.getSaleContractTokensMinted(this);
            FinaliseSale(this, msg.sender, tokenMinted);
        }
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

        nousTokenSale.tokenMint(_accountHolder, _tokens);

        TokenPurchase(
            msg.sender,
            _accountHolder,
            0,
            _tokens
        );

        return true;
    }

}