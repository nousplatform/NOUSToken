pragma solidity ^0.4.4;

contract CrowdSaleInterface {
    function buyTokens(address _beneficiary, uint256 _rate) external payable;
    function tokenMint(address _beneficiary, uint256 _tokens) public;
    function finalizeICO() external;
    function payDelayBonuses(uint256 _startTime) external;
    function finalizeSale() external;
}
