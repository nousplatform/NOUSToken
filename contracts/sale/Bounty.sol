pragma solidity ^0.4.18;


import "./Crowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";


contract Bounty is Crowdsale {

    using SafeMath for uint256;

    struct Allocation {
        address beneficiary;
        uint delayDays; //in days
        uint percent;
        address safeWallet;
    }

    Allocation[] public listAllocation;

    event BountyPurchase(address indexed beneficiary, address safe, uint tokenAmount);

    function finalization() internal {
        reserveBounty();
        super.finalization();
    }

    function reserveBounty() internal {
        for (uint i; i < listAllocation.length; i++) {
            uint _releaseTime = block.timestamp.add(listAllocation[i].delayDays.mul(1 days));
            address _safe = new TokenTimelock(token, listAllocation[i].beneficiary, _releaseTime);
            uint _tokenAmount = token.totalSupply().mul(listAllocation[i].percent).div(100);
            _processPurchase(_safe, _tokenAmount);
            emit BountyPurchase(listAllocation[i].beneficiary, _safe, _tokenAmount);
        }
    }

    function addBounty(address _beneficiary, uint _delayDays, uint _percent) public onlyOwner {
        Allocation storage _allocation;
        _allocation.beneficiary = _beneficiary;
        _allocation.delayDays = _delayDays;
        _allocation.percent = _percent;
        listAllocation.push(_allocation);
    }

    function release() public {
        for (uint i; i < listAllocation.length; i++) {
            TokenTimelock(listAllocation[i].safeWallet).release();
        }
    }

}
