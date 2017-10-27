pragma solidity ^0.4.11;


import "../lib/SafeMath.sol";
import "../base/Ownable.sol";


/**
* @title Bonus for the invited
* @dev Payed bonus
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

    // @dev partner wallet address => array bonuses for pay, bonuses for affiliate
    mapping (address => PartnerStruct) public partners;

    address[] private partnerIndexes; // index for bonuses map

    address private dugSale; // address Nous Sale contract

    // Events
    event PayedBonus(address indexed beneficiary, uint256 weiAmount);

    event RejectBonus(address indexed partner, uint256 amount);

    event AddBonus(address indexed partner, address affiliate, uint256 amount);

    modifier onlySaleAgent() {
        assert(msg.sender == dugSale);
        _;
    }

    /**
    * @dev return referral address
    * @param _affiliate Address affiliate
    */
    function getReferralAddress(address _affiliate) external constant returns (address) {
        return referral[_affiliate];
    }

    /**
    * @dev Tie affiliate and partner
    * @param _affiliate Address affiliate
    * @param _partner Address partner wallet
    */
    function addAffiliate(address _affiliate, address _partner) external onlyOwner returns (bool) {
        require(referral[_affiliate] == address(0));
        referral[_affiliate] = _partner;
        return true;
    }

    /**
    * @dev Set dug sale address
    */
    function setDugSale( address _dugSale ) external onlyOwner returns (bool) {
        require(_dugSale != address(0));
        require(dugSale == address(0));
        dugSale = _dugSale;
        return true;
    }

    /**
    * @dev Add bonus for affiliate
    * @param _partnerWalletAddress Address partner wallet
    * @param _affiliateAddress Address affiliate account
    */
    function addBonus(address _affiliateAddress, address _partnerWalletAddress) public onlySaleAgent payable {
        require(_partnerWalletAddress != address(0));
        require(referral[_affiliateAddress] == _partnerWalletAddress);
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
    function getPartnerBonuses(address _partnerWalletAddress) public constant onlyOwner
    returns(uint256[], uint256[], bool[], bool[]) {
        require(_partnerWalletAddress != address(0));
        
        PartnerStruct storage partner = partners[_partnerWalletAddress];
        uint256 length = partner.bonusIndexes.length;
        uint256[] memory amount = new uint256[](length);
        uint256[] memory time = new uint256[](length);
        bool[] memory payed = new bool[](length);
        bool[] memory frozen = new bool[](length);
       
        for (uint256 i = 0; i < partner.bonusIndexes.length; i++) {
            amount[i] = partner.bonuses[i].amount;
            time[i] = partner.bonuses[i].time;
            payed[i] = partner.bonuses[i].payed;
            frozen[i] = partner.bonuses[i].frozen;
        }
        return (amount, time, payed, frozen);
    }

    /**
    * @dev Return partner balance available to payed
    * @param _partnerWalletAddress Address partner wallet
    * @return totalAvailable Sum total available
    */
    function getAvailableBalance(address _partnerWalletAddress) public constant returns (uint256) {
        require(isPartner(_partnerWalletAddress));
        uint256 totalAvailable = 0;
        PartnerStruct storage partner = partners[_partnerWalletAddress];
        for (uint256 i = 0; i < partner.bonusIndexes.length; i++) {
            if (validateBonusStatusForPay(_partnerWalletAddress, i)) {
                totalAvailable = totalAvailable.add(partner.bonuses[i].amount);
            }
        }
        return totalAvailable;
    }

    /**
    * @dev Pay Bonus * @param partnerWalletAddress Address partner wallet
    */
    function payoutBonus() public {
        address partnerWalletAddress = msg.sender;

        require(partnerWalletAddress != address(0));
        require(getAvailableBalance(partnerWalletAddress) > 0);
        require(isPartner(partnerWalletAddress));
        require(partners[partnerWalletAddress].blocked);

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
    * @dev Block partner
    * @param _partnerWalletAddress Address partner wallet
    */
    function lockUnlockPartner(address _partnerWalletAddress, bool status) public onlyOwner {
        require(isPartner(_partnerWalletAddress));
        partners[_partnerWalletAddress].blocked = status;
    }

    /**
    * @dev Frozen bonus
    * @param _partnerWalletAddress Address partner wallet
    */
    function frozenBonus(address _partnerWalletAddress, uint256 index, bool status) public onlyOwner {
        require(isPartner(_partnerWalletAddress));
        partners[_partnerWalletAddress].bonuses[index].frozen = status;
    }

    /**
    * @dev Returns partner status blocked or
    * @param _partnerWalletAddress Address partner wallet
    */
    function isActivePartner(address _partnerWalletAddress) public constant returns (bool) {
        require(isPartner(_partnerWalletAddress));
        return !partners[_partnerWalletAddress].blocked;
    }

    /**
    * @dev Returns all partners
    * @return partnerWalletAddress[], totalPayout[], blockedStatus[], totalBonuses[]
    */
    function getPartnersPayed() public onlyOwner constant returns (address[], uint256[], bool[], uint256[]) {
        uint256 totalPartners = partnerIndexes.length;

        address[] memory partnerWalletAddress = new address[](totalPartners);
        uint256[] memory totalPayout = new uint256[](totalPartners);
        bool[] memory blockedStatus = new bool[](totalPartners);
        uint256[] memory totalBonuses = new uint256[](totalPartners);

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

    /**
    * @dev Retuns status bonus
    */
    function validateBonusStatusForPay(address _partnerWalletAddress, uint256 index) internal returns (bool) {
        assert(isPartner(_partnerWalletAddress));
        PartnerStruct storage partner = partners[_partnerWalletAddress];
        return partner.bonuses[index].frozen == false &&
            partner.bonuses[index].payed == false &&
            partner.bonuses[index].time + (3 minutes) > now;
    }

    /**
    * @dev validate affilate bonus exists in parner list
    * @params _partnerWalletAddress Asddress partner wallet
    * @params _affiliateAddress Asddress affiliate
    */
    /*function isAffilateBonus(address _partnerWalletAddress, address _affiliateAddress) internal returns(bool){
        if (!isPartner(_partnerWalletAddress)) return false;

        PartnerStruct _partner = partners[_partnerWalletAddress];

        if (_partner.bonusIndexes.length == 0) return false;
        return _partner.bonusIndexes[_partner.bonuses[_affiliateAddress].bonusIndex] == _affiliateAddress;
    }*/


}
