pragma solidity ^0.4.18;


import "./Crowdsale.sol";
import "zeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";

/**
* @notice Bounty contract
*/
contract Bounty is Crowdsale {

    using SafeMath for uint256;

    uint public constant MAXPercentage = 50;

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
            if (listAllocation[i].beneficiary != 0x0) {
                address _currentRecipient = listAllocation[i].beneficiary;

                if (listAllocation[i].delayDays > 0) {
                    uint _releaseTime = block.timestamp.add(listAllocation[i].delayDays.mul(1 days));
                    listAllocation[i].safeWallet = new TokenTimelock(token, listAllocation[i].beneficiary, _releaseTime);
                    _currentRecipient = listAllocation[i].safeWallet;
                }

                uint _tokenAmount = token.totalSupply().mul(listAllocation[i].percent).div(100);
                _processPurchase(_currentRecipient, _tokenAmount);
                emit BountyPurchase(listAllocation[i].beneficiary, listAllocation[i].safeWallet, _tokenAmount);
            }
        }
    }

    /**
    * @notice Add bounty
    * @param _beneficiary address
    * @param _delayDays For delay tokens on many days
    * @param _percent Percent for calculate total amount
    */
    function addBounty(address _beneficiary, uint256 _delayDays, uint _percent) public onlyOwner {
        require(_percent > 0);
        uint _totalPercent;

        for (uint i; i < listAllocation.length; i++) {
            _totalPercent.add(listAllocation[i].percent);
        }

        require(MAXPercentage > _totalPercent.add(_percent));

        Allocation memory _allocation;
        _allocation.beneficiary = _beneficiary;
        _allocation.delayDays = _delayDays;
        _allocation.percent = _percent;
        listAllocation.push(_allocation);
    }

    function release() public {
        for (uint i; i < listAllocation.length; i++) {
            if (listAllocation[i].safeWallet != 0x0) {
                TokenTimelock(listAllocation[i].safeWallet).release();
            }
        }
    }

}
