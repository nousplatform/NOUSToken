pragma solidity ^0.4.11;


import "../base/Ownable.sol";
import "../lib/SafeMath.sol";
import "../lib/Data.sol";
import "../token/MintableToken.sol";
import "../NOUSToken.sol";
import "./RefundVault.sol";


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
    mapping (address => Data.SalesAgent) internal salesAgents; // Our contract addresses of our sales contracts
    address[] internal salesAgentsAddresses; // Keep an array of all our sales agent addresses for iteration

    /**** Modifier ***********/
    /// @dev Only allow access from the latest version of a sales contract
    modifier isSalesContract(address _sender) {
        assert(salesAgents[_sender].exists == true); // Is this an authorised sale contract?
        _;
    }

    modifier ownerOrSale() {
        assert(salesAgents[msg.sender].exists == true || msg.sender == owner);
        _;
    }

    /*function isActiveSalesAgent(address _sender) external returns (bool) {
        return salesAgents[_sender].exists == true &&
            salesAgents[_sender].isFinalized == false;
    }*/

    //**** Constructors ******************//
    /// @dev constructor
    function BaseContract(
        address _token,
        address _vault,
        address _affiliate
    ) {
        if (address(tokenContract) == 0x0) {
            tokenContract = MintableToken(_token);
            //mintableTokenAddr = _token;
        }

        if (refundVaultAddr == 0x0) {
            //vaultContract = RefundVault(_vault);
            refundVaultAddr = _vault;
        }

        if (affiliateAddr == 0x0) {
            affiliateAddr = _affiliate;
        }
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
    * @dev warning Change owner token contact
    */
    function changeTokenOwner(address newOwner) onlyOwner {
        tokenContract.transferOwnership(newOwner);
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

    /// @dev Returns the min target amount of ether the contract wants to raise
    /*function getTargetEtherMin() constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return targetEthMin;
    }*/

    /// @dev Returns the max target amount of ether the contract can raise
    /// @param _salesAgentAddress The address of the token sale agent contract
    /*function getTargetEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return targetEthMax;
    }*/

}
