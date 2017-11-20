pragma solidity ^0.4.18;

import "zeppelin-solidity/contracts/token/BurnableToken.sol";
import "zeppelin-solidity/contracts/token/MintableToken.sol";


/**
 * @title AidCoin
 */
contract AidCoin is MintableToken, BurnableToken {
    string public name = "AidCoin";
    string public symbol = "AID";
    uint256 public decimals = 18;
    uint256 public maxSupply = 100000000 * (10 ** decimals);

    function AidCoin() public {

    }

    modifier canTransfer(address _from, uint _value) {
        require(mintingFinished);
        _;
    }

    function transfer(address _to, uint _value) canTransfer(msg.sender, _value) public returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint _value) canTransfer(_from, _value) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}
