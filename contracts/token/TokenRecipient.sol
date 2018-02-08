pragma solidity ^0.4.18;

contract TokenRecipient {
    function receiveApproval(address _from, uint _value, address _tknAddress, bytes _extraData);
}
