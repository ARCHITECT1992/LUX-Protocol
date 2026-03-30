// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LUX Protocol: The Light of Science
 * @dev Optimized for Polygon Mainnet Deployment.
 * Final Logic: ERC-20 + Ownable + ReentrancyGuard + Burnable.
 * Security v2: Added zero-address check, daily reward cap,
 *              POL withdrawal function, and event logging.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract LUXToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {

    // ─── Constants ────────────────────────────────────────────────
    uint256 private constant _MAX_SUPPLY         = 100_000_000 * 10**18;
    uint256 private constant _FOUNDER_ALLOCATION =   5_000_000 * 10**18;

    /// @dev Max LUX that can be rewarded per 24-hour window (1% of reserve)
    uint256 public constant DAILY_REWARD_CAP     =     950_000 * 10**18;

    // The Architect's Genesis Wallet (immutable after deploy)
    address public constant ARCHITECT_WALLET =
        0x0CB7c3B321724086542f7200261335FC487465D2;

    // ─── State ────────────────────────────────────────────────────
    uint256 public scientificMiningReserve;

    /// @dev Tracks how much has been distributed in the current day
    uint256 public rewardedToday;

    /// @dev Unix timestamp of when the current 24h window started
    uint256 public dailyWindowStart;

    // ─── Events ───────────────────────────────────────────────────
    event ScientificContributionValidated(
        address indexed contributor,
        uint256 reward
    );
    event POLWithdrawn(address indexed to, uint256 amount);

    // ─── Constructor ──────────────────────────────────────────────
    constructor() ERC20("LUX - Light of Science", "LUX") Ownable(msg.sender) {
        // 1. Mint Founder Allocation directly to Architect wallet
        _mint(ARCHITECT_WALLET, _FOUNDER_ALLOCATION);

        // 2. Set Scientific Reserve
        scientificMiningReserve = _MAX_SUPPLY - _FOUNDER_ALLOCATION;

        // 3. Mint reserve to contract for PoSC distribution
        _mint(address(this), scientificMiningReserve);

        // 4. Initialize daily window
        dailyWindowStart = block.timestamp;
    }

    // ─── PoSC Distribution ────────────────────────────────────────
    /**
     * @notice Reward a contributor for a validated scientific task.
     * @dev    Protected by: onlyOwner, nonReentrant, zero-address check,
     *         reserve check, and a rolling 24-hour distribution cap.
     * @param  contributor  Recipient wallet — must not be address(0).
     * @param  amount       LUX amount (in wei) to transfer.
     */
    function rewardScientificContribution(
        address contributor,
        uint256 amount
    ) external onlyOwner nonReentrant {

        // ✅ FIX 1: Zero-address guard
        require(
            contributor != address(0),
            "LUX: contributor is the zero address"
        );

        // ✅ FIX 2: Reserve guard
        require(
            amount <= scientificMiningReserve,
            "LUX: Insufficient mining reserve"
        );

        // ✅ FIX 3: Rolling daily cap
        _refreshDailyWindow();
        require(
            rewardedToday + amount <= DAILY_REWARD_CAP,
            "LUX: Daily reward cap exceeded"
        );

        // Update state before transfer (Checks-Effects-Interactions)
        scientificMiningReserve -= amount;
        rewardedToday           += amount;

        _transfer(address(this), contributor, amount);

        emit ScientificContributionValidated(contributor, amount);
    }

    // ─── POL Management ──────────────────────────────────────────
    /**
     * @notice Withdraw any POL (native token) held by this contract.
     * @dev    ✅ FIX 4: Prevents POL from being permanently locked.
     */
    function withdrawPOL() external onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        require(balance > 0, "LUX: No POL to withdraw");

        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "LUX: POL transfer failed");

        emit POLWithdrawn(owner(), balance);
    }

    // ─── Views ────────────────────────────────────────────────────
    /// @notice Returns the fixed maximum supply.
    function maxSupply() public pure returns (uint256) {
        return _MAX_SUPPLY;
    }

    /// @notice Returns how much reward capacity remains today.
    function remainingDailyCapacity() external view returns (uint256) {
        if (block.timestamp >= dailyWindowStart + 1 days) {
            return DAILY_REWARD_CAP; // window will reset on next tx
        }
        return DAILY_REWARD_CAP - rewardedToday;
    }

    // ─── Internal Helpers ─────────────────────────────────────────
    /// @dev Resets the daily counter if 24 hours have elapsed.
    function _refreshDailyWindow() internal {
        if (block.timestamp >= dailyWindowStart + 1 days) {
            dailyWindowStart = block.timestamp;
            rewardedToday    = 0;
        }
    }

    // ─── Receive POL ──────────────────────────────────────────────
    /// @dev Allows contract to receive POL for gas/operational use.
    receive() external payable {}
}
