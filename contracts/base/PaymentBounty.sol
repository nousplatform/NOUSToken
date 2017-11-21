pragma solidity ^0.4.0;


import "../base/Ownable.sol";
import "../interfaces/NOUSTokenInterface.sol";
import "../lib/SafeMath.sol";

contract PaymentBounty is Ownable {

    using SafeMath for uint256;

    address tokenAddress;

    struct Bounty {
        address wallet; // wallet address for transfer
        bytes32 name; // name bonus
        uint256 delay; // delay to payment in month
        uint256 percent; // percent payed
        uint256 periodPathOfPay; // on how many equal parts to pay
        uint256 amountReserve; // amount acured
        uint256 totalPayout; // how is payed
        uint256 timeLastPayout; // how is payed
    }

    Bounty[] public bountyPayment; // array bonuses

    function PaymentBounty(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }

    /// @dev add bounty initial state
    function setPaymentBounty(
        address _walletAddress,
        bytes32 _name,
        uint256 _percent,
        uint256 _delay,
        uint256 _periodPathOfPay
    )
    public onlyOwner
    {
        assert(_walletAddress != 0x0);
        Bounty memory newBounty;
        newBounty.wallet = _walletAddress;
        newBounty.name = _name;
        newBounty.percent = _percent;
        newBounty.delay = _delay;
        newBounty.periodPathOfPay = _periodPathOfPay;
        newBounty.amountReserve = 0;
        newBounty.totalPayout = 0;
        bountyPayment.push(newBounty);
    }

    // @dev reserve all bounty on this NOUSSale address contract
    function reserveBonuses(uint256 _totalSupply) public onlyOwner returns (uint256){

        uint256 totalReserved = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            if (bountyPayment[i].amountReserve == 0) {
                bountyPayment[i].amountReserve = _totalSupply.mul(bountyPayment[i].percent).div(100);
                // reserve fonds on this contract

                totalReserved = totalReserved + bountyPayment[i].amountReserve;
            }
        }
        return totalReserved;
    }

    // @dev start only minet close payout after delay
    // @dev and contract reserve funds
    function payDelayBonuses(uint256 _startTime) public onlyOwner {
        //require(salesAgents[msg.sender].saleContractType == Data.SaleContractType.ReserveFunds);
        //require(saleState == SaleState.Ended);

        uint256 delayNextTime = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            uint256 dateDelay = _startTime;

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
                NOUSTokenInterface(tokenAddress).transfer(bountyPayment[i].wallet, payout);
                // transfer bonuses
                bountyPayment[i].totalPayout = bountyPayment[i].totalPayout.add(payout);
                bountyPayment[i].timeLastPayout = delayNextTime;
            }
        }
    }
}
