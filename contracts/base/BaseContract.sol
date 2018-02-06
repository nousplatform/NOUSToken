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

    /**** Events ****/
    event SaleFinalised(address _agent, uint256 _tockenMint, uint256 _weiAmount);
    event TotalOutBounty(address _agent, address _wallet, bytes32 _name, uint256 _totalPayout); // all payed to bonus
    event PayBounty(address _agent, address _wallet, bytes32 _name, uint256 _amount);
    event TokenMinted(address indexed _agent, address indexed beneficiary, uint256 amount);
    event TranslateEther(address indexed _agent, address indexed beneficiary, uint256 value);

    /**** Data ****/
    enum SaleState {Active, Pending, Ended}
    SaleState public globalSaleState;

    struct SaleAgent {
        SaleState state; // state sale contract
        bool exists; // Check to see if the mapping exists
    }

    mapping (address => SaleAgent) internal salesAgents; // Our contract addresses of our sales contracts
    address[] internal salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration

    /**** Modifier ***********/
    /// @dev Only allow access from the latest version of a sales contract
    modifier isSalesContract(address _sender) {
        require(salesAgents[_sender].exists == true);
        _;
    }

    //**** Constructors ******************//
    /// @dev constructor
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

        setDougContracts('nous_token', _token);
        setDougContracts('refund_vault', _vault);
        setDougContracts('bonus_for_affiliate', _affiliate);
        setDougContracts('payment_bounty', _bounty);
    }

    function setDougContracts(byres32 _name, address _address) public onlyOwner {
        Doug[_name] = _address;
    }

    function setPercentBonusForAffiliate(uint256 _newPercent) onlyOwner {
        require(_newPercent > 0);
        require(_newPercent < 100);
        percentBonusForAffiliate = _newPercent;
    }



    // validate goal
    function goalReached() public constant returns (bool) {
        return weiRaised > targetEthMin;
    }

    /**
    * @dev Find stop sale
    */
    function setSaleState(SaleState _state) public onlyOwner {
        saleState = _state;
    }

    /**
    * @dev Find sames type active sales, and diactivate
    */
    function changeActiveSale(Data.SaleContractType _saleContractType) internal returns (uint256) {
        for (uint256 i = 0; i < salesAgentsAddresses.length; i++) {
            if (salesAgents[salesAgentsAddresses[i]].saleContractType == _saleContractType && salesAgents[salesAgentsAddresses[i]].isFinalized == false) {
                salesAgents[salesAgentsAddresses[i]].isFinalized = true;
                return salesAgents[salesAgentsAddresses[i]].tokensMinted;
            }
        }
        return 0;
    }

    /**
    * @dev Returns all information on sale contract
    */
    function getSaleContract(address _salesAgentAddress) public constant
    returns(
        bool finalize,
        uint256 startTime,
        uint256 endTime,
        uint256 tokensLimit,
        uint256 tokensMinted,
        uint256 rate,
        uint256 minDeposit,
        Data.SaleContractType contractType
    ) {
        finalize = salesAgents[_salesAgentAddress].isFinalized;
        startTime = salesAgents[_salesAgentAddress].startTime;
        endTime = salesAgents[_salesAgentAddress].endTime;
        tokensLimit = salesAgents[_salesAgentAddress].tokensLimit;
        tokensMinted = salesAgents[_salesAgentAddress].tokensMinted;
        rate = salesAgents[_salesAgentAddress].rate;
        minDeposit = salesAgents[_salesAgentAddress].minDeposit;
        contractType = salesAgents[_salesAgentAddress].contractType;

        return (finalize, startTime, endTime, tokensLimit, tokensMinted, rate, minDeposit);
    }

}
