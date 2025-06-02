// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TaleVestingWallet.sol";
import "./ITaleVestingWallet.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TaleVestingWalletFactory is Ownable(msg.sender) {

    address public immutable token;

    address[] public allVestingWallets;
    mapping(address => address[]) public beneficiaryWallets;

    event VestingWalletCreated(address indexed beneficiary, address vestingAddress);

    constructor(address _token) {
        require(_token != address(0), "Invalid token");
        token = _token;
    }

    function createVestingWallet(
        address _beneficiary,
        uint256 _startTimestamp,
        uint256 _releaseMonths,
        uint256 _totalAmount
    ) external onlyOwner returns (address walletAddress) {
        require(_beneficiary != address(0), "Invalid beneficiary");
        require(_releaseMonths > 0, "Invalid release period");
        require(_totalAmount > 0, "Invalid amount");

        TaleVestingWallet wallet = new TaleVestingWallet(
            token,
            _beneficiary,
            _startTimestamp,
            _releaseMonths,
            _totalAmount
        );

        wallet.transferOwnership(msg.sender);

        walletAddress = address(wallet);
        allVestingWallets.push(walletAddress);
        beneficiaryWallets[_beneficiary].push(walletAddress);

        emit VestingWalletCreated(_beneficiary, walletAddress);
    }

    function getAllVestingWallets() external view returns (address[] memory) {
        return allVestingWallets;
    }

    function getWalletsByBeneficiary(address _beneficiary) external view returns (address[] memory) {
        return beneficiaryWallets[_beneficiary];
    }

    function getVestingScheduleFor(address wallet)
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
        require(wallet != address(0), "Invalid wallet address");
        return ITaleVestingWallet(wallet).getVestingSchedule();
    }
}
