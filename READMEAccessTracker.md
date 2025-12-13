AccessVault contract:

Purpose
A vault where users:

Stake ETH to earn a fixed 5% annual yield (configurable by owner).
Withdraw/claim rewards only if they hold an active NovaClassTicket (NFT/access pass).
Key Components
Access Control

INovaClassTicket: Checks if a user has a valid ticket (hasAccess).
onlyOwner: Restricts fundVault and updateYieldRate to the contract owner.
State Variables

Tracks user deposits (deposits), timestamps (depositTime, lastRewardClaim), and total ETH (totalDeposited).
Fixed yieldRate (default: 5%).
Core Functions

deposit(): Accepts ETH, updates balances/emits Deposited event.
withdraw(uint256): Reverts if no ticket or insufficient balance; sends ETH via call.
claimRewards(): Calculates rewards (time-based), transfers ETH if vault has funds.
calculateRewards(address): Computes pending rewards using:

(userDeposit * yieldRate / 100) * (timeElapsed / 365 days)
getVaultInfo(address): Returns user stats (deposit, rewards, ticket status).
Owner Functions

fundVault(): Accepts ETH to fund rewards (payable).
updateYieldRate(uint256): Adjusts yield rate (capped at 20%).
Security

Reentrancy-protected: Uses call after state changes.
Input validation: Checks for msg.value > 0, sufficient balance, and ticket access.
Custom errors: NoAccess, InsufficientBalance, etc.
Events

Deposited, Withdrawn, RewardClaimed for transparency.
Flow
User deposits ETH → earns yield over time.
To withdraw/claim, user must hold a NovaClassTicket.
Owner funds the vault (to cover rewards) and can adjust the yield rate.
Note: The vault’s reward payout depends on its ETH balance (owner must fund it). Yield is not compounded.