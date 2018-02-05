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

    address public wallet;

    State public state;

    event Closed();

    event RefundsEnabled();

    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) {
        require(_wallet != 0x0);
        wallet = _wallet;
        state = State.Active;
    }

    //TODO: set wallet is dangerous function
    /*function setWallet(address _wallet) public onlyOwner {
        require(_wallet != 0x0);
        wallet = _wallet;
    }*/

    function setState(State _state) public onlyOwner {
        state = _state;
    }

    function deposit(address investor) public onlySaleAgent payable {
        require(msg.value > 0);
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    // @dev stop sale? taransfer ether to wallet
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

    function refundSaleAgent(address investor) public onlySaleAgent returns (uint256) {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        Refunded(investor, depositedValue);
        return depositedValue;
    }

    //TODO: only integer
    function withdrawOnly(uint256 _amount) public onlyOwner {
        require(_amount > 0);
        uint256 amount = _amount * 1 ether;
        assert(this.balance > amount);
        wallet.transfer(amount);
    }

    function kill() public onlyOwner {
        selfdestruct(owner);
    }
}
