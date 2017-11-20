pragma solidity ^0.4.11;


import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/Data.sol";
import "../token/MintableToken.sol";
import "../NOUSToken.sol";
import "./RefundVault.sol";
import "./SaleAgent.sol";


/**
* @title Base sail contract
* @dev Base implementation logic
*/
contract BaseContract is Ownable {

    /**** Libs ****/
    using SafeMath for uint256;

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    /**** Variables ****/
    MintableToken public tokenContract; // The token being sold
    SaleAgent public saleAgentContract; // The token being sold
    //RefundVault public vaultContract; // contract refunded value

    //address public mintableTokenAddr; // address BonusForAffiliate contract
    address public refundVaultAddr; // address BonusForAffiliate contract
    address public affiliateAddr; // address BonusForAffiliate contract

    /**** Properties ****/
    uint256 public totalSupplyCap; // 777 Million tokens Capitalize max count NOUS tokens
    uint256 public availablePurchase; // 543 900 000 tokens  Available for purchase
    uint256 public targetEthMax; // The max amount of ether the agent is allowed raise
    uint256 public targetEthMin; // minimum amount of funds to be raised in weis
    uint256 public weiRaised; // amount of raised money in wei
    uint256 public maxGasPrice; // amount of raised money in wei
    uint256 public percentBonusForAffiliate; // percent for bonus

    /**** Events ****/
    event SaleFinalised(address _agent, address _address, uint256 _amountMint);
    event TotalOutBounty(address _agent, address _wallet, bytes32 _name, uint256 _totalPayout); // all payed to bonus
    event PayBounty(address _agent, address _wallet, bytes32 _name, uint256 _amount);

    /**** Data ****/
    enum SaleState {Active, Pending, Ended}
    SaleState public saleState;

    Data.Bounty[] public bountyPayment; // array bonuses


    /**** Modifier ***********/
    /// @dev Only allow access from the latest version of a sales contract
    modifier isSalesContract(address _sender) {
        assert(saleAgentContract.getSaleContractExists(_sender) == true); // Is this an authorised sale contract?
        _;
    }


    //**** Constructors ******************//
    /// @dev constructor
    function BaseContract(
        address _saleAgent,
        address _token,
        address _vault,
        address _affiliate
    ) {
        if (address(saleAgentContract) == 0x0) {
            saleAgentContract = SaleAgent(_saleAgent);
        }

        if (address(tokenContract) == 0x0) {
            tokenContract = MintableToken(_token);
        }

        if (refundVaultAddr == 0x0) {
            refundVaultAddr = _vault;
        }

        if (affiliateAddr == 0x0) {
            affiliateAddr = _affiliate;
        }
    }


    /// @dev add bounty initial state
    function setPaymentBounty(
        address _walletAddress,
        bytes32 _name,
        uint256 _percent,
        uint256 _delay,
        uint256 _periodPathOfPay
    )
    internal
    {
        assert(_walletAddress != 0x0);
        Data.Bounty memory newBounty;
        newBounty.wallet = _walletAddress;
        newBounty.name = _name;
        newBounty.percent = _percent;
        newBounty.delay = _delay;
        newBounty.periodPathOfPay = _periodPathOfPay;
        newBounty.amountReserve = 0;
        newBounty.totalPayout = 0;
        bountyPayment.push(newBounty);
    }

    //****************Refund*******************//

    // validate goal
    function goalReached() public constant returns (bool) {
        return weiRaised > targetEthMin;
    }

    // if crowdsale is unsuccessful, investors can claim refunds here
    function claimRefund(address beneficiary) isSalesContract(msg.sender) public returns (uint256) {
        require(saleState == SaleState.Ended);
        // refund started only closed contract
        require(!goalReached());

        //token. TODO get token
        RefundVault vaultContract = RefundVault(refundVaultAddr);
        return vaultContract.refund(beneficiary);
    }

    /*** Management *******************/
    /**
    * @dev Find stop sale
    */
    function pendingActiveSale() onlyOwner {
        require(saleState != SaleState.Ended);
        if (saleState == SaleState.Pending) {
            saleState = SaleState.Active;
        } else {
            saleState = SaleState.Pending;
        }
    }

    /**
    * @dev warning Change owner token contact
    */
    function changeTokenOwner(address newOwner) onlyOwner {
        tokenContract.transferOwnership(newOwner);
    }




}
