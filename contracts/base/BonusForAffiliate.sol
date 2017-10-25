pragma solidity ^0.4.10;

import '../lib/SafeMath.sol';
import '../base/Ownable.sol';

contract BonusForAffiliate is Ownable {

	using SafeMath for uint256;

	struct PartnerStruct {
		bool blocked;
		uint256 totalPayout;
		uint256 index;
		uint256[] bonusIndexes;			// index
		mapping (uint256 => BonusStruct) bonuses; // if one bonus is default
	}

	struct BonusStruct {
		uint256 amount;
		uint256 time;
		bool payed;
		bool frozen;
	}

	// @dev partner wallet address => array bonuses for pay, bonuses for affiliate
	mapping (address => PartnerStruct) public partners;
	address[] partnerIndexes; // index for bonuses map

	// Events
	event PayedBonus(address indexed beneficiary, uint256 weiAmount);
	event RejectBonus(address indexed partner, uint256 amount);
	event AddBonus(address indexed partner, address affiliate, uint256 amount);


	/**
	* @dev validate if partner exists.
	* @param _partnerWalletAddress Address partner wallet
	*/
	function isPartner(address _partnerWalletAddress) internal returns(bool){
		if ( partnerIndexes.length == 0 ) return false;
		return partnerIndexes[partners[_partnerWalletAddress].index] == _partnerWalletAddress;
	}

	/**
	* @dev Retuns status bonus
	*/
	function validateBonusStatusForPay(address _partnerWalletAddress, uint256 index) internal returns (bool){
		return partners[_partnerWalletAddress].bonuses[index].frozen == false
			&& partners[_partnerWalletAddress].bonuses[index].payed == false
			&& partners[_partnerWalletAddress].bonuses[index].time + (1 days) > now;
	}


    function addAffiliateBonus(address _partnerWalletAddress, address _affiliateAddress) onlyOwner public payable {
		require (_partnerWalletAddress != address(0));
		require (_affiliateAddress != address(0));
		require (msg.value > 0);

		if (!isPartner(_partnerWalletAddress)) {
			PartnerStruct memory partner;
			partner.blocked = false;
			partner.index = partnerIndexes.push(_partnerWalletAddress)-1;
			partners[_partnerWalletAddress] = partner;
		}

		BonusStruct memory bonus;
		bonus.amount = msg.value;
		bonus.time = now;
		bonus.payed = false;
		bonus.frozen = false;

		uint256 _index = partners[_partnerWalletAddress].bonusIndexes.push() - 1;

		partners[_partnerWalletAddress].bonuses[_index] = bonus;
    }

	function getPartnerBonuses(address _partnerWalletAddress) onlyOwner {

	}

	/**
	* @dev Return partner balance available to payed
	* @param _partnerWalletAddress Address partner wallet
	* @return totalAvailable Sum total available
	*/
	function getBalance(address _partnerWalletAddress) public returns (uint256){
		require (isPartner(_partnerWalletAddress));
		uint256 totalAvailable = 0;
		for (uint256 i = 0; i < partners[_partnerWalletAddress].bonusIndexes.length; i++) {
			if (validateBonusStatusForPay(_partnerWalletAddress, i)){
				totalAvailable = totalAvailable.add(partners[_partnerWalletAddress].bonuses[i].amount);
			}
		}
		return totalAvailable;
	}

    /**
    * @dev Pay Bonus
    * @param _partnerWalletAddress Address partner wallet
    */
    function payoutBonus(address _partnerWalletAddress) public {
		require (_partnerWalletAddress != address(0));
		require (isPartner(_partnerWalletAddress));
		require (partners[_partnerWalletAddress].blocked);

		PartnerStruct partner = partners[_partnerWalletAddress];

		for ( uint256 i = 0; i <  partner.bonusIndexes.length; i++ ) {
			if ( validateBonusStatusForPay(_partnerWalletAddress, i) ) {
				uint256 _amount = partner.bonuses[i].amount;
				_partnerWalletAddress.transfer(_amount);
				partners[_partnerWalletAddress].bonuses[i].payed = true;
				partners[_partnerWalletAddress].totalPayout = partners[_partnerWalletAddress].totalPayout.add(_amount);
				PayedBonus(_partnerWalletAddress, _amount);
			}
		}
    }

	/**
	* @dev Block parner
	* @param _partnerWalletAddress Address partner wallet
	*/
	function lockUnlocPartner(address _partnerWalletAddress, bool status) onlyOwner returns(bool){
		if (!isPartner(_partnerWalletAddress)) return false;
		partners[_partnerWalletAddress].blocked = status;
		return true;
	}

	/**
	* @dev Frozen bonus
	* @param _partnerWalletAddress Address partner wallet
	*/
	function frozenBonus(address _partnerWalletAddress, uint256 index, bool status) onlyOwner returns(bool){
		if (!isPartner(_partnerWalletAddress)) return false;
		partners[_partnerWalletAddress].bonuses[index].frozen = status;
		return true;
	}

	/**
	* @dev Get partner status
	* @param _partnerWalletAddress Address partner wallet
	*/
	function getPartnerStaus(address _partnerWalletAddress) returns (bool){
		if (!isPartner(_partnerWalletAddress)) return false;
		return partners[_partnerWalletAddress].blocked;
	}

	/**
	* @dev Returns all partners
	* @return partnerWalletAddress[], totalPayout[], blockedStatus[], totalBonuses[]
	*/
	function getPartnersPayed() onlyOwner constant returns(address[], uint256[], bool[], uint256[]){
		uint256 totalPartners = partnerIndexes.length;

		address[] memory partnerWalletAddress = new address[](totalPartners);
		uint256[] memory totalPayout = new uint256[](totalPartners);
		bool[] memory blockedStatus = new bool[](totalPartners);
		uint256[] memory totalBonuses = new uint256[](totalPartners);

		for (uint256 i = 0; i < totalPartners; i++ ) {
			partnerWalletAddress[i] = partnerIndexes[i];
			totalPayout[i] = partners[partnerIndexes[i]].totalPayout;
			blockedStatus[i] = partners[partnerIndexes[i]].blocked;
			totalBonuses[i] = partners[partnerIndexes[i]].bonuses.length;
		}

		return (partnerWalletAddress, totalPayout, blockedStatus, totalBonuses);
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
