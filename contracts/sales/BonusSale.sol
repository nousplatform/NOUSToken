pragma solidity ^0.4.11;


import "./BaseSaleAgent.sol";
import "../NousplatformCrowdSale.sol";


contract BonusSale is BaseSaleAgent {

    struct BonusRateStruct {
        uint256 period; // in week rate
        uint256 rate;
    }

    BonusRateStruct[] bonusRates; // index rates

    /// @dev constructor
    function NOUSCrowdsale(address _saleContractAddress) {

        // todo переделать
        addBonusRate(1, 7300);
        // 1 Week = 7300 NOUS
        addBonusRate(2, 7000);
        // 2 Week 1 ETH = 7000 NOUS
        addBonusRate(3, 6700);
        // 3 Week 1 ETH = 6700 NOUS
    }

    function bayToken() payable external {
        rate = getBonusRate();
        super.bayToken();
    }

    //@dev addBonusRate adding bonuses foe weeks period
    //@param _period In hours
    //@param _rate array periods for bonus
    function addBonusRate(uint256 _period, uint256 _rate) public onlyOwner {
        require(_period > 0 && _rate > 0);

        bonusRates.push(BonusRateStruct({
            period : _period,
            rate : _rate
        }));
    }

    //@dev TODO Доделать функцию с периодами get period rates
    function getBonusRate() internal returns (uint256) {
        for (uint256 i = 0; i < bonusRates.length; i++) {
            uint256 toPeriod = startTime;
            toPeriod = toPeriod + bonusRates[i].period * 1 hours;

            if (now < toPeriod) {
                return bonusRates[i].rate;
            }
        }

        return rate;
    }

}
