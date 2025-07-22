# STXFiat.clar

This contract implements a multi-collateral stablecoin protocol for the Stacks blockchain. It features algorithmic supply management, cross-chain bridge functionality, enhanced governance, and security mechanisms.

---

## Features

- **Multi-Collateral System:** Supports multiple collateral types, each with custom parameters (collateral ratio, liquidation threshold, stability fee, debt ceiling).
- **Stablecoin Minting & Repayment:** Users can deposit collateral to mint stablecoins and repay debt to withdraw collateral.
- **Liquidation:** Positions below the liquidation threshold can be liquidated.
- **Algorithmic Supply Management:** Rebase mechanism adjusts supply based on price deviation from the target.
- **Cross-Chain Bridge:** Secure bridge system with validator signatures for cross-chain transfers.
- **Governance & Security:** Blacklisting, transfer limits, emergency mode, and parameter updates.
- **Transaction Logging:** All major actions are logged for transparency.

---

## Key Functions

### Initialization & Oracle

- `initialize`: Initializes the contract and sets the owner.
- `set-price-oracle`, `remove-price-oracle`: Manage the price oracle contract.
- `set-current-price`, `manual-set-price`: Set the stablecoin price manually (for testing).

### Collateral Management

- `add-collateral-type`: Add a new collateral type with parameters.
- `deposit-collateral-and-mint`: Deposit collateral and mint stablecoins.
- `repay-debt-and-withdraw`: Repay debt and withdraw collateral.

### Liquidation

- `liquidate-position`: Liquidate under-collateralized positions.

### Supply Management

- `rebase-supply`: Algorithmically adjust supply based on price deviation.

### Bridge

- `add-bridge-validator`: Add a validator for bridge operations.
- `initiate-bridge-transfer`: Initiate a cross-chain transfer.
- `validate-bridge-request`: Validators sign bridge requests.
- `complete-bridge-in`: Complete incoming bridge transfers.

### Transfers & Security

- `transfer`: Enhanced transfer function with blacklist and rate limiting.
- `enable-emergency-mode`, `disable-emergency-mode`: Emergency controls.
- `blacklist-address`: Blacklist or unblacklist an address.
- `update-transfer-limits`: Update transfer limits and cooldown.

### Governance

- `update-rebase-parameters`: Update rebase parameters.
- `update-bridge-parameters`: Update bridge fee and validator count.

### Read-Only Queries

- `get-user-position`, `get-collateral-info`, `get-global-stats`, `get-bridge-request`, `get-price-history`, `balance-of`, `get-total-supply`, `get-contract-owner`, `is-initialized`, `get-transaction-history`, `get-current-stablecoin-price`, `get-oracle-info`, `check-position-safety`

---

## Usage

Deploy the contract, initialize it, add collateral types, and interact with minting, repayment, transfer, and bridge functions. Use governance functions to update parameters and manage security.

---

## Notes

- This contract is designed for development and testing. It is not audited for production use.
- Collateral transfers assume SIP-010 compatibility but are mocked for simplicity.

---

## License

See the project root for license information.
