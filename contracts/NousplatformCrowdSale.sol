pragma solidity ^0.4.11;


import "./token/MintableToken.sol";
import "./base/Crowdsale.sol";
import "./interfaces/PaymentBountyInterface.sol";


contract NousplatformCrowdSale is Crowdsale {

    function NousplatformCrowdSale(address _token, address _vault, address _affiliate, address _bonuses)
    BaseContract(_token, _vault, _affiliate, _bonuses)
    {
        //544 Million tokens
        totalSupplyCap = 777 * (10 ** 6) * EXPONENT;

        //543 900 000 tokens  Available for purchase
        availablePurchase = 543900000 * EXPONENT; // эта нигде не используется!!

        // minimum amount of funds to be raised in weis
        targetEthMax = 54000 * (1 ether);

        // minimum amount of funds to be raised in weis
        targetEthMin = 3500  * (1 ether);

        // maximum gas price for contribution transactions
        maxGasPrice = 300000 wei;

        // @dev bonus from affiliate
        percentBonusForAffiliate = 10;
    }

    // @dev TODO If need manualy
    function setPaymentBounty(address wallet, bytes32 typeBounty, uint256 percent, uint256 payedPeriod, uint256 payedPath) public onlyOwner returns (bool) {
        require(wallet != 0x0);
        require(percent > 0);

        PaymentBountyInterface paymentBounty = PaymentBountyInterface(bountyAddr);
        paymentBounty.setPaymentBounty(wallet, typeBounty, percent, payedPeriod, payedPath);

        // 20% Will Be Retained by Nousplatform
        // Nousplatform retained tokens are locked for the first 4 months, and will be vested over a period of 20 months total,
        // 5% every month. The total vesting period is 24 months.
        //paymentBounty.setPaymentBounty(0xe594004148C30B1762A108F017999F081aDa8143, "TeamBonus", 20, 4, 5);
        // test account 4

        // 5% Advisors, Grants, Partnerships  Advisors tokens are locked for 2 months and distributed fully.
        //paymentBounty.setPaymentBounty(0x4043BF02966Fa198fa24489Ca76DE1Be669f6e33, "AdvisorsBonus", 5, 2, 1);
        // test account 5

        // 3% Community, 2% Will Be Used To Cover Token Sale
        //paymentBounty.setPaymentBounty(0x96473fFE81913158a113bA5683B050DD264d2a9C, "GrantsBonus", 5, 0, 1);
        // test account 6
    }

}
