pragma solidity ^0.4.11;


import "./BaseContract.sol";
import "../interfaces/SalesAgentInterface.sol";
//import "./BonusForAffiliate.sol";
import "../interfaces/BonusForAffiliateInterface.sol";
import "../interfaces/RefundVaultInterface.sol";
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

        RefundVaultInterface vaultContract = RefundVaultInterface(refundVaultAddr);

        vaultContract.deposit.value(weiAmount)(beneficiary);
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
    /*function closeRefunds() public onlyOwner {
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
    }*/



    //**************Bonuses*****************//
    // @dev start only minet close payout after delay
    // @dev and contract reserve funds
    /*function payDelayBonuses() public isSalesContract(msg.sender) {
        require(salesAgents[msg.sender].saleContractType == Data.SaleContractType.ReserveFunds);
        require(saleState == SaleState.Ended);

        uint256 delayNextTime = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            uint256 dateDelay = salesAgents[msg.sender].startTime;

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
    }*/

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
