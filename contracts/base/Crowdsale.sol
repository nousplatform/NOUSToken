pragma solidity ^0.4.11;


import "./BaseContract.sol";
import "../interfaces/SalesAgentInterface.sol";
//import "./BonusForAffiliate.sol";
import "../interfaces/BonusForAffiliateInterface.sol";
import "../interfaces/RefundVaultInterface.sol";
import "../interfaces/PaymentBountyInterface.sol";

//import "../interfaces/NOUSTokenInterface.sol";


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
    // @dev this contact sale not payed/ Payed only forwardFunds
    function buyTokens(address beneficiary, uint256 tokens) public isSalesContract(msg.sender) payable returns (bool) {
        require(saleState == SaleState.Active);
        require(beneficiary != 0x0);
        require(msg.value > 0);

        uint256 weiAmount = msg.value;

        BonusForAffiliateInterface affiliate = BonusForAffiliateInterface(affiliateAddr);
        address _referral = affiliate.getReferralAddress(beneficiary);

        if (_referral != address(0)) {
            uint256 bonus = weiAmount.mul(percentBonusForAffiliate).div(100);
            weiAmount = weiAmount.sub(bonus);
            affiliate.addBonus.value(bonus)(beneficiary, _referral);
        }

        tokenMint(beneficiary, tokens);

        RefundVaultInterface(refundVaultAddr).deposit.value(weiAmount)(beneficiary);
        // transfer ETH to refund contract
        weiRaised = weiRaised.add(weiAmount);
        // increment wei Raised
        TranslateEther(
            msg.sender,
            beneficiary,
            weiAmount
        );

        return true;
    }

    function tokenMint(address beneficiary, uint256 tokens) public isSalesContract(msg.sender) returns (bool) {
        require(saleState == SaleState.Active);
        require(beneficiary != 0x0);
        require(tokens > 0);

        tokenContract.mint(beneficiary, tokens);
        salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(tokens);
        TokenMinted(msg.sender, beneficiary, tokens);
        return true;
    }

    //**************Validates*****************//
    // verifies that the gas price is lower than 50 gwei
    function validGasPrice(uint256 _gasPrice) external constant returns (bool) {
        return _gasPrice <= maxGasPrice;
    }

    /// @return true if crowdsale event has ended and call super.hasEnded
    function hasEnded(address _salesAgent) public constant returns (bool) {
        return salesAgents[_salesAgent].exists == true && (
             salesAgents[_salesAgent].tokensMinted >= salesAgents[_salesAgent].tokensLimit ||
             weiRaised >= targetEthMax ||
             totalSupplyCap <= tokenContract.totalSupply() ||
             now > salesAgents[_salesAgent].endTime
        );
    }

    //***Finalize 
    /// @dev Sets the contract sale agent process as completed, that sales agent is now retired
    /// oweride if ne logic and coll super finalize
    function finalizeSaleContract(address _salesAgent) public onlyOwner() returns (bool) {
        require(!salesAgents[_salesAgent].isFinalized);
        require(hasEnded(_salesAgent));

        salesAgents[_salesAgent].isFinalized = true;
        SaleFinalised(_salesAgent, msg.sender, salesAgents[_salesAgent].tokensMinted);
        return true;
    }

    /// @dev global finalization is activate this function all sales wos stoped.
    /// end pay bonuses
    function finalizeICO(address _salesAgent) public onlyOwner() returns (bool) {
        //require(!isGlobalFinalized);
        require(salesAgents[msg.sender].saleContractType == Data.SaleContractType.ReserveFunds);
        require(saleState != SaleState.Ended);
        require(salesAgents[_salesAgent].isFinalized == false);

        // reserve bonuses and write all tokens on paymentbounty contract
        uint256 totalReserved = PaymentBountyInterface(bountyAddr).reserveBonuses(tokenContract.totalSupply());
        tokenContract.mint(bountyAddr, totalReserved);

        tokenContract.finishMinting();
        // stop mining tokens
        saleState = SaleState.Ended;
        // close all sale

        //isGlobalFinalized = true;
        return true;
    }

    // @dev TODO If need manualy
    function setPaymentBounty(/*address wallet, byte32 type, uint256 percent, uint256 payedPeriod, uint256 payedPath*/) public onlyOwner returns (bool) {
        //require(wallet != 0x0);
        //require(percent > 0);

        PaymentBountyInterface paymentBounty = PaymentBountyInterface(bountyAddr);
        // 20% Will Be Retained by Nousplatform
        // Nousplatform retained tokens are locked for the first 4 months, and will be vested over a period of 20 months total,
        // 5% every month. The total vesting period is 24 months.
        paymentBounty.setPaymentBounty(0xe594004148C30B1762A108F017999F081aDa8143, "TeamBonus", 20, 4, 5);
        // test account 4

        // 5% Advisors, Grants, Partnerships  Advisors tokens are locked for 2 months and distributed fully.
        paymentBounty.setPaymentBounty(0x4043BF02966Fa198fa24489Ca76DE1Be669f6e33, "AdvisorsBonus", 5, 2, 1);
        // test account 5

        // 3% Community, 2% Will Be Used To Cover Token Sale
        paymentBounty.setPaymentBounty(0x96473fFE81913158a113bA5683B050DD264d2a9C, "GrantsBonus", 5, 0, 1);
        // test account 6
    }

    function payDelayBonuses() public isSalesContract(msg.sender) {
        require(salesAgents[msg.sender].saleContractType == Data.SaleContractType.ReserveFunds);
        require(saleState == SaleState.Ended);

        PaymentBountyInterface(bountyAddr).payDelayBonuses(salesAgents[msg.sender].startTime);
    }

}
