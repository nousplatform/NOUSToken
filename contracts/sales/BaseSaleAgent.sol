pragma solidity ^0.4.0;

contract BaseSaleAgent is Ownable {



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
}
