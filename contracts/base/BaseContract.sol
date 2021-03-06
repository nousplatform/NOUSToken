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

    address public refundVaultAddr; // address BonusForAffiliate contract
    address public affiliateAddr; // address BonusForAffiliate contract
    address public bountyAddr; // address PaymentBounty contract

    /**** Properties ****/
    uint256 public totalSupplyCap; // 777 Million tokens Capitalize max count NOUS tokens
    uint256 public availablePurchase; // tokens  Available for purchase
    uint256 public targetEthMax; // The max amount of ether the agent is allowed raise
    uint256 public targetEthMin; // minimum amount of funds to be raised in weis
    uint256 public weiRaised; // amount of raised money in wei
    uint256 public maxGasPrice; // amount of raised money in wei
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
        assert(salesAgents[_sender].exists == true); // Is this an authorised sale contract?
        //assert(salesAgents[_sender].isFinalized == false);
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
        if (address(tokenContract) == 0x0) {
            tokenContract = NOUSTokenInterface(_token);
        }

        if (refundVaultAddr == 0x0) {
            refundVaultAddr = _vault;
        }

        if (affiliateAddr == 0x0) {
            affiliateAddr = _affiliate;
        }

        if (bountyAddr == 0x0) {
            bountyAddr = _bounty;
        }
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
        uint256 _maxDeposit,
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
        require(_minDeposit <= _maxDeposit); // Make sure the min deposit is less than or equal to the max
        require(_endTime > _startTime);
        //require(_startTime >= now);

        // Add the new sales contract
        Data.SalesAgent memory newSalesAgent;
        newSalesAgent.saleContractAddress = _saleAddress;
        newSalesAgent.saleContractType = _saleContractType;
        newSalesAgent.tokensLimit = _tokensLimit * EXPONENT;
        newSalesAgent.tokensMinted = 0;
        newSalesAgent.minDeposit = _minDeposit * 1 ether;
        newSalesAgent.maxDeposit = _maxDeposit * 1 ether;
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
    function pendingActiveSale() onlyOwner {
        require(saleState != SaleState.Ended);
        if (saleState == SaleState.Pending) {
            saleState = SaleState.Active;
        } else {
            saleState = SaleState.Pending;
        }
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

    /**** Getters ****/
    /// @dev Returns true if this sales contract has finalised
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractIsFinalised(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (bool) {
        return salesAgents[_salesAgentAddress].isFinalized;
    }

    /// @dev Returns the start block for the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractStartTime(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].startTime;
    }

    /// @dev Returns the start block for the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractEndTime(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].endTime;
    }

    /// @dev Returns the max tokens for the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTokensLimit(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].tokensLimit;
    }

    /// @dev Returns the token total currently minted by the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTokensMinted(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].tokensMinted;
    }

    /// @dev Returns the token total currently minted by the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTokensRate(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].rate;
    }

    /// @dev Returns the token total currently minted by the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractMinDeposit(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].minDeposit;
    }

    /// @dev Returns the token total currently minted by the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractMaxDeposit(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (uint256) {
        return salesAgents[_salesAgentAddress].maxDeposit;
    }

    function getTokenTotalSupply() returns (uint256) {
        return tokenContract.totalSupply();
    }

}
