// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract Staking is Ownable, ReentrancyGuard {

    struct Stake {
        uint256 amount;
        uint256 duration;
        uint256 endTime;
        uint256 reward;
        bool isClaimed;
    }
    
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    uint256 public constant RATE_DIVISOR = 100;

    mapping(address => Stake) public stakes;
    mapping(uint256 => uint256) public rates;

    event Staked(address indexed user, uint256 amount, uint256 reward);
    event Unstaked(address indexed user, uint256 amount);

    constructor(address _stakingToken, address _rewardToken, address initialOwner) Ownable(initialOwner) {
        require(_stakingToken != address(0) && _rewardToken != address(0), "invalid addresses");
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);

        // pre set reward rates for 1 and 2 hours respectively
        rates[60 minutes] = 500;
        rates[120 minutes] = 1000;
    }

    function stake(uint256 amount, uint256 duration) external nonReentrant {
        require(amount > 0, "invalid amount");
        require(rates[duration] > 0, "invalid rate for this duration");
        require(stakes[msg.sender].amount == 0 || stakes[msg.sender].isClaimed, "already staked");

        stakingToken.transferFrom(msg.sender, address(this), amount);
        
        uint256 reward = (amount * rates[duration]) / (100 * RATE_DIVISOR);

        stakes[msg.sender] = Stake({
            amount: amount,
            duration: duration,
            endTime: block.timestamp + duration,
            reward: reward,
            isClaimed: false
        });

        emit Staked(msg.sender, amount, reward);
    }

    function unstake() external nonReentrant {
        Stake memory stakeRecord = stakes[msg.sender];
        
        require(stakeRecord.amount > 0 && stakeRecord.isClaimed == false, "nothing to unstake or already unstaked");
        require(block.timestamp >= stakeRecord.endTime, "staking period not yet finished");

        stakes[msg.sender].isClaimed = true;
        
        require(stakingToken.transfer(msg.sender, stakeRecord.amount), "transfer failed");
        require(rewardToken.transfer(msg.sender, stakeRecord.reward), "not enough rewards");

        emit Unstaked(msg.sender, stakeRecord.amount);
    }

    function setRewardRate(uint256 duration, uint256 rate) public onlyOwner {
        rates[duration] = rate;
    }

    function setRewardToken(address _rewardToken) public onlyOwner {
        require(_rewardToken != address(0), "invalid address");
        rewardToken = IERC20(_rewardToken);
    }

    function getStakeRecord(address user) external view returns (Stake memory) {
        return stakes[user];
    }

}
