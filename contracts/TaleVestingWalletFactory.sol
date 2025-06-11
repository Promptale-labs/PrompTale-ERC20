// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "./TaleVestingWallet.sol";
import "./ITaleVestingWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title TaleVestingWalletFactory
 * @notice Deploys and manages TaleVestingWallet contracts for multiple beneficiaries.
 */
contract TaleVestingWalletFactory is Ownable {
    /// @notice ERC20 token address used in vesting
    address public immutable token;

    /// @notice List of all created vesting wallet addresses
    address[] private allVestingWallets;

    /// @notice Mapping of beneficiary to their vesting wallet(s)
    mapping(address => address[]) private beneficiaryWallets;

    /// @notice Emitted when a new vesting wallet is created
    event VestingWalletCreated(address indexed beneficiary, address vestingAddress);

    /**
     * @notice Constructor
     * @param _token The ERC20 token address used for vesting
     */
    constructor(address _token) Ownable(msg.sender) {
        require(_token != address(0), "TaleFactory: token address is zero");
        token = _token;
    }

    /**
     * @notice Creates a new TaleVestingWallet contract for the beneficiary.
     * @param _beneficiary Address to receive vested tokens
     * @param _startTimestamp When vesting begins
     * @param _releaseMonths Number of intervals over which tokens are released
     * @param _totalAmount Total amount of tokens to vest
     * @return walletAddress The deployed vesting wallet address
     */
    function createVestingWallet(
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _interval,
        uint256 _releaseMonths,
        uint256 _totalAmount
    ) external onlyOwner returns (address walletAddress) {
        require(_beneficiary != address(0), "TaleFactory: beneficiary address is zero");
        require(_interval > 86400, "TaleFactory: interval must be > 86400");
        require(_startTimestamp >= block.timestamp, "TaleFactory: Start timestamp must be in future");
        require(_startTimestamp <= block.timestamp + 365 days, "TaleFactory: Start timestamp too far in future");
        require(_releaseMonths > 0, "TaleFactory: releaseMonths must be > 0");
        require(_releaseMonths <= 365, "TaleFactory: Release period too long");
        require(_totalAmount >= 1000000000000000000, "TaleFactory: Amount too small");

        TaleVestingWallet wallet = new TaleVestingWallet(
            token,
            _beneficiary,
            _startTimestamp,
            _interval,
            _releaseMonths,
            _totalAmount
        );

        wallet.transferOwnership(msg.sender);

        walletAddress = address(wallet);
        allVestingWallets.push(walletAddress);
        beneficiaryWallets[_beneficiary].push(walletAddress);

        emit VestingWalletCreated(_beneficiary, walletAddress);
    }

    /**
     * @notice Returns all vesting wallet addresses deployed by the factory.
     * @return List of vesting wallet addresses
     */
    function getAllVestingWallets() external view returns (address[] memory) {
        return allVestingWallets;
    }

    /**
     * @notice Returns the vesting wallet addresses for a specific beneficiary.
     * @param _beneficiary Address of the beneficiary
     * @return Array of vesting wallet addresses for that beneficiary
     */
    function getWalletsByBeneficiary(address _beneficiary) external view returns (address[] memory) {
        return beneficiaryWallets[_beneficiary];
    }

    /**
     * @notice Fetches vesting schedule info from a deployed vesting wallet.
     * @param wallet Address of the vesting wallet
     * @return _beneficiary Address of the beneficiary
     * @return _start Timestamp when vesting starts
     * @return _interval Interval between releases
     * @return _releaseMonths Total number of vesting intervals
     * @return _totalAmount Total amount to be vested
     * @return _releasedTimes Number of completed releases
     * @return _releasedAmount Total amount released so far
     * @return _releasableAmount Amount currently releasable
     */
    function getVestingScheduleFor(address wallet)
        external
        view
        returns (
            address _beneficiary,
            uint256 _start,
            uint256 _interval,
            uint256 _releaseMonths,
            uint256 _totalAmount,
            uint256 _releasedTimes,
            uint256 _releasedAmount,
            uint256 _releasableAmount
        )
    {
        require(wallet != address(0), "TaleFactory: wallet address is zero");
        return ITaleVestingWallet(wallet).getVestingSchedule();
    }
}
