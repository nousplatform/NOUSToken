pragma solidity ^0.4.11;


import "./StandardToken.sol";
import "../base/Ownable.sol";


/**
* @title Mintable token
* @dev Simple ERC20 Token example, with mintable token creation
* @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
* Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
*/
contract MintableToken is StandardToken, Ownable {

    event Mint(address indexed to, uint256 amount);

    event MintFinished(uint256);

    //@dev address Nous Sale contract
    address dugSale;

    //@dev The variable determines permission to mintable tokens
    bool mining = true;

    /**
     * @dev Function to mint tokens
     * @param _to The address that will receive the minted tokens.
     * @param _amount The amount of tokens to mint.
     * @return A boolean that indicates if the operation was successful.
     */
    function mint(address _to, uint256 _amount) public returns (bool) {
        require(msg.sender == dugSale);
        require(mining);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(0x0, _to, _amount);
        return true;
    }

    /**
    * @notice Stop mining add event MintFinished saved date stop mining
    * @dev Function to stop minting new tokens.
    */
    function finishMinting() public onlyOwner {
        mining = false;
        MintFinished(now);
    }

    /**
    * @notice Lock unlock transfer between accounts
    */
    function lockUnlockTransfer() public onlyOwner {
        lock = !lock;
    }

    /**
    * @notice Set doug sale agent
    */
    function setDugSale(address _dugSale) public onlyOwner {
        require(_dugSale != 0x0);
        dugSale = _dugSale;
    }

    /**
    * @notice Returned active dug sale address
    */
    function getDugSaleAddress() public constant returns (address) {
        return dugSale;
    }

    /**
    * @notice Returned active dug sale address
    */
    function canMints() public constant returns(bool) {
        return mining;
    }

}
