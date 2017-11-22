pragma solidity ^0.4.11;


import "../lib/SafeMath.sol";
import "../base/Ownable.sol";


/**
 * @title RefundVault
 * @dev This contract is used for storing funds while a crowdsale
 * is in progress. Supports refunding the money if crowdsale fails,
 * and forwarding it if crowdsale is successful.
 */
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State {Active, Refunding, Closed}

    mapping (address => uint256) public deposited;

    address private dugSale; // address Nous Sale contract

    address public wallet;

    State public state;

    event Closed();

    event RefundsEnabled();

    event Refunded(address indexed beneficiary, uint256 weiAmount);

    modifier onlySaleAgent() {
        assert(msg.sender == dugSale);
        _;
    }

    function setDugSale( address _dugSale ) external onlyOwner returns (bool) {
        require(_dugSale != address(0));
        //require(dugSale == address(0));
        dugSale = _dugSale;
        return true;
    }

    function RefundVault(address _wallet) {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) public onlySaleAgent payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() public onlyOwner {
        require(state == State.Active);
        state = State.Closed;
        Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() public onlyOwner {
        require(state == State.Active);
        state = State.Refunding;
        RefundsEnabled();
    }

    function refund(address investor) public returns (uint256) {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
        return depositedValue;
    }

    function balance() external returns (uint256){
        return this.balance / 1 ether;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        uint256 amount = _amount * 1 ether;
        require(this.balance > amount);
        wallet.transfer(amount);
    }
}
