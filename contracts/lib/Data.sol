pragma solidity ^0.4.11;


library Data {

    enum SaleContractType {Presale, Crowdsale, ReserveFunds}

    // These are contract addresses that are authorised to mint tokens
    struct SalesAgent {
        address saleContractAddress; // Address of the contract
        SaleContractType saleContractType; // Type of the contract ie. presale, crowdsale, reserve_funds
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

    struct Bounty {
        address wallet; // wallet address for transfer
        bytes32 name; // name bonus
        uint256 delay; // delay to payment in month
        uint256 percent; // percent payed
        uint256 periodPathOfPay; // on how many equal parts to pay
        uint256 amountReserve; // amount acured
        uint256 totalPayout; // how is payed
        uint256 timeLastPayout; // how is payed
    }
}
