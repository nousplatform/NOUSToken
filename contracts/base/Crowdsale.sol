pragma solidity ^0.4.11;


import "./BaseContract.sol";


/**
 * @title Crowdsale
 */
contract Crowdsale is BaseContract {

    //@dev Payable Function bay tokens, sales go only sale agent contract
    //@param _beneficiary Address of the buyer
    //@param _rate Rate for tokens mint
    function buyTokens(address _beneficiary, uint256 _rate) external validateSaleAgent(msg.sender) payable {
        require(totalSaleState == saleState.Active);
        require(_beneficiary != 0x0);
        require(_rate > 0);
        require(msg.value > 0);
        require(weiRaised.add(msg.value) <= TARGET_ETH_MAX);

        uint256 _weiAmount = msg.value;
        uint256 _tokens = _weiAmount.mul(_rate);

        BonusForAffiliateInterface BonusForAffiliate = BonusForAffiliateInterface(Doug["bonus_for_affiliate"]);
        address _referral = BonusForAffiliate.getReferralAddress(_beneficiary);

        if (_referral != 0x0) {
            uint256 _bonus = _weiAmount.mul(percentBonusForAffiliate).div(100);
            _weiAmount = _weiAmount.sub(_bonus);
            BonusForAffiliate.addBonus.value(_bonus)(_beneficiary, _referral);
        }

        tokenMint(_beneficiary, _tokens);

        RefundVaultInterface(Doug["refund_vault"]).deposit.value(_weiAmount)(_beneficiary);
        // transfer ETH to refund contract
        weiRaised = weiRaised.add(_weiAmount);
        // increment wei Raised
        BuyingTokens(
            msg.sender,
            _beneficiary,
            _weiAmount
        );
    }

    //Todo FOR TEST
    function testTotalSuplay() public constant returns(uint256) {
        TokenInterface(Doug["nous_token"]).totalSupply();
    }

    //@notice Mintable Tokens
    //@param _beneficiary address beneficiary tokens
    //@param _tokens Token amount
    function tokenMint(address _beneficiary, uint256 _tokens) public validateSaleAgent(msg.sender) {
        require(_beneficiary != 0x0);
        require(_tokens > 0);

        TokenInterface Token =  TokenInterface(Doug["nous_token"]);
        require(TOTAL_SUPPLY_CAP >= Token.totalSupply().add(_tokens));

        Token.mint(_beneficiary, _tokens);
        TokenMinted(msg.sender, _beneficiary, _tokens);
    }

    /// @dev global finalization is activate this function all sales wos stoped.
    /// end reserve percent bonuses
    function finalizeICO() external validateSaleAgent(msg.sender) {

        require(totalSaleState != saleState.Ended);
        require(salesAgents[msg.sender].isFinalized == false);

        TokenInterface Token =  TokenInterface(Doug["nous_token"]);

        // reserve bonuses and write all tokens on paymentbounty contract
        uint256 _totalReserved = PaymentBountyInterface(Doug["payment_bounty"]).reserveBonuses(Token.totalSupply());
        Token.mint(Doug["payment_bounty"], _totalReserved);

        // stop mining tokens
        totalSaleState = saleState.Ended;
    }

    // @dev payed bonuses as plan
    function payDelayBonuses(uint256 _startTime) external validateSaleAgent(msg.sender) {
        require(totalSaleState == saleState.Ended);
        PaymentBountyInterface(Doug["payment_bounty"]).payDelayBonuses(_startTime);
    }

}
