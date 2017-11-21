pragma solidity ^0.4.0;


contract BonusForAffiliateInterface {

    function addBonus(address _backerAddress, address _partnerWalletAddress) public payable;

    function getReferralAddress(address _backer) external returns (address);

}
