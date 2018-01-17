pragma solidity ^0.4.18;

import "./AidCoin.sol";
import "zeppelin-solidity/contracts/crowdsale/Crowdsale.sol";


/**
 * @title AidCoinIco
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract AidCoinIco is Ownable, Crowdsale {
    using SafeMath for uint256;

    mapping (address => uint256) public whitelist;
    mapping (address => uint256) public boughtTokens;

    mapping (address => uint256) public claimedAirdropTokens;

    // max tokens cap
    uint256 public tokenCap = 12000000 * (10 ** 18);

    // with whitelist
    uint256 public maxWithWhitelist = 8000000 * (10 ** 18);
    uint256 public boughtWithWhitelist = 0;

    // without whitelist
    uint256 public maxWithoutWhitelist = 4000000 * (10 ** 18);
    uint256 public maxWithoutWhitelistPerUser = 5 * 2000 * (10 ** 18); //5 * 2000 (rate)
    uint256 public boughtWithoutWhitelist = 0;

    // amount of sold tokens
    uint256 public soldTokens;

    function AidCoinIco(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        address _token
    ) public
    Crowdsale (_startTime, _endTime, _rate, _wallet)
    {
        require(_token != 0x0);
        token = AidCoin(_token);
    }

    /**
     * @dev Set the ico token contract
     */
    function createTokenContract() internal returns (MintableToken) {
        return AidCoin(0x0);
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        // get wei amount
        uint256 weiAmount = msg.value;

        // calculate token amount to be transferred
        uint256 tokens = weiAmount.mul(rate);

        // check if amount is less than allowed limits
        checkValidAmount(beneficiary, tokens);

        // calculate new total sold
        uint256 newTotalSold = soldTokens.add(tokens);

        // check if we are over the max token cap
        require(newTotalSold <= tokenCap);

        // update states
        weiRaised = weiRaised.add(weiAmount);
        soldTokens = newTotalSold;

        // mint tokens to beneficiary
        token.mint(beneficiary, tokens);
        TokenPurchase(
            msg.sender,
            beneficiary,
            weiAmount,
            tokens
        );

        forwardFunds();
    }

    function updateEndDate(uint256 _endTime) public onlyOwner {
        require(_endTime > now);
        require(_endTime > startTime);

        endTime = _endTime;
    }

    function closeTokenSale() public onlyOwner {
        require(hasEnded());

        // transfer token ownership to ico owner
        token.transferOwnership(owner);
    }

    function changeParticipationLimits(uint256 newMaxWithWhitelist, uint256 newMaxWithoutWhitelist) public onlyOwner {
        newMaxWithWhitelist = newMaxWithWhitelist * (10 ** 18);
        newMaxWithoutWhitelist = newMaxWithoutWhitelist * (10 ** 18);
        uint256 totalCap = newMaxWithWhitelist.add(newMaxWithoutWhitelist);

        require(totalCap == tokenCap);
        require(newMaxWithWhitelist >= boughtWithWhitelist);
        require(newMaxWithoutWhitelist >= boughtWithoutWhitelist);

        maxWithWhitelist = newMaxWithWhitelist;
        maxWithoutWhitelist = newMaxWithoutWhitelist;
    }

    function changeWhitelistStatus(address[] users, uint256[] amount) public onlyOwner {
        require(users.length > 0);

        uint len = users.length;
        for (uint i = 0; i < len; i++) {
            address user = users[i];
            uint256 newAmount = amount[i] * (10 ** 18);
            whitelist[user] = newAmount;
        }
    }

    function checkValidAmount(address beneficiary, uint256 tokens) internal {
        bool isWhitelist = false;
        uint256 limit = maxWithoutWhitelistPerUser;

        // check if user is whitelisted
        if (whitelist[beneficiary] > 0) {
            isWhitelist = true;
            limit = whitelist[beneficiary];
        }

        // check the previous amount of tokes owned during ICO
        uint256 ownedTokens = boughtTokens[beneficiary];

        // calculate new total owned by beneficiary
        uint256 newOwnedTokens = ownedTokens.add(tokens);

        // check if we are over the max per user
        require(newOwnedTokens <= limit);

        if (!isWhitelist) {
            // calculate new total sold
            uint256 newBoughtWithoutWhitelist = boughtWithoutWhitelist.add(tokens);

            // check if we are over the max token cap
            require(newBoughtWithoutWhitelist <= maxWithoutWhitelist);

            // update states
            boughtWithoutWhitelist = newBoughtWithoutWhitelist;
        } else {
            // calculate new total sold
            uint256 newBoughtWithWhitelist = boughtWithWhitelist.add(tokens);

            // check if we are over the max token cap
            require(newBoughtWithWhitelist <= maxWithWhitelist);

            // update states
            boughtWithWhitelist = newBoughtWithWhitelist;
        }

        boughtTokens[beneficiary] = boughtTokens[beneficiary].add(tokens);
    }

    function airdrop(address[] users, uint256[] amounts) public onlyOwner {
        require(users.length > 0);
        require(amounts.length > 0);
        require(users.length == amounts.length);

        uint256 oldRate = 1200;
        uint256 newRate = 2400;

        uint len = users.length;
        for (uint i = 0; i < len; i++) {
            address to = users[i];
            uint256 value = amounts[i];

            uint256 oldTokens = value.mul(oldRate);
            uint256 newTokens = value.mul(newRate);

            uint256 tokensToAirdrop = newTokens.sub(oldTokens);

            if (claimedAirdropTokens[to] == 0) {
                claimedAirdropTokens[to] = tokensToAirdrop;
                token.mint(to, tokensToAirdrop);
            }
        }
    }

    // overriding Crowdsale#hasEnded to add tokenCap logic
    // @return true if crowdsale event has ended or cap is reached
    function hasEnded() public constant returns (bool) {
        bool capReached = soldTokens >= tokenCap;
        return super.hasEnded() || capReached;
    }

    // @return true if crowdsale event has started
    function hasStarted() public constant returns (bool) {
        return now >= startTime && now < endTime;
    }
}