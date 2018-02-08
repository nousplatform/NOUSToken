pragma solidity ^0.4.18;

import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../interfaces/CrowdSaleInterface.sol";


contract BaseSaleAgent is Ownable {

    event FinaliseSale(uint256 tokensMinted, uint256 weiAmount, uint256 dateFinalize);
    event TokenPurchase(address indexed beneficiary, uint256 value, uint256 tokens);

    using SafeMath for uint256;
    uint256 internal constant EXPONENT = 10 ** uint256(18);

    //address dougSaleAddress; // Address nousplatformCrowdSale of the contract
    uint256 tokensLimit; // The maximum amount of tokens this sale contract is allowed to distribute
    uint256 minDeposit; // The minimum deposit amount allowed
    uint256 maxDeposit; // The maximum deposit amount allowed
    uint256 startTime; // The start time (unix format) when allowed to mint tokens
    uint256 endTime; // The end time from unix format when to finish minting tokens
    uint256 rate; // default rate
    uint256 tokensMinted; // The current amount of tokens minted by this agent
    uint256 weiRaised; // The current amount of tokens minted by this agent
    bool isFinalized; // Has this sales contract been completed and the ether sent to the deposit address

    CrowdSaleInterface public CrowdSale;

    /**
      @notice Set the address of a new crowdsale/presale contract agent if needed, usefull for upgrading
      @notice Only the owner can register a new sale agent
      @param _dougSaleAddress The address of the new token sale contract
      @param _tokensLimit The maximum amount of tokens this sale contract is allowed to distribute
      @param _minDeposit The minimum deposit amount allowed
      @param _maxDeposit The maximum deposit amount allowed
      @param _startTime The start time when allowed to mint tokens
      @param _endTime The end time when to finish minting tokens
      @param _rate tokens rate
    */
    function setParamsSaleAgent(
        address _dougSaleAddress,
        uint256 _tokensLimit,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate
    ) public onlyOwner {
        require(_dougSaleAddress != 0x0); // Valid addresses
        require(_tokensLimit > 0); // Must have some available tokens
        require(_maxDeposit > _minDeposit); // Make sure the min deposit is less than or equal to the max
        require(_endTime > _startTime);

        // Add the new sales contract
        CrowdSale = CrowdSaleInterface(_dougSaleAddress);

        tokensLimit = _tokensLimit * EXPONENT;
        minDeposit = _minDeposit * 1 ether;
        maxDeposit = _maxDeposit * 1 ether;
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        isFinalized = false;
    }

    function getAllParams() public constant returns(
        uint256 _tokensLimit,
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        uint256 _tokensMinted,
        uint256 _weiRaised,
        bool _finalize
    ) {
        return (tokensLimit, minDeposit, maxDeposit, startTime, endTime, rate, tokensMinted, weiRaised, isFinalized);
    }

    //@dev you may redefined this function, but coll method super
    function finalise() public onlyOwner {
        require(isFinalized == false);
        isFinalized = true;
        CrowdSale.finalizeSale();
        FinaliseSale(tokensMinted, weiRaised, now);
    }

    // Deliver
    //@dev Function to send NOUS to investors, presale
    //@dev Can only be called while the presale is not over.
    //@param _batchOfAddresses list of addresses
    //@param _amountOf matching list of address balances
    function deliverTokens(address[] _batchOfAddresses, uint256[] _amountOf) external onlyOwner {
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_batchOfAddresses[i], _amountOf[i]);
        }
    }

    // @dev Logic to transfer presale tokens
    // Can only be called while the there are leftover presale tokens to allocate. Any multiple contribution from
    // the same address will be aggregated.
    // @param _accountHolder user address
    // @param _amountOf balance to send out integer
    function deliverTokenToClient(address _accountHolder, uint256 _amountOf) public onlyOwner {
        require(isFinalized == false);
        require(_accountHolder != 0x0);
        uint256 _tokens = _amountOf.mul(EXPONENT);

        CrowdSale.tokenMint(_accountHolder, _tokens);

        TokenPurchase(
            _accountHolder,
            0,
            _tokens
        );
    }

    function availabilityCheckPurchase() public constant returns (bool) {
        return isFinalized == false && now > startTime && now < endTime;
    }

    function checkValue(uint256 _value) public constant returns (bool) {
        return _value > 0 && minDeposit > _value && maxDeposit < _value;
    }
}
