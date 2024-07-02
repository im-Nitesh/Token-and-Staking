// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ABC.sol";

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