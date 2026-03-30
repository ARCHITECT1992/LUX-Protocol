// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title LUX Protocol: The Light of Science
 * @dev Implementation of the LUX Token for Decentralized Scientific Computing.
 * Total Supply: 100,000,000 LUX
 * Consensus: Proof of Scientific Contribution (PoSC)
 */

import "@openzeppelin/contracts@5.0.0/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts@5.0.0/access/Ownable.sol";
import "@openzeppelin/contracts@5.0.0/utils/ReentrancyGuard.sol";
contract LUXToken is ERC20, Ownable, ReentrancyGuard {
    
    // Fixed Total Supply: 100 Million LUX
    uint256 private constant _MAX_SUPPLY = 100_000_000 * 10**18;
    
    // Architect (Founder) allocation: 5%
    uint256 private constant _FOUNDER_ALLOCATION = 5_000_000 * 10**18;
    
    // Remaining for Scientific Mining: 95%
    uint256 public scientificMiningReserve;

    address public constant ARCHITECT_WALLET = 0x0CB7c3B321724086542f7200261335FC487465D2;

    event ScientificContributionValidated(address indexed contributor, uint256 reward);

    constructor() ERC20("LUX - Light of Science", "LUX") {
        // Minting the Founder's allocation directly to the ARCHITECT
        _mint(ARCHITECT_WALLET, _FOUNDER_ALLOCATION);
        
        // Setting the reserve for future scientific rewards
        scientificMiningReserve = _MAX_SUPPLY - _FOUNDER_ALLOCATION;
        
        // The remaining supply is held by the contract for distribution via PoSC
        _mint(address(this), scientificMiningReserve);
    }

    /**
     * @dev Distributes rewards for scientific tasks (e.g., Protein Folding, Space Data Analysis).
     * Only the Architect or the designated AI-Oracle can trigger this after validation.
     */
    function rewardScientificContribution(address contributor, uint256 amount) 
        external 
        onlyOwner 
        nonReentrant 
    {
        require(amount <= scientificMiningReserve, "LUX: Insufficient mining reserve");
        
        scientificMiningReserve -= amount;
        _transfer(address(this), contributor, amount);
        
        emit ScientificContributionValidated(contributor, amount);
    }

    /**
     * @dev Returns the total maximum supply of LUX.
     */
    function maxSupply() public pure returns (uint256) {
        return _MAX_SUPPLY;
    }
}
