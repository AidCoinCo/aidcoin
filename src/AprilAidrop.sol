pragma solidity ^0.4.18;

import "./AidCoin.sol";


/**
 * @title AprilAirdrop
 */
contract AprilAirdrop is Ownable {

    address airdropWallet;
    mapping (address => uint256) public claimedAirdropTokens;

    AidCoin public token;

    function AprilAirdrop(address _airdropWallet, address _token) public {
        require(_airdropWallet != address(0));
        require(_token != address(0));

        airdropWallet = _airdropWallet;
        token = AidCoin(_token);
    }

    function multisend(address[] users, uint256[] amounts) public onlyOwner {
        require(users.length > 0);
        require(amounts.length > 0);
        require(users.length == amounts.length);

        for (uint i = 0; i < users.length; i++) {
            address to = users[i];
            uint256 value = amounts[i] * (10 ** 18) * 5 / 100;

            if (claimedAirdropTokens[to] == 0) {
                claimedAirdropTokens[to] = value;
                token.transferFrom(airdropWallet, to, value);
            }
        }
    }
}