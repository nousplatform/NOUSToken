pragma solidity ^0.4.11;

import './BaseContract.sol';
import "../interfaces/SalesAgentInterface.sol";
import './BonusForAffiliate.sol';

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is BaseContract {

    uint256 timeNow;
    /**
    * event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /// @dev this contact sale not payed/ Payed only forwardFunds TODO validate this
    function buyTokens(address beneficiary, uint256 tokens) isSalesContract(msg.sender) public payable returns (bool)  {

        require(saleState == SaleState.Active);
        // if sale is frozen TODO validate stop sale and send transaction
        require(beneficiary != 0x0);
        require(msg.value > 0);
        // TODO validate

        uint256 weiAmount = msg.value;

        BonusForAffiliate Affiliate = BonusForAffiliate(affiliate);
        address _referral = Affiliate.getPartner(beneficiary);

        if (_referral != address(0)) {
            uint256 bonus = weiAmount.mul(percentBonusForAffiliate).div(100);
            weiAmount = weiAmount.sub(bonus);
            Affiliate.addAffiliateBonus.value(bonus)(_referral, beneficiary);
        }

        Token.mint(beneficiary, tokens);
        salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(tokens);
        // increment tokensMinted

        Vault.deposit.value(weiAmount)(beneficiary);
        // transfer ETH to refund contract
        weiRaised = weiRaised.add(weiAmount);
        // increment wei Raised

        TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

        return true;
    }

    //**************Validates*****************//

    // verifies that the gas price is lower than 50 gwei
    function validGasPrice(uint256 _gasprice) returns (bool){
        return _gasprice <= MAX_GAS_PRICE;
    }

    /// @dev Validate state contract
    function validateStateSaleContract(address _salesAgent) public returns (bool) {
        return salesAgents[_salesAgent].isFinalized == false // No minting if the sale contract has finalised
        && now > salesAgents[_salesAgent].startTime //
        && now < salesAgents[_salesAgent].endTime;
        // within time
    }

    /// @dev Validate Mined tokens
    function validPurchase(address _agent, uint _tokens) public returns (bool) {
        return _tokens > 0 // non zero
        && salesAgents[_agent].tokensLimit >= salesAgents[_agent].tokensMinted.add(_tokens) // within Tokens mined
        && totalSupplyCap >= Token.totalSupply().add(_tokens);
    }

    /// @dev General validation for a sales agent contract receiving a contribution, additional validation can be done in the sale contract if required
    /// @param _value The value of the contribution in wei
    /// @return A boolean that indicates if the operation was successful.
    function validateContribution(uint256 _value) isSalesContract(msg.sender) returns (bool) {
        return _value > 0
        && _value >= salesAgents[msg.sender].minDeposit // Is it above the min deposit amount?
        && _value <= salesAgents[msg.sender].maxDeposit
        && weiRaised.add(_value) <= targetEthMax;
        // Does this deposit put it over the max target ether for the sale contract?
    }

    /// @return true if crowdsale event has ended and call super.hasEnded
    function hasEnded(address _salesAgent) public constant returns (bool) {
        return salesAgents[_salesAgent].exists == true
        && (salesAgents[_salesAgent].tokensMinted >= salesAgents[_salesAgent].tokensLimit //capReachedToken
        || weiRaised >= targetEthMax //capReachedWei
        || totalSupplyCap <= Token.totalSupply()
        || now > salesAgents[_salesAgent].endTime);
        //timeAllow
    }

    //*******************Finalize*****************//

    /// @dev Sets the contract sale agent process as completed, that sales agent is now retired
    /// oweride if ne logic and coll super finalize
    function finalizeSaleContract(address _salesAgent) ownerOrSale() public returns (bool) {
        require(!salesAgents[_salesAgent].isFinalized);
        require(hasEnded(_salesAgent));

        salesAgents[_salesAgent].isFinalized = true;
        SaleFinalised(_salesAgent, msg.sender, salesAgents[_salesAgent].tokensMinted);
        return true;
    }

    /// @dev global finalization is activate this function all sales wos stoped.
    /// end pay bonuses
    function finalizeICO(address _salesAgent) ownerOrSale() public returns (bool)  {
        //require(!isGlobalFinalized);
        require(salesAgents[msg.sender].saleContractType == SaleContractType.ReserveFunds);
        require(saleState != SaleState.Ended);
        require(salesAgents[_salesAgent].isFinalized == false);

        reserveBonuses();
        // reserve bonuses

        Token.finishMinting();
        // stop mining tokens
        saleState = SaleState.Ended;
        // close all sale

        //isGlobalFinalized = true;
        return true;
    }

    //************* Control ETH *****************//

    /**
    * @dev close refunds and send coins to wallet
    */
    function closeRefunds() onlyOwner {
        Vault.close();
        // close vault contract and send ETH to Wallet
    }

    /**
    * @dev Refund coins in investors
    */
    function enableRefunds() onlyOwner {
        Vault.enableRefunds();
    }

    /**
    * @dev withdraw cash on wallet
    */
    function withdraw(uint256 _amount) onlyOwner public {
        require(_amount > 0);
        Vault.withdraw(_amount * 1 ether);
    }

    //***** Deliver *****************//

    /**
    * @dev Function to send NOUS to presale investors
    * Can only be called while the presale is not over.
    * @param _salesAgent addresses sale agent
    * @param _batchOfAddresses list of addresses
    * @param _amountOf matching list of address balances
    */
    function deliverPresaleTokens(address _salesAgent, address[] _batchOfAddresses, uint256[] _amountOf)
    external ownerOrSale returns (bool success) {
        //require(now < salesAgents[msg.sender].startTime);
        //require(salesAgents[msg.sender].saleContractType == 'presale');
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_salesAgent, _batchOfAddresses[i], _amountOf[i]);
        }
        return true;
    }

    /**
    * @dev Logic to transfer presale tokens
    * Can only be called while the there are leftover presale tokens to allocate. Any multiple contribution from
    * the same address will be aggregated.
    * @param _accountHolder user address
    * @param _amountOf balance to send out
    */
    function deliverTokenToClient(address _salesAgent, address _accountHolder, uint256 _amountOf) ownerOrSale public returns (bool){
        require(_accountHolder != 0x0);
        uint256 _tokens = _amountOf.mul(exponent);
        require(validPurchase(_salesAgent, _tokens));

        Token.mint(_accountHolder, _tokens);
        salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(_tokens);

        TokenPurchase(msg.sender, _accountHolder, 0, _tokens);
        return true;
    }

    //**************Bonuses*****************//

    /// @dev reserve all bounty on this NOUSSale address contract
    function reserveBonuses() internal {

        uint256 totalSupply = Token.totalSupply();

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            if (bountyPayment[i].amountReserve == 0) {
                bountyPayment[i].amountReserve = totalSupply.mul(bountyPayment[i].percent).div(100);
                // reserve fonds on this contract
                Token.mint(this, bountyPayment[i].amountReserve);
            }
        }
    }

    // @dev start only minet close
    function payDelayBonuses() public isSalesContract(msg.sender) {
        require(salesAgents[msg.sender].saleContractType == SaleContractType.ReserveFunds);
        require(saleState == SaleState.Ended);

        uint256 delayNextTime = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++)
        {
            uint256 dateDelay = salesAgents[msg.sender].startTime;

            // todo WARNING  For test sets minutes
            // calculate date delay  1 month = 30 dey
            for (uint256 p = 0; p < bountyPayment[i].delay; p++) {
                //dateDelay = dateDelay + (30 days);
                dateDelay = dateDelay + (5 minutes);
            }

            // set last date payaout
            if (bountyPayment[i].timeLastPayout == 0) {
                delayNextTime = dateDelay;
            }
            else {
                //delayNextTime = bountyPayment[i].timeLastPayout + (30 days); // todo minutes
                delayNextTime = bountyPayment[i].timeLastPayout + (2 minutes);
                // todo minutes
            }

            // delay bonuses
            if (now >= dateDelay
            && bountyPayment[i].amountReserve > bountyPayment[i].totalPayout
            && now >= delayNextTime)
            {
                uint256 payout = bountyPayment[i].amountReserve.div(bountyPayment[i].periodPathOfPay);
                Token.transfer(bountyPayment[i].wallet, payout);
                // transfer bonuses
                bountyPayment[i].totalPayout = bountyPayment[i].totalPayout.add(payout);
                bountyPayment[i].timeLastPayout = delayNextTime;
            }
        }
    }


}
