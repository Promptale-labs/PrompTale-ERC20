// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaleVestingWallet
 * @notice Handles token vesting over fixed intervals.
 */
contract TaleVestingWallet is Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable token;
    address public beneficiary;

    uint256 public immutable interval;
    uint256 public startTimestamp;
    uint256 public totalAmount;
    uint256 public releaseMonths;

    uint256 private _releasedAmount;
    uint256 private _releasedTimes;

    // Emergency withdrawal state
    bool private _beneficiaryConsent = false;

    event TokensReleased(address indexed beneficiary, uint256 amount);
    event VestingProgress(uint256 releasedTimes, uint256 totalReleased, uint256 releasable);
    event EmergencyWithdraw(address indexed to, uint256 amount, bool withConsent);
    event BeneficiaryConsentUpdated(bool newConsent);

    /**
     * @notice Initializes the vesting wallet.
     */
    constructor(
        address _token,
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _interval,
        uint256 _releaseMonths,
        uint256 _totalAmount
    ) Ownable(msg.sender) {
        require(_token != address(0), "TaleVestingWallet: token address is zero");
        require(_beneficiary != address(0), "TaleVestingWallet: beneficiary address is zero");
        require(_interval > 0, "TaleVestingWallet: interval must be > 0");
        require(_releaseMonths > 0, "TaleVestingWallet: releaseMonths must be > 0");
        require(_totalAmount >= 1000000000000000000, "TaleVestingWallet: Amount too small");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        startTimestamp = _startTimestamp;
        interval = _interval;
        releaseMonths = _releaseMonths;
        totalAmount = _totalAmount;
    }

    /**
     * @notice Releases releasable tokens to the beneficiary.
     */
    function release() external {
        require(msg.sender == beneficiary, "TaleVestingWallet: unauthorized");
        require(block.timestamp >= startTimestamp, "TaleVestingWallet: vesting not started");

        uint256 currentTime = block.timestamp;
        uint256 releasable = releasableAmount(currentTime);
        require(releasable > 0, "TaleVestingWallet: no tokens to release");

        _releasedAmount += releasable;
        _releasedTimes = (currentTime - startTimestamp) / interval;
        if (_releasedTimes > releaseMonths) _releasedTimes = releaseMonths;

        token.safeTransfer(beneficiary, releasable);

        emit TokensReleased(beneficiary, releasable);
        emit VestingProgress(_releasedTimes, _releasedAmount, releasable);
    }

    /**
     * @notice Calculates releasable token amount.
     */
    function releasableAmount(uint256 currentTime) public view returns (uint256) {
        if (currentTime < startTimestamp) return 0;

        uint256 elapsed = (currentTime - startTimestamp) / interval;
        if (elapsed > releaseMonths) elapsed = releaseMonths;

        uint256 vested = (totalAmount * elapsed) / releaseMonths;
        return vested > _releasedAmount ? vested - _releasedAmount : 0;
    }

    /**
     * @notice Returns full vesting info for the wallet.
     * @return resultBeneficiary Address of the beneficiary
     * @return resultStart Timestamp when vesting starts
     * @return resultInterval Interval between releases
     * @return resultReleaseMonths Total number of vesting intervals
     * @return resultTotalAmount Total amount to be vested
     * @return resultReleasedTimes Number of completed releases
     * @return resultReleasedAmount Total amount released so far
     * @return resultReleasableAmount Amount currently releasable
     */
    function getVestingSchedule() external view returns (
        address resultBeneficiary,
        uint256 resultStart,
        uint256 resultInterval,
        uint256 resultReleaseMonths,
        uint256 resultTotalAmount,
        uint256 resultReleasedTimes,
        uint256 resultReleasedAmount,
        uint256 resultReleasableAmount
    ) {
        return (
            beneficiary,
            startTimestamp,
            interval,
            releaseMonths,
            totalAmount,
            _releasedTimes,
            _releasedAmount,
            releasableAmount(block.timestamp)
        );
    }

    /**
     * @notice Allows the beneficiary to set their consent for emergency withdrawal
     * @param consent Whether the beneficiary consents to full emergency withdrawal
     */
    function setEmergencyWithdrawConsent(bool consent) external {
        require(msg.sender == beneficiary, "TaleVestingWallet: only beneficiary can set consent");
        _beneficiaryConsent = consent;
        emit BeneficiaryConsentUpdated(consent);
    }

    /**
     * @notice Emergency withdrawal function that can be called by owner
     * @dev If beneficiary has given consent, all tokens are withdrawn. Otherwise, only excess tokens are withdrawn
     * @param to Address to receive the withdrawn tokens
     */
    function emergencyWithdraw(address to) external onlyOwner {
        require(to != address(0), "TaleVestingWallet: withdraw to zero address");
        
        uint256 balance = token.balanceOf(address(this));
        uint256 remainingForBeneficiary = totalAmount - _releasedAmount;
        
        if (_beneficiaryConsent) {
            require(balance > 0, "TaleVestingWallet: no tokens to withdraw");
            token.safeTransfer(to, balance);
            emit EmergencyWithdraw(to, balance, true);
        } else {
            require(balance > remainingForBeneficiary, "TaleVestingWallet: no excess tokens to withdraw");
            uint256 withdrawableAmount = balance - remainingForBeneficiary;
            require(withdrawableAmount > 0, "TaleVestingWallet: no tokens available for withdrawal");
            
            token.safeTransfer(to, withdrawableAmount);
            emit EmergencyWithdraw(to, withdrawableAmount, false);
        }
    }

}
