Phase 1 : Compile 

Click "Solidity Compiler" tab (left sidebar)
Click "Compile NovaClassTicket.sol"
Verify green checkmark appears ✅

Phase 2: Set Up to Deploy (5 mins)

Click "Deploy & Run Transactions" tab
Environment: Select "Remix VM (Shanghai)"
Constructor Parameters:

_passPrice: 100000000000000000 (0.1 ETH in wei)
_passDurationDays: 30 (30 days)

Phase 3: Deploy to JavaScript VM (5 mins)
Click "Deploy"
Contract appears under "Deployed Contracts"

Phase 4: Testing (15 mins)
Test 1: Buy a Pass

Set VALUE to 100000000000000000 wei (0.1 ETH)
Click buyPass
Check transaction success ✅
Click myAccess → should return true

Test 2: Check Access

Copy your address from "Account" dropdown
Paste into hasAccess function
Click → should return true
Click getTimeRemaining with your address → shows seconds remaining

Test 3: Test Another User

Switch to different account (Account dropdown)
Click myAccess → should return false
Try buyPass without VALUE → should fail ❌

Test 4: Owner Functions

Switch back to owner account (first account)
Click getBalance → shows contract balance
Click withdraw → withdraws funds to owner
Test updatePrice with new value: 50000000000000000 (0.05 ETH)

Test 5: Verify Events

Check console for "AccessPurchased" events
Verify buyer address and expiry time are correct