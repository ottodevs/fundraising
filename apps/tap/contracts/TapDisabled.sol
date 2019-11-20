pragma solidity 0.4.24;

import "./ITap.sol";


contract TapDisabled is ITap {

    /***** external functions *****/

    /**
     * @notice Do nothing, Tap is disabled
    */
    function updateBeneficiary(address) external {}

    /**
     * @notice Do nothing, Tap is disabled
    */
    function updateMaximumTapRateIncreasePct(uint256) external {}

    /**
     * @notice Do nothing, Tap is disabled
    */
    function updateMaximumTapFloorDecreasePct(uint256) external {}

    /**
     * @notice Do nothing, Tap is disabled
    */
    function addTappedToken(address, uint256, uint256) external {}

    /**
     * @notice Do nothing, Tap is disabled
    */
    function updateTappedToken(address, uint256, uint256) external {}

    /**
     * @notice Do nothing, Tap is disabled
    */
    function resetTappedToken(address) external {}

    /**
     * @notice Do nothing, Tap is disabled
    */
    function withdraw(address) external {}

    /***** public view functions *****/

    function getMaximumWithdrawal(address) public view returns (uint256) {
        return 0;
    }
}
