pragma solidity ^0.4.11;


import "../lib/SafeMath.sol";
import "../base/Ownable.sol";


/**
* @title Bonus for the invited
* @dev Payed bonus * @dev function addAffiliate - added referral link on partner
*/
contract BonusForAffiliate is Ownable {

    using SafeMath for uint256;

    mapping (address => address) private referral;

    struct BonusStruct {
        uint256 amount;
        uint256 time;
        bool payed;
        bool frozen;
    }

    struct PartnerStruct {
        bool blocked;
        uint256 totalPayout;
        uint256 index;
        uint256[] bonusIndexes;            // index
        mapping (uint256 => BonusStruct) bonuses; // if one bonus is default
    }

    // @dev partner wallet address => array bonuses for pay, bonuses for backer
    mapping (address => PartnerStruct) private partners;

    address[] private partnerIndexes; // index for bonuses map

    address public dugSale; // address Nous Sale contract

    // Events
    event PayedBonus(address indexed beneficiary, uint256 weiAmount);

    event RejectBonus(address indexed partner, uint256 amount);

    event AddBonus(address indexed partner, address backer, uint256 amount);

    modifier onlySaleAgent() {
        assert(msg.sender == dugSale);
        _;
    }

    /**
    * @dev return referral address
    * @param _backer Address backer
    */
    function getReferralAddress(address _backer) external constant returns (address) {
        return referral[_backer];
    }

    /**
    * @dev Tie backer and partner
    * @param _backer Address backer
    * @param _partner Address partner wallet
    */
    function addAffiliate(address _backer, address _partner) external onlyOwner returns (bool) {
        require(referral[_backer] == address(0));
        require(_backer != _partner);
        referral[_backer] = _partner;
        return true;
    }

    /**
    * @dev Set dug sale address
    */
    function setDugSale( address _dugSale ) external onlyOwner returns (bool) {
        require(_dugSale != address(0));
        //require(dugSale == address(0));
        dugSale = _dugSale;
        return true;
    }

    /**
    * @dev Block partner
    * @param _partnerWalletAddress Address partner wallet
    */
    function lockUnlockPartner(address _partnerWalletAddress) external onlyOwner {
        require(isPartner(_partnerWalletAddress));
        partners[_partnerWalletAddress].blocked = !partners[_partnerWalletAddress].blocked;
    }

    /**
    * @dev Frozen bonus
    * @param _partnerWalletAddress Address partner wallet
    */
    function frozenBonus(address _partnerWalletAddress, uint256 index, bool status) external onlyOwner {
        require(isPartner(_partnerWalletAddress));
        partners[_partnerWalletAddress].bonuses[index].frozen = status;
    }

    /**
    * @dev Add bonus for backer can only sale contract
    * @param _partnerWalletAddress Address partner wallet
    * @param _backerAddress Address backer account
    */
    function addBonus(address _backerAddress, address _partnerWalletAddress) external onlySaleAgent payable {
        require(_partnerWalletAddress != address(0));
        require(referral[_backerAddress] == _partnerWalletAddress);
        require(msg.value > 0);

        PartnerStruct storage partner = partners[_partnerWalletAddress];

        if (!isPartner(_partnerWalletAddress)) {
            partner.blocked = false;
            partner.index = partnerIndexes.push(_partnerWalletAddress) - 1;
        }

        uint256 item = partner.bonusIndexes.length;
        partner.bonuses[item] = BonusStruct({
            amount: msg.value,
            time: now,
            payed: false,
            frozen: false
        });
        partner.bonusIndexes.push(item);
    }

    /**
    * @dev Get all partner bonuses
    * @return amount [], time [], payed [], frozen []
    */
    function getPartnerBonuses(address _partnerWalletAddress) public constant
    returns(uint256[] memory index, uint256[] memory amount, uint256[] memory time, bool[] memory payed, bool[] memory frozen)
    {
        require(_partnerWalletAddress != address(0));

        PartnerStruct storage partner = partners[_partnerWalletAddress];
        uint256 length = partner.bonusIndexes.length;
        index = new uint256[](length);
        amount = new uint256[](length);
        time = new uint256[](length);
        payed = new bool[](length);
        frozen = new bool[](length);

        for (uint256 i = 0; i < partner.bonusIndexes.length; i++) {
            index[i] = i;
            amount[i] = partner.bonuses[i].amount;
            time[i] = partner.bonuses[i].time;
            payed[i] = partner.bonuses[i].payed;
            frozen[i] = partner.bonuses[i].frozen;
        }
        return (index, amount, time, payed, frozen);
    }

    /**
    * @dev Return partner balance available to payed
    * @param _partnerWalletAddress Address partner wallet
    * @return totalEarned Sum total earned include bonuses payments that did not reach payment by time
    * @return totalDeduced Sum total is deduced
    */
    function getPartnerBalance(address _partnerWalletAddress) public constant
    returns(uint256 totalEarned, uint256 totalDeduced)
    {
        require(isPartner(_partnerWalletAddress));
        //totalEarned = 0;
        //totalDeduced = 0;
        PartnerStruct storage partner = partners[_partnerWalletAddress];
        for (uint256 i = 0; i < partner.bonusIndexes.length; i++) {
            if (partner.bonuses[i].frozen == false) {
                totalEarned = totalEarned + partner.bonuses[i].amount;
                if (partner.bonuses[i].payed == true) {
                    totalDeduced = totalDeduced + partner.bonuses[i].amount;
                }
            }
        }
        return (totalEarned, totalDeduced);
    }

    /**
    * @dev Return partner balance available to payed
    * @param _partnerWalletAddress Address partner wallet
    * @return totalAvailable Sum total available
    */
    function getAvailableBalance(address _partnerWalletAddress) public constant returns (uint256 totalAvailable) {
        require(isPartner(_partnerWalletAddress));
        //totalAvailable = 0;
        PartnerStruct storage partner = partners[_partnerWalletAddress];
        for (uint256 i = 0; i < partner.bonusIndexes.length; i++) {
            if (validateBonusStatusForPay(_partnerWalletAddress, i)) {
                totalAvailable = totalAvailable.add(partner.bonuses[i].amount);
            }
        }
        return totalAvailable;
    }

    /**
    * @dev Pay Bonus
    */
    function payoutBonus() public {
        address partnerWalletAddress = msg.sender;

        require(isPartner(partnerWalletAddress));
        require(partners[partnerWalletAddress].blocked == false);
        require(getAvailableBalance(partnerWalletAddress) > 0);

        PartnerStruct storage partner = partners[partnerWalletAddress];

        for (uint256 i = 0; i < partner.bonusIndexes.length; i++) {
            if (validateBonusStatusForPay(partnerWalletAddress, i)) {
                uint256 _amount = partner.bonuses[i].amount;
                partner.bonuses[i].payed = true;
                partner.totalPayout = partner.totalPayout.add(_amount);
                partnerWalletAddress.transfer(_amount);
                PayedBonus(partnerWalletAddress, _amount);
            }
        }
    }

    /**
    * @dev Returns partner status blocked or
    * @param _partnerWalletAddress Address partner wallet
    */
    function isActivePartner(address _partnerWalletAddress) public constant returns (bool) {
        return isPartner(_partnerWalletAddress) && !partners[_partnerWalletAddress].blocked;
    }

    /**
    * @dev Returns all partners
    * @return partnerWalletAddress[], totalPayout[], blockedStatus[], totalBonuses[]
    */
    function getPartnersPaid() public constant
    returns (address[] memory partnerWalletAddress, uint256[] memory totalPayout, bool[] memory blockedStatus, uint256[] memory totalBonuses)
    {
        uint256 totalPartners = partnerIndexes.length;

        partnerWalletAddress = new address[](totalPartners);
        totalPayout = new uint256[](totalPartners);
        blockedStatus = new bool[](totalPartners);
        totalBonuses = new uint256[](totalPartners);

        for (uint256 i = 0; i < totalPartners; i++) {
            partnerWalletAddress[i] = partnerIndexes[i];
            totalPayout[i] = partners[partnerIndexes[i]].totalPayout;
            blockedStatus[i] = partners[partnerIndexes[i]].blocked;
            totalBonuses[i] = partners[partnerIndexes[i]].bonusIndexes.length;
        }

        return (partnerWalletAddress, totalPayout, blockedStatus, totalBonuses);
    }

    /**
    * @dev validate if partner exists.
    * @param _partnerWalletAddress Address partner wallet
    */
    function isPartner(address _partnerWalletAddress) internal returns (bool) {
        if (partnerIndexes.length == 0) {
            return false;
        }
        return partnerIndexes[partners[_partnerWalletAddress].index] == _partnerWalletAddress;
    }

    // ToDo FOR TEST 3 Minutes
    /**
    * @dev Retuns status bonus
    */
    function validateBonusStatusForPay(address _partnerWalletAddress, uint256 index) internal returns (bool) {
        return partners[_partnerWalletAddress].bonuses[index].frozen == false && partners[_partnerWalletAddress].bonuses[index].payed == false &&
        partners[_partnerWalletAddress].bonuses[index].time + (3 minutes) < now;
    }

}
