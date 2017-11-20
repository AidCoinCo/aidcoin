pragma solidity ^0.4.18;

import "./AidCoin.sol";
import "zeppelin-solidity/contracts/crowdsale/Crowdsale.sol";
import "zeppelin-solidity/contracts/token/TokenTimelock.sol";


/**
 * @title AidCoinPresale
 * @dev Extension of Crowdsale with a max amount of tokens raised
 */
contract AidCoinPresale is Ownable, Crowdsale {
    using SafeMath for uint256;

    // max tokens cap
    uint256 public tokenCap = 10000000 * (10 ** 18);

    // amount of sold tokens
    uint256 public soldTokens;

    // Team wallet
    address public teamWallet;
    // Advisor wallet
    address public advisorWallet;
    // AID pool wallet
    address public aidPoolWallet;
    // Company wallet
    address public companyWallet;
    // Bounty wallet
    address public bountyWallet;

    // reserved tokens
    uint256 public teamTokens 		= 	10000000 * (10 ** 18);
    uint256 public advisorTokens 	= 	10000000 * (10 ** 18);
    uint256 public aidPoolTokens 	= 	10000000 * (10 ** 18);
    uint256 public companyTokens 	= 	27000000 * (10 ** 18);
    uint256 public bountyTokens 	= 	3000000 * (10 ** 18);

    uint256 public claimedAirdropTokens;
    mapping (address => bool) public claimedAirdrop;

    // team locked tokens
    TokenTimelock public teamTimeLock;
    // advisor locked tokens
    TokenTimelock public advisorTimeLock;
    // company locked tokens
    TokenTimelock public companyTimeLock;

    modifier beforeEnd() {
        require(now < endTime);
        _;
    }

    function AidCoinPresale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        address _teamWallet,
        address _advisorWallet,
        address _aidPoolWallet,
        address _companyWallet,
        address _bountyWallet
    ) public
    Crowdsale (_startTime, _endTime, _rate, _wallet)
    {
        require(_teamWallet != 0x0);
        require(_advisorWallet != 0x0);
        require(_aidPoolWallet != 0x0);
        require(_companyWallet != 0x0);
        require(_bountyWallet != 0x0);

        teamWallet = _teamWallet;
        advisorWallet = _advisorWallet;
        aidPoolWallet = _aidPoolWallet;
        companyWallet = _companyWallet;
        bountyWallet = _bountyWallet;

        // give tokens to aid pool
        token.mint(aidPoolWallet, aidPoolTokens);

        // give tokens to team with lock
        teamTimeLock = new TokenTimelock(token, teamWallet, uint64(now + 1 years));
        token.mint(address(teamTimeLock), teamTokens);

        // give tokens to company with lock
        companyTimeLock = new TokenTimelock(token, companyWallet, uint64(now + 1 years));
        token.mint(address(companyTimeLock), companyTokens);

        // give tokens to advisor
        uint256 initialAdvisorTokens = advisorTokens.mul(20).div(100);
        token.mint(advisorWallet, initialAdvisorTokens);
        uint256 lockedAdvisorTokens = advisorTokens.sub(initialAdvisorTokens);
        advisorTimeLock = new TokenTimelock(token, advisorWallet, uint64(now + 180 days));
        token.mint(address(advisorTimeLock), lockedAdvisorTokens);
    }

    /**
     * @dev Create new instance of token contract
     */
    function createTokenContract() internal returns (MintableToken) {
        return new AidCoin();
    }

    // low level token purchase function
    function buyTokens(address beneficiary) public payable {
        require(beneficiary != 0x0);
        require(validPurchase());

        // get wei amount
        uint256 weiAmount = msg.value;

        // calculate token amount to be transferred
        uint256 tokens = weiAmount.mul(rate);

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

    // mint tokens for airdrop
    function airdrop(address[] users) public onlyOwner beforeEnd {
        require(users.length > 0);

        uint256 amount = 5 * (10 ** 18);

        uint len = users.length;
        for (uint i = 0; i < len; i++) {
            address to = users[i];
            if (!claimedAirdrop[to]) {
                claimedAirdropTokens = claimedAirdropTokens.add(amount);
                require(claimedAirdropTokens <= bountyTokens);

                claimedAirdrop[to] = true;
                token.mint(to, amount);
            }
        }
    }

    // close token sale and transfer ownership, also move unclaimed airdrop tokens
    function closeTokenSale(address _icoContract) public onlyOwner {
        require(hasEnded());
        require(_icoContract != 0x0);

        // mint unclaimed bounty tokens
        uint256 unclaimedAirdropTokens = bountyTokens.sub(claimedAirdropTokens);
        if (unclaimedAirdropTokens > 0) {
            token.mint(bountyWallet, unclaimedAirdropTokens);
        }

        // transfer token ownership to ico contract
        token.transferOwnership(_icoContract);
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