pragma solidity ^0.4.18;

import "./AidCoin.sol";


/**
 * @title BountyProgram
 */
contract BountyProgram is Ownable {

    address bountyWallet;
    mapping (address => uint256) public claimedBountyTokens;

    AidCoin public token;

    function BountyProgram(address _bountyWallet, address _token) public {
        require(_bountyWallet != address(0));
        require(_token != address(0));

        bountyWallet = _bountyWallet;
        token = AidCoin(_token);
    }

    function multisend(address[] users, uint256[] amounts) public onlyOwner {
        require(users.length > 0);
        require(amounts.length > 0);
        require(users.length == amounts.length);

        for (uint i = 0; i < users.length; i++) {
            address to = users[i];
            uint256 value = amounts[i] * (10 ** 18);

            if (claimedBountyTokens[to] == 0) {
                claimedBountyTokens[to] = value;
                token.transferFrom(bountyWallet, to, value);
            }
        }
    }
}