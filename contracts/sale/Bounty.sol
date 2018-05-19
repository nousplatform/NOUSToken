pragma solidity ^0.4.18;


import "./Crowdsale.sol";
import "https://github.com/OpenZeppelin/zeppelin-solidity/contracts/token/ERC20/TokenTimelock.sol";

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
            Allocation storage _curAll = listAllocation[i];
            if (_curAll.beneficiary != 0x0) {
                address _currentRecipient = _curAll.beneficiary;

                if (_curAll.delayDays > 0) {
                    uint _releaseTime = block.timestamp.add(_curAll.delayDays.mul(1 days));
                    _curAll.safeWallet = new TokenTimelock(token, _curAll.beneficiary, _releaseTime);
                    _currentRecipient = _curAll.safeWallet;
                }

                uint _tokenAmount = token.totalSupply().mul(_curAll.percent).div(100);
                _processPurchase(_currentRecipient, _tokenAmount);
                emit BountyPurchase(_curAll.beneficiary, _curAll.safeWallet, _tokenAmount);
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
            _totalPercent += listAllocation[i].percent;
        }

        require(MAXPercentage >= _totalPercent.add(_percent));

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
