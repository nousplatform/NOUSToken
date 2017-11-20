pragma solidity ^0.4.0;


import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/Data.sol";


contract SaleAgent is Ownable {

    using SafeMath for uint256;

    mapping (address => SalesAgent) private salesAgents; // Our contract addresses of our sales contracts
    address[] internal salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    address saleProvider;


    /// @dev Only allow access from the latest version of a sales contract
    modifier isSalesContract(address _sender) {
        assert(salesAgents[_sender].exists == true); // Is this an authorised sale contract?
        _;
    }

    /// @dev Only sale provider
    modifier onlySaleProvider() {
        assert(saleProvider == msg.sender); // Is this an authorised sale contract?
        _;
    }

    // These are contract addresses that are authorised to mint tokens
    struct SalesAgent {
        address saleContractAddress; // Address of the contract
        Data.SaleContractType saleContractType; // Type of the contract ie. presale, crowdsale, reserve_funds
        uint256 tokensLimit; // The maximum amount of tokens this sale contract is allowed to distribute
        uint256 tokensMinted; // The current amount of tokens minted by this agent
        uint256 rate; // default rate
        uint256 minDeposit; // The minimum deposit amount allowed
        uint256 maxDeposit; // The maximum deposit amount allowed
        uint256 startTime; // The start time (unix format) when allowed to mint tokens
        uint256 endTime; // The end time from unix format when to finish minting tokens
        bool isFinalized; // Has this sales contract been completed and the ether sent to the deposit address?
        bool exists; // Check to see if the mapping exists
    }


    function setSaleProvider(address _saleProvider){
        require(saleProvider == 0x0);
        require(_saleProvider != 0x0);
        saleProvider = _saleProvider;
    }

    //**** Setters ****//
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
        //require(saleState != SaleState.Ended); // if Sale state closed do not add sale config
        require(_saleAddress != 0x0); // Valid addresses
        require(_tokensLimit > 0); // && _tokensLimit <= totalSupplyCap Must have some available tokens
        require(_minDeposit <= _maxDeposit); // Make sure the min deposit is less than or equal to the max
        require(_endTime > _startTime);
        //require(_startTime >= now);

        // Add the new sales contract
        SalesAgent memory newSalesAgent;
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

    function addTokensMinted(address _salesAgentAddress, uint256 tokens) isSalesContract(_salesAgentAddress) onlySaleProvider returns (bool) {
        salesAgents[_salesAgentAddress].tokensMinted = salesAgents[_salesAgentAddress].tokensMinted.add(tokens);
        return true;
    }

    function setFinalize(address _salesAgentAddress) isSalesContract(_salesAgentAddress) onlySaleProvider returns (bool) {
        salesAgents[_salesAgentAddress].isFinalized = true;
        return true;
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

    /// @dev
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractExists(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (bool) {
        return salesAgents[_salesAgentAddress].exists;
    }

    /// @dev
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractContractType(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns (Data.SaleContractType) {
        return salesAgents[_salesAgentAddress].saleContractType;
    }



    /*function isActiveSalesAgent(address _sender) external returns (bool) {
        return salesAgents[_sender].exists == true &&
            salesAgents[_sender].isFinalized == false;
    }*/

}
