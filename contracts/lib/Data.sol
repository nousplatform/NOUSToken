pragma solidity ^0.4.11;


library Data {


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
