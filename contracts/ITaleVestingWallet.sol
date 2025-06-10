// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface ITaleVestingWallet {
    function getVestingSchedule()
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
        );
}