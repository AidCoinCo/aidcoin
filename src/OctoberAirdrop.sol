pragma solidity ^0.4.24;

import "./JulyAirdrop.sol";


/**
 * @title OctoberAirdrop
 */
contract OctoberAirdrop is Ownable {
	using SafeMath for uint256;

	address airdropWallet;
	mapping (address => uint256) public claimedAirdropTokens;
	mapping (address => uint256) public remainingAirdropSurplus;
	address[] public remainingAirdropSurplusAddresses;

	JulyAirdrop previousAirdrop;
	AidCoin public token;

	constructor(address _airdropWallet, address _token, address _previousAirdrop) public {
		require(_airdropWallet != address(0));
		require(_token != address(0));
		require(_previousAirdrop != address(0));

		airdropWallet = _airdropWallet;
		token = AidCoin(_token);
		previousAirdrop = JulyAirdrop(_previousAirdrop);
	}

	function multisend(address[] users, uint256[] amounts) public onlyOwner {
		require(users.length > 0);
		require(amounts.length > 0);
		require(users.length == amounts.length);

		for (uint i = 0; i < users.length; i++) {
			address to = users[i];
			uint256 value = (amounts[i] * (10 ** 18)).mul(125).div(1000);

			if (claimedAirdropTokens[to] == 0) {
				claimedAirdropTokens[to] = value;

				uint256 previousSurplus = previousAirdrop.remainingAirdropSurplus(to);
				if (value > previousSurplus) {
					value = value.sub(previousSurplus);
					token.transferFrom(airdropWallet, to, value);
				} else {
					remainingAirdropSurplus[to] = previousSurplus.sub(value);
					remainingAirdropSurplusAddresses.push(to);
				}
			}
		}
	}

	function getRemainingAirdropSurplusAddressesLength() view public returns (uint) {
		return remainingAirdropSurplusAddresses.length;
	}
}
