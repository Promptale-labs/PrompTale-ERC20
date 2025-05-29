// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TaleVestingWallet is Ownable(msg.sender) {
    using SafeERC20 for IERC20;
    IERC20 public immutable token;

    address public beneficiary;
    uint256 public constant INTERVAL = 30 days;
    uint256 public startTimestamp;
    uint256 public totalAmount;
    uint256 public releaseMonths = 1;
    uint256 public releasedAmount = 0;
    uint256 public releasedTimes = 0;

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingProgress(uint256 releasedTimes, uint256 totalReleased, uint256 releasable);
    event VestingUpdateUint(string attrubute, uint256 newValue);
    event VestingUpdateAddress(string attrubute, address newValue);
    event Withdraw(address indexed to, uint256 amount);
    
    /**
     * @dev Set the ERC20 token address.
     */
    constructor(
        address _token,
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _releaseMonths,
        uint256 _totalAmount
    ) {
        require(_token != address(0), "Invalid token");
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_releaseMonths > 0, "ReleaseMonths is smaller than 0");
        
        token = IERC20(_token);
        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        releaseMonths = _releaseMonths;
        totalAmount = _totalAmount;
    }

    /**
     * @dev Release the tokens.
     *
     * Emits a {TokensReleased} event.
     */
    function release() public virtual {
        require(msg.sender == beneficiary || msg.sender == owner(), "Only beneficiary");
        require(startTimestamp < block.timestamp, "Still locked");

        uint256 calculationAmount = releasableAmount(block.timestamp);
        
        require(calculationAmount > 0, "Insufficient release amount.");

        token.safeTransfer(beneficiary, calculationAmount);

        releasedAmount += calculationAmount;
        releasedTimes = releasableMonth(block.timestamp);

        emit TokensReleased(beneficiary, calculationAmount);
        emit VestingProgress(releasedTimes, releasedAmount, calculationAmount);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function releasableAmount(uint256 currentTime) public view returns (uint256) {
        if (currentTime < startTimestamp) return 0;

        uint256 elapsedMonths = releasableMonth(currentTime);

        uint256 vestedAmount = (totalAmount * elapsedMonths) / releaseMonths;

        return vestedAmount > releasedAmount ? vestedAmount - releasedAmount : 0;
    }

    function releasableMonth(uint256 currentTime) public view returns (uint256) {
        if (currentTime < startTimestamp) return 0;

        uint256 elapsedMonths = (currentTime - startTimestamp) / INTERVAL;
        if (elapsedMonths > releaseMonths) elapsedMonths = releaseMonths;

        return elapsedMonths;
    }

    /**
     * @dev Getter for the VestingInfo.
     */
    function getVestingSchedule()
        external
        view
        returns (
            address _beneficiary,
            uint256 _start,
            uint256 _interval,
            uint256 _releasesMonths,
            uint256 _totalAmount,
            uint256 _releasedTimes,
            uint256 _releasedAmount,
            uint256 _releasableAmount
        )
    {
        uint256 currentTime = block.timestamp;
        return (
            beneficiary,
            startTimestamp,
            INTERVAL,
            releaseMonths,
            totalAmount,
            releasedTimes,
            releasedAmount,
            releasableAmount(currentTime)
        );
    }

    /**
     * @dev Setter for the VestingInfo.
     */
    function setVestingAmount (uint256 _value) external onlyOwner {
        totalAmount = _value;
        emit VestingUpdateUint("totalAmount", _value );
    }
    function setVestingStartTime (uint256 _value) external onlyOwner {
        startTimestamp = _value;
        emit VestingUpdateUint("startTime", _value );
    }
    function setVestingDuration(uint256 _value) external onlyOwner {
        require(_value > 0, "ReleaseMonths is smaller than 0");
        releaseMonths = _value;
        emit VestingUpdateUint("releaseMonths", _value );
    }
    function setVestingBeneficiary(address _value) external onlyOwner {
        require(_value != address(0), "Invalid beneficiary");
        beneficiary = _value;
        emit VestingUpdateAddress("beneficiary", _value );
    }

    function emergencyWithdraw(address to) external onlyOwner {
        require(to != address(0), "Invalid address");
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(to, balance), "Withdraw failed");
        emit Withdraw(to, balance);
    }

}
