pragma solidity ^0.4.11;


import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/Data.sol";
import "../interfaces/NOUSTokenInterface.sol";


/**
* @title Base sail contract
* @dev Base implementation logic
*/
contract BaseContract is Ownable {

    /**** Libs ****/
    using SafeMath for uint256;

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    mapping (bytes32 => address) public Doug;

    /**** Properties ****/
    uint256 public constant TOTAL_SUPPLY_CAP = 777 * (10 ** 6) * EXPONENT; // 777 Million tokens Capitalize max count NOUS tokens
    uint256 public constant AVAILABLE_PURCHASE = 543900000 * EXPONENT; // эта нигде не используется!!
    uint256 public constant TARGET_ETH_MAX = 54000 * (1 ether); // maximum amount of funds to be raised in weis
    uint256 public constant TARGET_ETH_MIN = 3500  * (1 ether); // minimum amount of funds to be raised in weis

    uint256 public weiRaised; // amount of raised money in wei
    uint256 public percentBonusForAffiliate; // percent for bonus
    uint256 public startTimeBonusPay;

    /**** Events ****/
    event BuyingTokens(address indexed agent, address indexed beneficiary, uint256 weiAmount);
    event TokenMinted(address indexed agent, address indexed beneficiary, uint256 tokens);

    event SaleFinalised(address _agent, uint256 _tockenMint, uint256 _weiAmount);
    event TotalOutBounty(address _agent, address _wallet, bytes32 _name, uint256 _totalPayout); // all payed to bonus
    event PayBounty(address _agent, address _wallet, bytes32 _name, uint256 _amount);


    /**** Data ****/
    enum saleState {Active, Pending, Ended}
    saleState public totalSaleState;

    struct SaleAgent {
        string desc; //name internal name
        bool exists; // Check to see if the mapping exists
    }

    mapping (address => SaleAgent) internal salesAgents; // Our contract addresses of our sales contracts
    address[] internal salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration

    //@dev Validate sale agent contract
    modifier validateSaleAgent(address _sender) {
        require(salesAgents[_sender].exists == true);
        require(salesAgents[_sender].state == saleState.Active);
        _;
    }

    //@dev constructor
    //@param _token NOUSToken address contract
    //@param _vault RefundVault address contract
    //@param _affiliate BonusForAffiliate address contract
    //@param _bounty PaymentBounty address contract ????????
    function BaseContract(
        address _token,
        address _vault,
        address _affiliate,
        address _bounty
    ) {
        require(_token != 0x0);
        require(_vault != 0x0);
        require(_affiliate != 0x0);
        require(_bounty != 0x0);

        addContract("nous_token", _token);
        addContract("refund_vault", _vault);
        addContract("bonus_for_affiliate", _affiliate);
        addContract("payment_bounty", _bounty);
    }

    //@notice Update or add auxiliary contract
    //param _name Name contract ('nous_token', 'refund_vault', 'bonus_for_affiliate', 'payment_bounty')
    //param _address Contract address
    function addContract(byres32 _name, address _address) public onlyOwner {
        Doug[_name] = _address;
    }

    //@notice Add sale agent
    //@param _saleAgent Address sale contract
    //@param _desc Internal description on sale contract
    function addSaleAgent(address _saleAgent, string _desc) external onlyOwner {
        SaleAgent memory _newSalesAgent;
        _newSalesAgent.desc = _desc;
        _newSalesAgent.exists = true;

        salesAgents[_saleAgent] = _newSalesAgent;
        salesAgentsAddresses.push(_saleAgent);
    }

    //@notice Set percent bonus for affiliate
    //@param _newPercent Update new percent
    function changePercentBonusForAffiliate(uint256 _newPercent) external onlyOwner {
        require(_newPercent > 0);
        require(_newPercent < 100);
        percentBonusForAffiliate = _newPercent;
    }

    //@notice Change sale state {Active, Pending, Ended}
    //@param _state enum {0 - Active, 1 - Pending, 2- Ended}
    function changeSaleState(saleState _state) external onlyOwner {
        totalSaleState = _state;
    }

}
