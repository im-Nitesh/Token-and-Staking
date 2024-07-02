// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ABC is ERC20 {
    uint256 public constant TOTAL_SUPPLY = 1000000000 * (10 ** 18); // Total supply of ABC tokens
    uint256 public constant PUBLIC_SALE_ALLOCATION = 220000000 * (10 ** 18); // Public sale allocation
    uint256 public constant SEED_FUNDING_ALLOCATION = 80000000 * (10 ** 18); // Seed funding allocation
    uint256 public constant PRIVATE_SALE_ALLOCATION = 40000000 * (10 ** 18); // Private sale allocation
    uint256 public constant PLATFORM_ALLOCATION = 180000000 * (10 ** 18); // Platform and ecosystem development allocation
    uint256 public constant LIQUIDITY_POOL_ALLOCATION = 90000000 * (10 ** 18); // Liquidity pool allocation
    uint256 public constant MARKETING_ALLOCATION = 60000000 * (10 ** 18); // Marketing and community engagement allocation
    uint256 public constant STAKING_INCENTIVES_ALLOCATION = 90000000 * (10 ** 18); // Staking incentives allocation
    uint256 public constant TEAM_ALLOCATION = 120000000 * (10 ** 18); // Team and founders allocation
    uint256 public constant ADVISORY_BOARD_ALLOCATION = 30000000 * (10 ** 18); // Advisory board allocation
    uint256 public constant RESEARCH_ALLOCATION = 100000000 * (10 ** 18); // Research and development fund allocation
    uint256 public constant STRATEGIC_RESERVE_ALLOCATION = 60000000 * (10 ** 18); // Strategic reserve allocation
    
    uint256 public constant STAKING_MONTHLY_APY = 50; // APY for 1-month staking
    uint256 public constant STAKING_QUARTERLY_APY = 80; // APY for 3-month staking
    uint256 public constant STAKING_SEMIANNUAL_APY = 100; // APY for 6-month staking

    constructor() ERC20("ABC", "ABC")  {
        _mint(msg.sender, PUBLIC_SALE_ALLOCATION);
        _mint(address(this), TOTAL_SUPPLY - PUBLIC_SALE_ALLOCATION);
    } 

    function transfer(address to, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return true;
    }

     function transferFrom(address from, address to, uint256 value) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, value);
        _transfer(from, to, value);
        return true;
    }

}

contract StakingContract is ABC {
    ABC public abcToken;
    uint256 public constant SECONDS_IN_A_MONTH = 30 days;
    uint256 public constant SECONDS_IN_THREE_MONTHS = 90 days;
    uint256 public constant SECONDS_IN_SIX_MONTHS = 180 days;

    struct Stake {
        uint256 amount;
        uint256 startTimestamp;
        uint256 duration; // in seconds
    }

    mapping(address => Stake) public stakes;

    event Staked(address indexed user, uint256 amount, uint256 duration);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);

    constructor(address _abcTokenAddress) {
        abcToken = ABC(_abcTokenAddress);
    }


    function stake(uint256 _amount, uint256 _duration) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(stakes[msg.sender].amount == 0, "Cannot stake while previous stake exists");

        abcToken.transferFrom(msg.sender, address(this), _amount);
        
        uint256 durationInSeconds;
        if (_duration == 1) {
            durationInSeconds = SECONDS_IN_A_MONTH;
        } else if (_duration == 3) {
            durationInSeconds = SECONDS_IN_THREE_MONTHS;
        } else if (_duration == 6) {
            durationInSeconds = SECONDS_IN_SIX_MONTHS;
        } else {
            revert("Invalid stake duration");
        }

        stakes[msg.sender] = Stake(_amount, block.timestamp, durationInSeconds);
        emit Staked(msg.sender, _amount, _duration);
    }

    function unstake() external {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake to unstake");
        require(block.timestamp >= userStake.startTimestamp + userStake.duration, "Stake duration not passed yet");

        abcToken.transfer(msg.sender, userStake.amount);
        emit Unstaked(msg.sender, userStake.amount);
        delete stakes[msg.sender];
    }

    function claimReward() external {
        Stake memory userStake = stakes[msg.sender];
        require(userStake.amount > 0, "No stake to claim reward");

        uint256 reward = calculateReward(msg.sender);
        abcToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    function calculateReward(address _user) public view returns (uint256) {
        Stake memory userStake = stakes[_user];
        uint256 stakeDuration = block.timestamp - userStake.startTimestamp;
        uint256 apy;

        if (userStake.duration == SECONDS_IN_A_MONTH) {
            apy = abcToken.STAKING_MONTHLY_APY();
        } else if (userStake.duration == SECONDS_IN_THREE_MONTHS) {
            apy = abcToken.STAKING_QUARTERLY_APY();
        } else if (userStake.duration == SECONDS_IN_SIX_MONTHS) {
            apy = abcToken.STAKING_SEMIANNUAL_APY();
        } else {
            revert("Invalid stake duration");
        }

        return (userStake.amount * apy * stakeDuration) / (100 * 365 days);
    }
}
