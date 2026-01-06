# STXFiat Multi-Collateral Stablecoin Protocol

A comprehensive stablecoin implementation for the Stacks blockchain with advanced features including position health scoring, enhanced liquidation rewards, and governance.

## Core Features

### Multi-Collateral System
- Support for multiple collateral types
- Configurable parameters per collateral:
  - Collateral ratio
  - Liquidation threshold
  - Stability fee
  - Debt ceiling

### Position Management
- Deposit collateral and mint stablecoins
- Repay debt and withdraw collateral
- Real-time position health tracking (0-100 scale)
- Risk level categorization (low, medium, high, critical)

### Price Stability
- Algorithmic supply management via rebasing
- Price oracle integration
- TWAP (Time-Weighted Average Price) calculations
- Manual price controls for testing

### Advanced Features
1. **Position Health Scoring**
   - Health scores on 0-100 scale
   - Risk level categorization
   - Liquidation risk assessment

2. **Enhanced Liquidation**
   - Liquidator reward system
   - 5% bonus for liquidators
   - Performance tracking

3. **Fee Management**
   - Protocol fee collection (0.05%)
   - Fee distribution system
   - Multiple distribution categories

4. **Batch Operations**
   - Support for multiple operations
   - Transaction batching
   - Result tracking

5. **Analytics & Monitoring**
   - Position analytics
   - Collateral utilization tracking
   - Error logging system

6. **Governance**
   - Proposal system
   - Voting mechanism
   - Parameter updates

## Usage

```clarity
;; Initialize contract
(contract-call? .stxfiat initialize)

;; Add collateral type
(contract-call? .stxfiat add-collateral-type 
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM 
    'ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG
    u150    ;; 150% collateral ratio
    u130    ;; 130% liquidation threshold
    u5      ;; 5% stability fee
    u1000000000) ;; 1M debt ceiling

;; Deposit and mint
(contract-call? .stxfiat deposit-collateral-and-mint
    'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM
    u1000   ;; collateral amount
    u500)   ;; mint amount
```

## Contract Architecture

- [`contracts/STXFiat.clar`]STXFiat.clar ): Main stablecoin contract
- [`contracts/oracle.clar`](contracts/oracle.clar ): Price oracle implementation

## Development

```bash
# Install dependencies
npm install

# Run tests
npm test

# Check contracts
clarinet check
```

## Important Notes

- This contract is for development and testing
- Not audited for production use
- Includes mock implementations for testing
- Uses Clarity language features for Stacks blockchain

## License

See [`package.json`](package.json ) for license information.

---

For detailed function documentation and implementation details, see the source code comments.
