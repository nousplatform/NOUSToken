pragma solidity ^0.4.11;


import "./BaseContract.sol";
import "../interfaces/SalesAgentInterface.sol";
import "./BonusForAffiliate.sol";
import "./RefundVault.sol";
import "../NOUSToken.sol";


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 */
contract Crowdsale is BaseContract {

    // event for token purchase logging
    // @param purchaser who paid for the tokens
    // @param beneficiary who got the tokens
    // @param value weis paid for purchase
    // @param amount amount of tokens purchased
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    // @dev this contact sale not payed/ Payed only forwardFunds TODO validate this
    function buyTokens(address beneficiary, uint256 tokens) public isSalesContract(msg.sender) payable returns (bool) {
        require(saleState == SaleState.Active);
        // if sale is frozen TODO validate stop sale and send transaction
        require(beneficiary != 0x0);
        require(msg.value > 0);
        // TODO validate

        uint256 weiAmount = msg.value;

        BonusForAffiliate affiliate = BonusForAffiliate(affiliateAddr);
        address _referral = affiliate.getReferralAddress(beneficiary);

        if (_referral != address(0)) {
            uint256 bonus = weiAmount.mul(percentBonusForAffiliate).div(100);
            weiAmount = weiAmount.sub(bonus);
            affiliate.addBonus.value(bonus)(beneficiary, _referral);
        }

        tokenContract.mint(beneficiary, tokens);
        saleAgentContract.addTokensMinted(msg.sender, tokens);
        // increment tokensMinted

        RefundVault vaultContract = RefundVault(refundVaultAddr);

        vaultContract.deposit.value(weiAmount)(beneficiary);
        // transfer ETH to refund contract
        weiRaised = weiRaised.add(weiAmount);
        // increment wei Raised

        TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );

        return true;
    }

    //**************Validates*****************//
    // verifies that the gas price is lower than 50 gwei
    function validGasPrice(uint256 _gasPrice) external constant returns (bool) {
        return _gasPrice <= maxGasPrice;
    }

    /// @dev Validate state contract
    function validateStateSaleContract(address _salesAgent) public constant returns (bool) {
        return ( saleAgentContract.getSaleContractIsFinalised(_salesAgent) == false && // No minting if the sale contract has finalised
            now > saleAgentContract.getSaleContractStartTime(_salesAgent) &&
            now < saleAgentContract.getSaleContractEndTime(_salesAgent)
        );
    }

    /// @dev Validate Mined tokens
    function validPurchase(address _agent, uint _tokens) public returns (bool) {
        return ( _tokens > 0  &&
            saleAgentContract.getSaleContractTokensLimit(_agent) >= saleAgentContract.getSaleContractTokensMinted(_agent).add(_tokens) && // within Tokens mined
            totalSupplyCap >= tokenContract.totalSupply().add(_tokens)
        );
    }

    // @dev General validation for a sales agent contract receiving a contribution,
    // @dev additional validation can be done in the sale contract if required
    // @param _value The value of the contribution in wei
    // @return A boolean that indicates if the operation was successful.
    function validateContribution(uint256 _value) isSalesContract(msg.sender) returns (bool) {
        return (_value > 0 && // value
            _value >= saleAgentContract.getSaleContractMinDeposit(msg.sender) && // Is it above the min deposit amount?
            _value <= saleAgentContract.getSaleContractMaxDeposit(msg.sender) &&
            weiRaised.add(_value) <= targetEthMax
        );
    }

    /// @return true if crowdsale event has ended and call super.hasEnded
    function hasEnded(address _salesAgent) public constant returns (bool) {
        return saleAgentContract.getSaleContractExists(_salesAgent) == true && (
             saleAgentContract.getSaleContractTokensMinted(_salesAgent) >= saleAgentContract.getSaleContractTokensLimit(_salesAgent) ||
             weiRaised >= targetEthMax ||
             totalSupplyCap <= tokenContract.totalSupply() ||
             now > saleAgentContract.getSaleContractEndTime(_salesAgent)
        );
    }

    //***Finalize
    /// @dev Sets the contract sale agent process as completed, that sales agent is now retired
    /// oweride if ne logic and coll super finalize
    function finalizeSaleContract(address _salesAgent) public onlyOwner() returns (bool) {
        require(!saleAgentContract.getSaleContractIsFinalised(_salesAgent));
        require(hasEnded(_salesAgent));

        saleAgentContract.setFinalize(_salesAgent);
        SaleFinalised(_salesAgent, msg.sender, saleAgentContract.getSaleContractTokensMinted(_salesAgent));
        return true;
    }

    /// @dev global finalization is activate this function all sales wos stoped.
    /// end pay bonuses
    function finalizeICO(address _salesAgent) public onlyOwner() returns (bool) {
        //require(!isGlobalFinalized);
        require(saleAgentContract.getSaleContractContractType(msg.sender) == Data.SaleContractType.ReserveFunds);
        require(saleState != SaleState.Ended);
        require(saleAgentContract.getSaleContractIsFinalised(_salesAgent) == false);

        reserveBonuses();
        // reserve bonuses

        tokenContract.finishMinting();
        // stop mining tokens
        saleState = SaleState.Ended;
        // close all sale

        //isGlobalFinalized = true;
        return true;
    }

    //************* Control ETH *****************//
    //@dev close refunds and send coins to wallet
    function closeRefunds() public onlyOwner {
        RefundVault vaultContract = RefundVault(refundVaultAddr);
        vaultContract.close();
        // close vault contract and send ETH to Wallet
    }

    // @dev Refund coins in investors
    function enableRefunds() public onlyOwner {
        RefundVault vaultContract = RefundVault(refundVaultAddr);
        vaultContract.enableRefunds();
    }

    // @dev withdraw cash on wallet
    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        RefundVault vaultContract = RefundVault(refundVaultAddr);
        vaultContract.withdraw(_amount * 1 ether);
    }

    // Deliver
    // @dev Function to send NOUS to presale investors
    // Can only be called while the presale is not over.
    // @param _salesAgent addresses sale agent
    // @param _batchOfAddresses list of addresses
    // @param _amountOf matching list of address balances
    function deliverPresaleTokens(address _salesAgent, address[] _batchOfAddresses, uint256[] _amountOf)
        external onlyOwner returns (bool success)
    {
        //require(now < saleAgentContract.salesAgents[msg.sender].startTime);
        //require(saleAgentContract.salesAgents[msg.sender].saleContractType == 'presale');
        require(_batchOfAddresses.length == _amountOf.length);

        for (uint256 i = 0; i < _batchOfAddresses.length; i++) {
            deliverTokenToClient(_salesAgent, _batchOfAddresses[i], _amountOf[i]);
        }
        return true;
    }

    // @dev Logic to transfer presale tokens
    // Can only be called while the there are leftover presale tokens to allocate. Any multiple contribution from
    // the same address will be aggregated.
    // @param _accountHolder user address
    // @param _amountOf balance to send out
    function deliverTokenToClient(address _salesAgent, address _accountHolder, uint256 _amountOf)
    public onlyOwner returns (bool) {
        require(_accountHolder != 0x0);
        uint256 _tokens = _amountOf.mul(EXPONENT);
        require(validPurchase(_salesAgent, _tokens));

        tokenContract.mint(_accountHolder, _tokens);
        saleAgentContract.addTokensMinted(msg.sender, _tokens);

        TokenPurchase(
            msg.sender,
            _accountHolder,
            0,
            _tokens
        );

        return true;
    }

    //**************Bonuses*****************//
    // @dev start only minet close payout after delay
    // @dev and contract reserve funds
    function payDelayBonuses() public isSalesContract(msg.sender) {
        require(saleAgentContract.getSaleContractContractType(msg.sender) == Data.SaleContractType.ReserveFunds);
        require(saleState == SaleState.Ended);

        uint256 delayNextTime = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            uint256 dateDelay = saleAgentContract.getSaleContractStartTime(msg.sender);

            // todo WARNING  For test sets minutes
            // calculate date delay  1 month = 30 dey
            for (uint256 p = 0; p < bountyPayment[i].delay; p++) {
                dateDelay = dateDelay + (30 days);
                //dateDelay = dateDelay + (5 minutes);
            }

            // set last date payaout
            if (bountyPayment[i].timeLastPayout == 0) {
                delayNextTime = dateDelay;
            } else {
                delayNextTime = bountyPayment[i].timeLastPayout + (30 days); // todo minutes
                //delayNextTime = bountyPayment[i].timeLastPayout + (2 minutes);
            }

            // delay bonuses
            if (now >= dateDelay && bountyPayment[i].amountReserve > bountyPayment[i].totalPayout &&
              now >= delayNextTime) {
                uint256 payout = bountyPayment[i].amountReserve.div(bountyPayment[i].periodPathOfPay);
                tokenContract.transfer(bountyPayment[i].wallet, payout);
                // transfer bonuses
                bountyPayment[i].totalPayout = bountyPayment[i].totalPayout.add(payout);
                bountyPayment[i].timeLastPayout = delayNextTime;
            }
        }
    }

    // @dev reserve all bounty on this NOUSSale address contract
    function reserveBonuses() internal {

        uint256 totalSupply = tokenContract.totalSupply();

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            if (bountyPayment[i].amountReserve == 0) {
                bountyPayment[i].amountReserve = totalSupply.mul(bountyPayment[i].percent).div(100);
                // reserve fonds on this contract
                tokenContract.mint(this, bountyPayment[i].amountReserve);
            }
        }
    }


}
