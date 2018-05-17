pragma solidity ^0.4.18;


import {Token} from "../Token.sol";
import "zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "zeppelin-solidity/contracts/math/SafeMath.sol";
import "./FinalizableCrowdsale.sol";


contract Crowdsale is FinalizableCrowdsale {

    using SafeMath for uint256;

    ERC20 public token;

    uint256 internal constant EXPONENT = 10 ** uint256(18);

    uint256 constant public totalSupplyCap = 2500000000 * EXPONENT;

    uint256 constant public tokensAvailableSale = 1250000000 * EXPONENT;

    event TokenPurchase(address indexed beneficiary, uint256 amount);

    function CrowdSale() {
        token = new Token();
    }

    function bayTokens(address _beneficiary, uint256 _tokenAmount) {
        _preValidatePurchase(_beneficiary);

        uint totalSupply = token.totalSupply();
        require(tokensAvailableSale >= totalSupply.add(_tokenAmount));

        _processPurchase(_beneficiary, _tokenAmount);
    }

   /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use super to concatenate validations.
   * @param _beneficiary Address performing the token purchase
   */
    function _preValidatePurchase(address _beneficiary) internal {
        require(_beneficiary != address(0));
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
     * @param _beneficiary Address receiving the tokens
     * @param _tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(totalSupplyCap >= token.totalSupply().add(_tokenAmount));
        emit TokenPurchase(_beneficiary, _tokenAmount);
        _mintTokens(_beneficiary, _tokenAmount);
    }

    /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
    function _mintTokens(address _beneficiary, uint256 _tokenAmount) internal {
        require(Token(token).mint(_beneficiary, _tokenAmount));
    }

    function finalization() internal {
        Token(token).finishMinting();
    }

}
