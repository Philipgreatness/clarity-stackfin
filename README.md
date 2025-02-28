# StackFin
A decentralized finance protocol for personal loans on the Stacks blockchain.

## Features
- Create loan requests with collateral
- Fund loan requests
- Repay loans with interest
- Claim collateral on default
- View loan status and history

## Setup and Installation
1. Clone the repository
2. Install Clarinet (if not already installed)
3. Run `clarinet check` to verify contracts
4. Run `clarinet test` to run test suite

## Usage Examples
```clarity
;; Create a loan request
(contract-call? .stackfin request-loan u1000000 u1200000 u30)

;; Fund a loan
(contract-call? .stackfin fund-loan u1)

;; Repay a loan
(contract-call? .stackfin repay-loan u1)

;; Check loan status
(contract-call? .stackfin get-loan-data u1)
```

## Dependencies
- Clarity language
- Clarinet for testing and deployment
