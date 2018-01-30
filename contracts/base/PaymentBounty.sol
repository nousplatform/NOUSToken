pragma solidity ^0.4.0;


import "../base/Ownable.sol";
import "../interfaces/NOUSTokenInterface.sol";
import "../lib/SafeMath.sol";

contract PaymentBounty is Ownable {

    using SafeMath for uint256;

    address public tokenAddress;

    address public dugSale;

    uint256 delay;

    event PayBonuses(address wallet, uint256 tokens);

    struct Bounty {
        address wallet; // wallet address for transfer
        bytes32 name; // name bonus
        uint256 delay; // delay to payment in month
        uint256 percent; // percent payed
        uint256 periodPathOfPay; // on how many equal parts to pay
        uint256 amountReserve; // amount acured
        uint256 totalPayout; // how is payed
        uint256 timeLastPayout; // how is payed
        bool reject;
    }

    Bounty[] public bountyPayment; // array bonuses

    function PaymentBounty(address _tokenAddress) {
        require(_tokenAddress != 0x0);
        tokenAddress = _tokenAddress;
        delay = 1800; // 1800 hours => 30 dey to period pay
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0x0);
        tokenAddress = _tokenAddress;
    }

    /**
    * @dev Set dug sale address
    */
    function setDugSaleAddress(address _dugSale) public onlyOwner {
        require(_dugSale != 0x0);
        dugSale = _dugSale;
    }

    function setDelayBonuses(uint256 _delay) public onlyOwner {
        delay = _delay;
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
        require(_walletAddress != 0x0);
        Bounty memory newBounty;
        newBounty.wallet = _walletAddress;
        newBounty.name = _name;
        newBounty.percent = _percent;
        newBounty.delay = _delay;
        newBounty.periodPathOfPay = _periodPathOfPay;
        newBounty.amountReserve = 0;
        newBounty.totalPayout = 0;
        newBounty.reject = false;
        bountyPayment.push(newBounty);
    }

    // @dev reserve all bounty on this NousplatformCrowdSale address contract
    function getTotalReserveBonuses(uint256 _totalSupply) public constant returns(uint256) {
        uint256 totalReserved = 0;
        for (uint256 i = 0; i < bountyPayment.length; i++) {
            if (bountyPayment[i].amountReserve == 0) {
                bountyPayment[i].amountReserve = _totalSupply.mul(bountyPayment[i].percent).div(100);
                totalReserved = totalReserved + bountyPayment[i].amountReserve;
            }
        }
        return totalReserved;
    }

    // @dev start only minet close payout after delay
    // @dev and contract reserve funds
    function payDelayBonuses(uint256 _startTime) public  {
        require(dugSale != msg.sender);

        uint256 delayNextTime = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            uint256 dateDelay = _startTime;

            // calculate date delay  1 month = 30 dey
            for (uint256 p = 0; p < bountyPayment[i].delay; p++) {
                dateDelay = dateDelay + (delay * 1 hours); //delay bonuses 30 deys default
            }

            // set last date payaout
            if (bountyPayment[i].timeLastPayout == 0) {
                delayNextTime = dateDelay;
            } else {
                delayNextTime = bountyPayment[i].timeLastPayout + (delay * 1 hours); //delay bonuses 30 deys default
            }

            // delay bonuses
            if (now >= dateDelay && bountyPayment[i].amountReserve > bountyPayment[i].totalPayout &&
              now >= delayNextTime && bountyPayment[i].reject == false) {
                uint256 payout = bountyPayment[i].amountReserve.div(bountyPayment[i].periodPathOfPay);
                NOUSTokenInterface(tokenAddress).transfer(bountyPayment[i].wallet, payout);
                PayBonuses(bountyPayment[i].wallet, payout);
                // transfer bonuses
                bountyPayment[i].totalPayout = bountyPayment[i].totalPayout.add(payout);
                bountyPayment[i].timeLastPayout = delayNextTime;
            }
        }
    }

    function transferTokens(address _to, uint256 _value) public onlyOwner {
        NOUSTokenInterface(tokenAddress).transfer(_to, _value);
    }

    function kill() public onlyOwner {
        NOUSTokenInterface NST = NOUSTokenInterface(tokenAddress);
        uint256 balance = NST.balanceOf(this);
        NST.transfer(owner, balance);
        selfdestruct(owner);
    }
}
