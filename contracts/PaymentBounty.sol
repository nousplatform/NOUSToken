pragma solidity ^0.4.18;


import "./base/Ownable.sol";
import "./interfaces/TokenInterface.sol";
import "./lib/SafeMath.sol";


contract PaymentBounty is Ownable {

    using SafeMath for uint256;

    address public tokenAddress;

    //uint256 delay = 1800; // 1800 hours => 30 dey to period pay

    event PayBonuses(address wallet, uint256 tokens);

    struct Bounty {
        address wallet; // wallet address for transfer
        string name; // name bonus
        uint256 delay; // delay to payment in month
        uint256 percent; // percent payed
        uint256 periodPathOfPay; // on how many equal parts to pay
        uint256 amountReserve; // amount acured
        uint256 totalPayout; // how is payed
        uint256 timeLastPayout; // how is payed
        bool reject;
    }

    Bounty[] public bountyPayment; // array bonuses

    function PaymentBounty(address _tokenAddress) Ownable() {
        setTokenAddress(_tokenAddress);
    }

    function setTokenAddress(address _tokenAddress) public onlyOwner {
        require(_tokenAddress != 0x0);
        tokenAddress = _tokenAddress;
    }

    /**
    * @dev Change delay for period pay bonuses
    * @param _delay
    */
    function setDelayBonuses(uint256 _delay) public onlyOwner {
        delay = _delay;
    }

    /**
    * @notice Function set config for reserve and transfer tokens
    * @param _walletAddress Address account for transfer
    * @param _name Name baunty
    * @param _percent Percent reserved bonuses from token totalSupplay
    * @param _delay Delay time in hour for start transfer
    * @param _periodPathOfPay Into how many equal parts to divide
    */
    function setPaymentBounty(
        address _walletAddress,
        string _name,
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

    /**
    * @notice Function reject bonuses
    * @param _index Bonus index
    */
    function rejectBonus(uint256 _index) public onlyOwner {
        bountyPayment[_index].reject = true;
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


    /**
    * @notice All account can call this function, end start
    * @param _startTime Start bonuses payed bonuses
    */
    function payDelayBonuses(uint256 _startTime) public {
        require(_startTime < now);

        TokenInterface Token = TokenInterface(tokenAddress);
        require(Token.bal()

        uint256 delayNextTime = 0;

        for (uint256 i = 0; i < bountyPayment.length; i++) {
            uint256 dateDelay = _startTime;

            // calculate date delay  1 month = 30 dey
            dateDelay = dateDelay + (bountyPayment[i].delay * 1 hours); //delay bonuses

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
                TokenInterface(tokenAddress).transfer(bountyPayment[i].wallet, payout);
                PayBonuses(bountyPayment[i].wallet, payout);
                // transfer bonuses
                bountyPayment[i].totalPayout = bountyPayment[i].totalPayout.add(payout);
                bountyPayment[i].timeLastPayout = delayNextTime;
            }
        }
    }

    /**
    * @notice Transfer token is this reserved to another address
    * @param _to Address to transfer token
    * @param _value
    */
    function transferTokens(address _to, uint256 _value) public onlyOwner {
        TokenInterface(tokenAddress).transfer(_to, _value);
    }

    /**
    * @notice Kill this contract and all reserved tokens transfer on owner address
    */
    function kill() external onlyOwner {
        TokenInterface Token = TokenInterface(tokenAddress);
        uint256 balance = Token.balanceOf(this);
        Token.transfer(owner, balance);
        selfdestruct(owner);
    }
}
