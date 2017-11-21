pragma solidity ^0.4.11;


import "./token/MintableToken.sol";
import "./base/Crowdsale.sol";
import "./interfaces/PaymentBountyInterface.sol";


contract NOUSSale is Crowdsale {

    //wallet = 0xdd870fa1b7c4700f2bd7f44238821c26f7392148; // todo add address wallet amount

    function NOUSSale(address _token, address _vault, address _affiliate, address _bonuses)
    BaseContract(_token, _vault, _affiliate, _bonuses)
    {
        //777 Million tokens
        totalSupplyCap = 777 * (10 ** 6) * EXPONENT;

        //543 900 000 tokens  Available for purchase
        availablePurchase = 543900000 * EXPONENT;

        // minimum amount of funds to be raised in weis
        targetEthMax = 85000 * (1 ether);

        // maximum gas price for contribution transactions
        maxGasPrice = 300000 wei;

        // minimum amount of funds to be raised in weis
        targetEthMin = 5500  * (1 ether); // todo For test uncoment
        //targetEthMin = 4 * (1 ether);

        // @dev bonus from affiliate
        percentBonusForAffiliate = 10;

    }

}
