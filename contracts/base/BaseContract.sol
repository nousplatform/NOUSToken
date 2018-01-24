pragma solidity ^0.4.11;


import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/Data.sol";
import "../interfaces/NOUSTokenInterface.sol";

//import "./PaymentBounty.sol";


/**
* @title Base sail contract
* @dev Base implementation logic
*/
contract BaseContract is Ownable {

    /**** Libs ****/
    using SafeMath for uint256;

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    /**** Variables ****/
    NOUSTokenInterface public tokenContract; // The token being sold
    //PaymentBountyInterface public paymentBounty; // The token being sold
    mapping (bytes32 => address) public doug;

    address public refundVaultAddr; // address BonusForAffiliate contract
    address public affiliateAddr; // address BonusForAffiliate contract
    address public bountyAddr; // address PaymentBounty contract

    /**** Properties ****/
    uint256 public totalSupplyCap; // 777 Million tokens Capitalize max count NOUS tokens
    uint256 public availablePurchase; // tokens  Available for purchase
    uint256 public targetEthMax; // The max amount of ether the agent is allowed raise
    uint256 public targetEthMin; // minimum amount of funds to be raised in weis
    uint256 public weiRaised; // amount of raised money in wei
    //uint256 public maxGasPrice; // amount of raised money in wei
    uint256 public percentBonusForAffiliate; // percent for bonus

    /**** Events ****/
    event SaleFinalised(address _agent, uint256 _amountMint, uint256 _weiAmount);
    event TotalOutBounty(address _agent, address _wallet, bytes32 _name, uint256 _totalPayout); // all payed to bonus
    event PayBounty(address _agent, address _wallet, bytes32 _name, uint256 _amount);
    event TokenMinted(address indexed _agent, address indexed beneficiary, uint256 amount);
    event TranslateEther(address indexed _agent, address indexed beneficiary, uint256 value);

    /**** Data ****/
    enum SaleState {Active, Pending, Ended}
    SaleState public saleState;

    mapping (address => Data.SalesAgent) internal salesAgents; // Our contract addresses of our sales contracts
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
        setContracts(_token, _vault, _affiliate, _bounty);
    }

    /**
    *
    */
    function setContracts(
        address _token,
        address _vault,
        address _affiliate,
        address _bounty
    ) public onlyOwner {
        require(_token != 0x0);
        require(_vault != 0x0);
        require(_affiliate != 0x0);
        require(_bounty != 0x0);

        tokenContract = NOUSTokenInterface(_token);
        refundVaultAddr = _vault;
        affiliateAddr = _affiliate;
        bountyAddr = _bounty;
    }

    /**
    * @dev Set the address of a new crowdsale/presale contract agent if needed, usefull for upgrading
    * @dev Only the owner can register a new sale agent
    * @param _saleAddress The address of the new token sale contract
    * @param _saleContractType Type of the contract ie. presale, crowdsale, quarterly
    * @param _tokensLimit The maximum amount of tokens this sale contract is allowed to distribute
    * @param _minDeposit The minimum deposit amount allowed
    * @param _startTime The start block when allowed to mint tokens
    * @param _endTime The end block when to finish minting tokens
    */
    function setSaleAgentContract(
        address _saleAddress,
        Data.SaleContractType _saleContractType,
        uint256 _tokensLimit,
        uint256 _minDeposit,
        //uint256 _maxDeposit,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate
    )
    public onlyOwner
    {
        uint256 _tokensMinted = changeActiveSale(_saleContractType);
        require(saleState != SaleState.Ended); // if Sale state closed do not add sale config
        require(_saleAddress != 0x0); // Valid addresses
        require(_tokensLimit > 0 && _tokensLimit <= totalSupplyCap); // Must have some available tokens
        //require(_minDeposit <= _maxDeposit); // Make sure the min deposit is less than or equal to the max
        require(_endTime > _startTime);

        // Add the new sales contract
        Data.SalesAgent memory newSalesAgent;
        newSalesAgent.saleContractAddress = _saleAddress;
        newSalesAgent.saleContractType = _saleContractType;
        newSalesAgent.tokensLimit = _tokensLimit * EXPONENT;
        newSalesAgent.minDeposit = _minDeposit * 1 ether;
        //newSalesAgent.maxDeposit = _maxDeposit * 1 ether;
        newSalesAgent.startTime = _startTime;
        newSalesAgent.endTime = _endTime;
        newSalesAgent.rate = _rate;
        newSalesAgent.isFinalized = false;
        newSalesAgent.exists = true;
        newSalesAgent.tokensMinted = _tokensMinted;

        //newSalesAgent.bonusRates = new BonusRateStruct[](0); // after sale start global finalize
        salesAgents[_saleAddress] = newSalesAgent;
        // Store our agent address so we can iterate over it if needed
        salesAgentsAddresses.push(_saleAddress);
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
    function getSaleContract(address _saleAgentAddress) public constant
    returns(
        bool memory finalize,
        uint256 memory startTime,
        uint256 memory endTime,
        uint256 memory tokensLimit,
        uint256 memory tokensMinted,
        uint256 memory rate,
        Data.SaleContractType memory contractType
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
