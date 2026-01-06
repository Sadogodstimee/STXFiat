;; ===== TRAIT DEFINITIONS =====
(define-trait oracle-trait
  (
    (get-stablecoin-price () (response uint uint))
    (get-price () (response uint uint))
  ))

(define-trait sip-010-trait
  (
    (transfer (uint principal principal) (response bool uint))
    (get-balance (principal) (response uint uint))
  ))

(define-fungible-token stablecoin)

;; ===== ERROR CODES =====
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ALREADY-INITIALIZED (err u101))
(define-constant ERR-NOT-INITIALIZED (err u102))
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-INSUFFICIENT-BALANCE (err u104))
(define-constant ERR-MAX-SUPPLY-REACHED (err u105))
(define-constant ERR-INVALID-GOVERNANCE-ACTION (err u106))
(define-constant ERR-TRANSFER-PAUSED (err u107))
(define-constant ERR-BLACKLISTED (err u108))
(define-constant ERR-INVALID-RECIPIENT (err u109))
(define-constant ERR-INVALID-IMPLEMENTATION (err u110))
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u111))
(define-constant ERR-LIQUIDATION-THRESHOLD (err u112))
(define-constant ERR-INVALID-COLLATERAL-TYPE (err u113))
(define-constant ERR-ORACLE-ERROR (err u114))
(define-constant ERR-BRIDGE-ERROR (err u115))
(define-constant ERR-COOLDOWN-ACTIVE (err u116))
(define-constant ERR-DIVISION-BY-ZERO (err u117))
;; NEW ERROR CODES FOR IMPROVEMENTS
(define-constant ERR-BATCH-LIMIT-EXCEEDED (err u118))
(define-constant ERR-INVALID-HEALTH-SCORE (err u119))
(define-constant ERR-PROPOSAL-NOT-FOUND (err u120))
(define-constant ERR-VOTING-PERIOD-ENDED (err u121))
(define-constant ERR-INSUFFICIENT-VOTING-POWER (err u122))

;; ===== CORE STATE VARIABLES =====
(define-data-var contract-owner principal tx-sender)
(define-data-var initialized bool false)
(define-data-var total-supply uint u0)
(define-data-var max-supply uint u1000000000000) ;; 1 trillion tokens
(define-data-var transfer-paused bool false)
(define-data-var emergency-mode bool false)

;; ===== IMPROVEMENT 1: POSITION HEALTH SCORING SYSTEM =====
(define-map position-health-scores
  {user: principal, asset: principal}
  {
    health-score: uint,        ;; 0-100 scale
    risk-level: (string-ascii 10), ;; "low", "medium", "high", "critical"
    last-calculated: uint,
    liquidation-risk: uint     ;; Percentage risk of liquidation
  })

;; ===== IMPROVEMENT 2: LIQUIDATION REWARDS SYSTEM =====
(define-data-var liquidation-bonus-rate uint u500) ;; 5% bonus for liquidators
(define-map liquidation-rewards
  principal
  {
    total-rewards: uint,
    successful-liquidations: uint,
    last-liquidation: uint
  })

;; ===== IMPROVEMENT 3: FEE COLLECTION AND DISTRIBUTION =====
(define-data-var protocol-fee-rate uint u50) ;; 0.05% protocol fee
(define-data-var accumulated-fees uint u0)
(define-map fee-distribution
  (string-ascii 20)
  {
    percentage: uint,
    accumulated: uint,
    last-distribution: uint
  })

;; ===== IMPROVEMENT 4: ENHANCED VALIDATION SYSTEM =====
(define-map validation-rules
  (string-ascii 30)
  {
    enabled: bool,
    min-value: uint,
    max-value: uint,
    custom-logic: bool
  })

;; ===== IMPROVEMENT 5: BATCH OPERATIONS SUPPORT =====
(define-data-var max-batch-size uint u10)
(define-map batch-operation-results
  uint
  {
    operations-count: uint,
    successful-ops: uint,
    failed-ops: uint,
    total-amount: uint,
    timestamp: uint
  })

;; ===== IMPROVEMENT 6: POSITION ANALYTICS =====
(define-map position-analytics
  {user: principal, asset: principal}
  {
    average-collateral-ratio: uint,
    position-duration: uint,
    total-fees-paid: uint,
    rebalance-count: uint,
    last-activity: uint
  })

;; ===== IMPROVEMENT 7: ENHANCED ERROR TRACKING =====
(define-map error-logs
  uint
  {
    error-code: uint,
    function-name: (string-ascii 50),
    user: principal,
    timestamp: uint,
    additional-info: (string-ascii 100)
  })

(define-data-var error-log-counter uint u0)

;; ===== IMPROVEMENT 8: TIME-WEIGHTED AVERAGE PRICE (TWAP) =====
(define-map twap-data
  {asset: principal, window: uint}
  {
    cumulative-price: uint,
    last-update: uint,
    observation-count: uint,
    average-price: uint
  })

;; ===== IMPROVEMENT 9: COLLATERAL UTILIZATION TRACKING =====
(define-map collateral-utilization
  {asset: principal}
  {
    utilization-rate: uint,    ;; Percentage of debt ceiling used
    optimal-rate: uint,        ;; Target utilization rate
    efficiency-score: uint,    ;; How efficiently collateral is being used
    last-updated: uint
  })

;; ===== IMPROVEMENT 10: ENHANCED GOVERNANCE WITH PROPOSALS =====
(define-map governance-proposals
  uint
  {
    proposer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    proposal-type: (string-ascii 30),
    target-value: uint,
    votes-for: uint,
    votes-against: uint,
    voting-deadline: uint,
    execution-deadline: uint,
    executed: bool,
    cancelled: bool
  })

(define-map user-votes
  {user: principal, proposal-id: uint}
  {
    vote-power: uint,
    vote-direction: bool,
    vote-time: uint
  })

(define-data-var proposal-counter uint u0)
(define-data-var voting-period uint u1008) ;; 1 week in blocks
(define-data-var min-voting-power uint u1000) ;; Minimum tokens to vote

;; ===== MULTI-COLLATERAL SYSTEM =====
;; Supported collateral types with their parameters
(define-map collateral-types 
  {asset: principal} 
  {
    enabled: bool,
    price-feed: principal,
    collateral-ratio: uint,      ;; Required collateral ratio (150 = 150%)
    liquidation-threshold: uint, ;; Liquidation threshold (130 = 130%)
    stability-fee: uint,         ;; Annual stability fee (5 = 5%)
    debt-ceiling: uint           ;; Maximum debt for this collateral type
  })

;; User collateral positions
(define-map user-collateral-positions
  {user: principal, asset: principal}
  {
    collateral-amount: uint,
    debt-amount: uint,
    last-update: uint
  })

;; Global collateral tracking
(define-map global-collateral-stats
  {asset: principal}
  {
    total-collateral: uint,
    total-debt: uint,
    last-price: uint
  })

;; ===== ALGORITHMIC SUPPLY MANAGEMENT =====
(define-data-var target-price uint u100000000) ;; $1.00 in 8 decimal places
(define-data-var price-oracle (optional principal) none) ;; Make oracle optional
(define-data-var last-rebase-time uint u0)
(define-data-var rebase-cooldown uint u144) ;; 1 day in blocks
(define-data-var max-rebase-rate uint u10) ;; 10% max adjustment per rebase
(define-data-var rebase-threshold uint u5000000) ;; 5% price deviation threshold

;; Current price storage (manually managed for now)
(define-data-var current-price uint u100000000) ;; $1.00

;; Price stability mechanism
(define-map price-history
  uint
  {
    price: uint,
    timestamp: uint,
    supply-adjustment: int
  })

(define-data-var price-history-counter uint u0)

;; ===== CROSS-CHAIN BRIDGE SYSTEM =====
(define-map bridge-validators
  principal
  {
    active: bool,
    stake: uint,
    last-validation: uint
  })

(define-map bridge-requests
  uint
  {
    user: principal,
    amount: uint,
    target-chain: (string-ascii 20),
    target-address: (string-ascii 64),
    status: (string-ascii 10), ;; "pending", "validated", "completed", "failed"
    validators-signed: (list 10 principal),
    created-at: uint
  })

(define-data-var bridge-counter uint u0)
(define-data-var bridge-fee-rate uint u100) ;; 0.1% bridge fee
(define-data-var min-validators uint u3)

;; ===== ENHANCED SECURITY & GOVERNANCE =====
(define-map blacklisted principal bool)
(define-map last-transfer {user: principal} {time: uint, amount: uint})
(define-data-var max-transfer-amount uint u1000000)
(define-data-var transfer-cooldown uint u900)

;; Transaction logging
(define-map transaction-history
  uint
  {
    tx-type: (string-ascii 20),
    amount: uint,
    sender: principal,
    recipient: principal,
    timestamp: uint,
    additional-data: (string-ascii 100)
  })

(define-data-var tx-counter uint u0)

;; ===== HELPER FUNCTIONS =====
(define-private (is-valid-principal (address principal))
  (not (is-eq address 'SP000000000000000000002Q6VF78)))

(define-private (is-contract-owner)
  (is-eq tx-sender (var-get contract-owner)))

;; Custom min function since Clarity doesn't have built-in min
(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b))

;; Safe division function to prevent division by zero
(define-private (safe-divide (numerator uint) (denominator uint))
  (if (is-eq denominator u0)
      (err ERR-DIVISION-BY-ZERO)
      (ok (/ numerator denominator))))

;; Oracle calls are limited to known contract identifiers.
(define-private (get-stablecoin-price-from-oracle (oracle principal))
  (if (is-eq oracle .oracle)
      (contract-call? .oracle get-stablecoin-price)
      (err ERR-INVALID-IMPLEMENTATION)))

(define-private (get-asset-price-from-oracle (oracle principal))
  (if (is-eq oracle .oracle)
      (contract-call? .oracle get-price)
      (err ERR-INVALID-IMPLEMENTATION)))

;; Price fetching - uses oracle when set, falls back to stored price for testing
(define-private (get-current-price)
  (match (var-get price-oracle)
    oracle (ok (unwrap! (get-stablecoin-price-from-oracle oracle) ERR-ORACLE-ERROR))
    (ok (var-get current-price))))

;; Collateral value calculation using the configured price feed
(define-private (calculate-collateral-value (asset principal) (amount uint))
  (let ((collateral-info (unwrap! (map-get? collateral-types {asset: asset}) ERR-INVALID-COLLATERAL-TYPE))
        (oracle-price (unwrap! (get-asset-price-from-oracle (get price-feed collateral-info)) ERR-ORACLE-ERROR)))
    (ok (* amount oracle-price))))

;; Check if a collateral position is safe (used for liquidation checks)
(define-private (is-position-safe (user principal) (asset principal))
  (let ((position (default-to {collateral-amount: u0, debt-amount: u0, last-update: u0}
                   (map-get? user-collateral-positions {user: user, asset: asset})))
        (collateral-info (unwrap! (map-get? collateral-types {asset: asset}) false)))
    (if (is-eq (get debt-amount position) u0)
        true
        (let ((collateral-value (unwrap! (calculate-collateral-value asset (get collateral-amount position)) false))
              (required-collateral (* (get debt-amount position) (get collateral-ratio collateral-info))))
          (>= (* collateral-value u100) required-collateral)))))

;; ===== IMPROVEMENT 1: POSITION HEALTH SCORING FUNCTIONS =====
(define-private (calculate-health-score (user principal) (asset principal))
  (let ((position (default-to {collateral-amount: u0, debt-amount: u0, last-update: u0}
                   (map-get? user-collateral-positions {user: user, asset: asset})))
        (collateral-info (unwrap! (map-get? collateral-types {asset: asset}) u0)))
    (if (is-eq (get debt-amount position) u0)
        u100 ;; Perfect health if no debt
        (let ((collateral-value (unwrap! (calculate-collateral-value asset (get collateral-amount position)) u0))
              (debt-value (get debt-amount position))
              (collateral-ratio (if (> debt-value u0) (/ (* collateral-value u100) debt-value) u0)))
          ;; Health score based on how far above liquidation threshold
          (if (>= collateral-ratio (get liquidation-threshold collateral-info))
              (min-uint u100 (/ (* (- collateral-ratio (get liquidation-threshold collateral-info)) u100) 
                               (get liquidation-threshold collateral-info)))
              u0)))))

(define-private (update-position-health (user principal) (asset principal))
  (let ((health-score (calculate-health-score user asset))
        (risk-level (if (>= health-score u80) "low"
                       (if (>= health-score u60) "medium"
                          (if (>= health-score u30) "high" "critical"))))
        (liquidation-risk (if (> health-score u0) (- u100 health-score) u100)))
    (map-set position-health-scores {user: user, asset: asset}
      {
        health-score: health-score,
        risk-level: risk-level,
        last-calculated: stacks-block-height,
        liquidation-risk: liquidation-risk
      })
    health-score))

;; ===== IMPROVEMENT 3: FEE COLLECTION FUNCTIONS =====
(define-private (collect-protocol-fee (amount uint))
  (let ((fee-amount (/ (* amount (var-get protocol-fee-rate)) u100000)))
    (var-set accumulated-fees (+ (var-get accumulated-fees) fee-amount))
    fee-amount))

;; ===== IMPROVEMENT 7: ERROR LOGGING FUNCTION =====
(define-private (log-error (error-code uint) (function-name (string-ascii 50)) (info (string-ascii 100)))
  (begin
    (var-set error-log-counter (+ (var-get error-log-counter) u1))
    (map-set error-logs (var-get error-log-counter)
      {
        error-code: error-code,
        function-name: function-name,
        user: tx-sender,
        timestamp: stacks-block-height,
        additional-info: info
      })
    true))

;; ===== IMPROVEMENT 8: TWAP CALCULATION FUNCTIONS =====
(define-private (update-twap (asset principal) (price uint) (window uint))
  (let ((current-twap (default-to {cumulative-price: u0, last-update: u0, observation-count: u0, average-price: u0}
                       (map-get? twap-data {asset: asset, window: window})))
        (time-elapsed (- stacks-block-height (get last-update current-twap)))
        (new-cumulative (+ (get cumulative-price current-twap) (* price time-elapsed)))
        (new-count (+ (get observation-count current-twap) u1))
        (new-average (if (> time-elapsed u0) (/ new-cumulative time-elapsed) price)))
    (map-set twap-data {asset: asset, window: window}
      {
        cumulative-price: new-cumulative,
        last-update: stacks-block-height,
        observation-count: new-count,
        average-price: new-average
      })
    new-average))

;; ===== IMPROVEMENT 9: COLLATERAL UTILIZATION FUNCTIONS =====
(define-private (update-collateral-utilization (asset principal))
  (match (map-get? collateral-types {asset: asset})
    collateral-info
    (let ((global-stats (default-to {total-collateral: u0, total-debt: u0, last-price: u0}
                         (map-get? global-collateral-stats {asset: asset})))
          (utilization (if (> (get debt-ceiling collateral-info) u0)
                          (/ (* (get total-debt global-stats) u100) (get debt-ceiling collateral-info))
                          u0))
          (efficiency (if (> (get total-collateral global-stats) u0)
                         (/ (* (get total-debt global-stats) u100) (get total-collateral global-stats))
                         u0)))
      (map-set collateral-utilization {asset: asset}
        {
          utilization-rate: utilization,
          optimal-rate: u80, ;; 80% target utilization
          efficiency-score: efficiency,
          last-updated: stacks-block-height
        })
      utilization)
    ;; If collateral type doesn't exist, return 0
    u0))

;; ===== UTILITY FUNCTIONS =====
;; Modified log-transaction to not return a response to avoid type issues
(define-private (log-transaction 
  (tx-type (string-ascii 20)) 
  (amount uint) 
  (sender principal) 
  (recipient principal) 
  (additional-data (string-ascii 100)))
  (begin
    (var-set tx-counter (+ (var-get tx-counter) u1))
    (map-set transaction-history (var-get tx-counter)
      {
        tx-type: tx-type,
        amount: amount,
        sender: sender,
        recipient: recipient,
        timestamp: stacks-block-height,
        additional-data: additional-data
      })
    true)) ;; Return bool instead of response

;; ===== INITIALIZATION =====
(define-public (initialize)
  (begin
    (asserts! (not (var-get initialized)) ERR-ALREADY-INITIALIZED)
    (var-set initialized true)
    (var-set contract-owner tx-sender)
    (var-set last-rebase-time stacks-block-height)
    ;; Initialize fee distribution
    (map-set fee-distribution "protocol" {percentage: u5000, accumulated: u0, last-distribution: u0}) ;; 50%
    (map-set fee-distribution "rewards" {percentage: u3000, accumulated: u0, last-distribution: u0})   ;; 30%
    (map-set fee-distribution "treasury" {percentage: u2000, accumulated: u0, last-distribution: u0})  ;; 20%
    ;; Oracle is optional and can be set later
    (ok true)))

;; ===== ORACLE MANAGEMENT =====
(define-public (set-price-oracle (new-oracle principal))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-principal new-oracle) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq new-oracle .oracle) ERR-INVALID-IMPLEMENTATION)
    (var-set price-oracle (some new-oracle))
    (ok true)))

(define-public (remove-price-oracle)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (var-set price-oracle none)
    (ok true)))

(define-public (set-current-price (new-price uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-AMOUNT)
    (asserts! (<= new-price u1000000000000) ERR-INVALID-AMOUNT) ;; Max price validation
    (var-set current-price new-price)
    (ok true)))

;; ===== COLLATERAL MANAGEMENT =====
(define-public (add-collateral-type 
  (asset principal) 
  (price-feed principal) 
  (collateral-ratio uint) 
  (liquidation-threshold uint) 
  (stability-fee uint) 
  (debt-ceiling uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-valid-principal asset) ERR-INVALID-RECIPIENT)
    (asserts! (is-valid-principal price-feed) ERR-INVALID-RECIPIENT)
    (asserts! (is-eq price-feed .oracle) ERR-INVALID-IMPLEMENTATION)
    (asserts! (and (>= collateral-ratio u100) (<= collateral-ratio u300)) ERR-INVALID-AMOUNT)
    (asserts! (and (>= liquidation-threshold u100) (< liquidation-threshold collateral-ratio)) ERR-INVALID-AMOUNT)
    (asserts! (<= stability-fee u100) ERR-INVALID-AMOUNT) ;; Max 100% annual fee
    (asserts! (> debt-ceiling u0) ERR-INVALID-AMOUNT)
    
    (map-set collateral-types {asset: asset}
      {
        enabled: true,
        price-feed: price-feed,
        collateral-ratio: collateral-ratio,
        liquidation-threshold: liquidation-threshold,
        stability-fee: stability-fee,
        debt-ceiling: debt-ceiling
      })
    
    (map-set global-collateral-stats {asset: asset}
      {total-collateral: u0, total-debt: u0, last-price: u0})
    
    ;; Initialize collateral utilization tracking
    (update-collateral-utilization asset)
    
    (ok true)))

(define-public (deposit-collateral-and-mint (asset principal) (collateral-amount uint) (mint-amount uint))
  (let ((collateral-info (unwrap! (map-get? collateral-types {asset: asset}) ERR-INVALID-COLLATERAL-TYPE))
        (current-position (default-to {collateral-amount: u0, debt-amount: u0, last-update: u0}
                          (map-get? user-collateral-positions {user: tx-sender, asset: asset})))
        (collateral-value (unwrap! (calculate-collateral-value asset collateral-amount) ERR-ORACLE-ERROR))
        (total-debt (+ (get debt-amount current-position) mint-amount))
        (required-collateral (* total-debt (get collateral-ratio collateral-info)))
        (protocol-fee (collect-protocol-fee mint-amount)))
    
    (begin
      (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
      (asserts! (not (var-get transfer-paused)) ERR-TRANSFER-PAUSED)
      (asserts! (get enabled collateral-info) ERR-INVALID-COLLATERAL-TYPE)
      (asserts! (> collateral-amount u0) ERR-INVALID-AMOUNT)
      (asserts! (> mint-amount u0) ERR-INVALID-AMOUNT)
      (asserts! (<= (+ (var-get total-supply) mint-amount) (var-get max-supply)) ERR-MAX-SUPPLY-REACHED)
      
      ;; Check collateralization ratio
      (asserts! (>= (* collateral-value u100) required-collateral) ERR-INSUFFICIENT-COLLATERAL)
      
      ;; Check debt ceiling
      (let ((global-stats (default-to {total-collateral: u0, total-debt: u0, last-price: u0}
                          (map-get? global-collateral-stats {asset: asset}))))
        (asserts! (<= (+ (get total-debt global-stats) mint-amount) (get debt-ceiling collateral-info)) 
                  ERR-MAX-SUPPLY-REACHED))
      
      ;; For now, skip the actual collateral transfer (would need SIP-010 trait implementation)
      ;; (try! (contract-call? asset transfer collateral-amount tx-sender (as-contract tx-sender)))
      
      ;; Update user position
      (map-set user-collateral-positions {user: tx-sender, asset: asset}
        {
          collateral-amount: (+ (get collateral-amount current-position) collateral-amount),
          debt-amount: total-debt,
          last-update: stacks-block-height
        })
      
      ;; Update global stats
      (let ((global-stats (default-to {total-collateral: u0, total-debt: u0, last-price: u0}
                          (map-get? global-collateral-stats {asset: asset}))))
        (map-set global-collateral-stats {asset: asset}
          {
            total-collateral: (+ (get total-collateral global-stats) collateral-amount),
            total-debt: (+ (get total-debt global-stats) mint-amount),
            last-price: (get last-price global-stats)
          }))
      
      ;; Update position health score
      (update-position-health tx-sender asset)
      
      ;; Update collateral utilization
      (update-collateral-utilization asset)
      
      ;; Update position analytics
      (let ((analytics (default-to {average-collateral-ratio: u0, position-duration: u0, total-fees-paid: u0, rebalance-count: u0, last-activity: u0}
                        (map-get? position-analytics {user: tx-sender, asset: asset}))))
        (map-set position-analytics {user: tx-sender, asset: asset}
          (merge analytics {
            total-fees-paid: (+ (get total-fees-paid analytics) protocol-fee),
            rebalance-count: (+ (get rebalance-count analytics) u1),
            last-activity: stacks-block-height
          })))
      
      ;; Mint stablecoins
      (var-set total-supply (+ (var-get total-supply) mint-amount))
      (try! (ft-mint? stablecoin mint-amount tx-sender))
      
      ;; Log transaction
      (log-transaction "collateral-mint" mint-amount tx-sender tx-sender "collateral-deposit")
      
      (ok true))))

(define-public (repay-debt-and-withdraw (asset principal) (repay-amount uint) (withdraw-amount uint))
  (let ((current-position (unwrap! (map-get? user-collateral-positions {user: tx-sender, asset: asset}) 
                          ERR-INSUFFICIENT-BALANCE))
        (collateral-info (unwrap! (map-get? collateral-types {asset: asset}) ERR-INVALID-COLLATERAL-TYPE))
        (new-debt (- (get debt-amount current-position) repay-amount))
        (new-collateral (- (get collateral-amount current-position) withdraw-amount)))
    
    (begin
      (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
      (asserts! (>= (get debt-amount current-position) repay-amount) ERR-INVALID-AMOUNT)
      (asserts! (>= (get collateral-amount current-position) withdraw-amount) ERR-INVALID-AMOUNT)
      (asserts! (>= (ft-get-balance stablecoin tx-sender) repay-amount) ERR-INSUFFICIENT-BALANCE)
      
      ;; Check if remaining position is safe (if any debt remains)
      (if (> new-debt u0)
          (let ((remaining-collateral-value (unwrap! (calculate-collateral-value asset new-collateral) ERR-ORACLE-ERROR))
                (required-collateral (* new-debt (get collateral-ratio collateral-info))))
            (asserts! (>= (* remaining-collateral-value u100) required-collateral) ERR-INSUFFICIENT-COLLATERAL))
          true)
      
      ;; Burn repaid stablecoins
      (try! (ft-burn? stablecoin repay-amount tx-sender))
      (var-set total-supply (- (var-get total-supply) repay-amount))
      
      ;; Update position
      (if (and (is-eq new-debt u0) (is-eq new-collateral u0))
          (map-delete user-collateral-positions {user: tx-sender, asset: asset})
          (map-set user-collateral-positions {user: tx-sender, asset: asset}
            {
              collateral-amount: new-collateral,
              debt-amount: new-debt,
              last-update: stacks-block-height
            }))
      
      ;; Update global stats
      (let ((global-stats (unwrap-panic (map-get? global-collateral-stats {asset: asset}))))
        (map-set global-collateral-stats {asset: asset}
          {
            total-collateral: (- (get total-collateral global-stats) withdraw-amount),
            total-debt: (- (get total-debt global-stats) repay-amount),
            last-price: (get last-price global-stats)
          }))
      
      ;; Update position health score
      (if (> new-debt u0)
          (begin
            (update-position-health tx-sender asset)
            true)
          (begin
            (map-delete position-health-scores {user: tx-sender, asset: asset})
            true))
      
      ;; Update collateral utilization
      (update-collateral-utilization asset)
      
      ;; Log transaction
      (log-transaction "debt-repay" repay-amount tx-sender tx-sender "collateral-withdraw")
      
      (ok true))))

;; ===== IMPROVEMENT 2: ENHANCED LIQUIDATION WITH REWARDS =====
(define-public (liquidate-position (user principal) (asset principal))
  (let ((position (unwrap! (map-get? user-collateral-positions {user: user, asset: asset}) ERR-INSUFFICIENT-BALANCE))
        (collateral-info (unwrap! (map-get? collateral-types {asset: asset}) ERR-INVALID-COLLATERAL-TYPE))
        (liquidator-rewards (default-to {total-rewards: u0, successful-liquidations: u0, last-liquidation: u0}
                            (map-get? liquidation-rewards tx-sender))))
    
    (begin
      (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
      (asserts! (not (var-get emergency-mode)) ERR-TRANSFER-PAUSED)
      (asserts! (> (get debt-amount position) u0) ERR-INVALID-AMOUNT)
      
      ;; Check if position is below liquidation threshold
      (let ((collateral-value (unwrap! (calculate-collateral-value asset (get collateral-amount position)) ERR-ORACLE-ERROR))
            (liquidation-value (* (get debt-amount position) (get liquidation-threshold collateral-info)))
            (liquidation-bonus (/ (* (get debt-amount position) (var-get liquidation-bonus-rate)) u10000)))
        
        (asserts! (< (* collateral-value u100) liquidation-value) ERR-LIQUIDATION-THRESHOLD)
        
        ;; Calculate liquidator reward
        (let ((reward-amount (min-uint liquidation-bonus (/ (get collateral-amount position) u10))))
          
          ;; Liquidate the position
          (map-delete user-collateral-positions {user: user, asset: asset})
          
          ;; Update global stats
          (let ((global-stats (unwrap-panic (map-get? global-collateral-stats {asset: asset}))))
            (map-set global-collateral-stats {asset: asset}
              {
                total-collateral: (- (get total-collateral global-stats) (get collateral-amount position)),
                total-debt: (- (get total-debt global-stats) (get debt-amount position)),
                last-price: (get last-price global-stats)
              }))
          
          ;; Update liquidator rewards
          (map-set liquidation-rewards tx-sender
            {
              total-rewards: (+ (get total-rewards liquidator-rewards) reward-amount),
              successful-liquidations: (+ (get successful-liquidations liquidator-rewards) u1),
              last-liquidation: stacks-block-height
            })
          
          ;; Mint reward to liquidator
          (if (> reward-amount u0)
              (begin
                (var-set total-supply (+ (var-get total-supply) reward-amount))
                (try! (ft-mint? stablecoin reward-amount tx-sender)))
              true)
          
          ;; Burn the debt from total supply
          (var-set total-supply (- (var-get total-supply) (get debt-amount position)))
          
          ;; Clean up position health score
          (map-delete position-health-scores {user: user, asset: asset})
          
          ;; Update collateral utilization
          (update-collateral-utilization asset)
          
          ;; Log liquidation
          (log-transaction "liquidation" (get debt-amount position) user tx-sender "position-liquidated")
          
          (ok true))))))

;; ===== IMPROVEMENT 5: BATCH OPERATIONS =====
(define-public (batch-deposit-and-mint (operations (list 10 {asset: principal, collateral-amount: uint, mint-amount: uint})))
  (let ((batch-id (+ (var-get tx-counter) u1))
        (operations-count (len operations)))
    (begin
      (asserts! (<= operations-count (var-get max-batch-size)) ERR-BATCH-LIMIT-EXCEEDED)
      (asserts! (> operations-count u0) ERR-INVALID-AMOUNT)
      
      ;; Process each operation
      (let ((results (fold batch-process-deposit operations {successful: u0, failed: u0, total-amount: u0})))
        
        ;; Log batch operation
        (map-set batch-operation-results batch-id
          {
            operations-count: operations-count,
            successful-ops: (get successful results),
            failed-ops: (get failed results),
            total-amount: (get total-amount results),
            timestamp: stacks-block-height
          })
        
        (ok {
          batch-id: batch-id,
          successful: (get successful results),
          failed: (get failed results)
        })))))

(define-private (batch-process-deposit 
  (operation {asset: principal, collateral-amount: uint, mint-amount: uint})
  (acc {successful: uint, failed: uint, total-amount: uint}))
  (match (deposit-collateral-and-mint (get asset operation) (get collateral-amount operation) (get mint-amount operation))
    success {
      successful: (+ (get successful acc) u1),
      failed: (get failed acc),
      total-amount: (+ (get total-amount acc) (get mint-amount operation))
    }
    error {
      successful: (get successful acc),
      failed: (+ (get failed acc) u1),
      total-amount: (get total-amount acc)
    }))

;; ===== ALGORITHMIC SUPPLY MANAGEMENT =====
(define-public (rebase-supply)
  (let ((price-now (unwrap! (get-current-price) ERR-ORACLE-ERROR))
        (target-value (var-get target-price))
        (time-since-last (- stacks-block-height (var-get last-rebase-time))))
    
    (begin
      (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
      (asserts! (>= time-since-last (var-get rebase-cooldown)) ERR-COOLDOWN-ACTIVE)
      (asserts! (> target-value u0) ERR-DIVISION-BY-ZERO) ;; Prevent division by zero
      
      (let ((price-deviation (if (> price-now target-value)
                               (- price-now target-value)
                               (- target-value price-now)))
            (deviation-percentage (unwrap! (safe-divide (* price-deviation u100) target-value) ERR-DIVISION-BY-ZERO)))
        
        ;; Only rebase if deviation exceeds threshold
        (if (>= deviation-percentage (var-get rebase-threshold))
            (let ((adjustment-rate (min-uint (var-get max-rebase-rate) 
                                            (unwrap! (safe-divide deviation-percentage u2) ERR-DIVISION-BY-ZERO)))
                  (supply-now (var-get total-supply))
                  (adjustment-amount (unwrap! (safe-divide (* supply-now adjustment-rate) u100) ERR-DIVISION-BY-ZERO)))
              
              (begin
                ;; Record price history
                (var-set price-history-counter (+ (var-get price-history-counter) u1))
                (map-set price-history (var-get price-history-counter)
                  {
                    price: price-now,
                    timestamp: stacks-block-height,
                    supply-adjustment: (if (> price-now target-value) 
                                         (to-int adjustment-amount)
                                         (- (to-int adjustment-amount)))
                  })
                
                ;; Adjust supply based on price deviation
                (let ((supply-result 
                       (if (> price-now target-value)
                           ;; Price too high, increase supply
                           (begin
                             (asserts! (<= (+ supply-now adjustment-amount) (var-get max-supply)) ERR-MAX-SUPPLY-REACHED)
                             (var-set total-supply (+ supply-now adjustment-amount))
                             (ft-mint? stablecoin adjustment-amount (var-get contract-owner)))
                           ;; Price too low, decrease supply (if possible)
                           (if (>= (ft-get-balance stablecoin (var-get contract-owner)) adjustment-amount)
                               (begin
                                 (var-set total-supply (- supply-now adjustment-amount))
                                 (as-contract (ft-burn? stablecoin adjustment-amount tx-sender)))
                               (ok true)))))
                  
                  ;; Check if supply adjustment succeeded
                  (match supply-result
                    success (begin
                              (var-set last-rebase-time stacks-block-height)
                              (log-transaction "rebase" adjustment-amount (var-get contract-owner) (var-get contract-owner) "supply-adjustment")
                              (ok true))
                    error (err error)))))
            ;; Else clause: deviation is below threshold, no rebase needed
            (ok false))))))

;; ===== MANUAL PRICE MANAGEMENT (for testing without oracle) =====
(define-public (manual-set-price (new-price uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-AMOUNT)
    (asserts! (<= new-price u1000000000000) ERR-INVALID-AMOUNT) ;; Max price validation
    (var-set current-price new-price)
    (ok true)))

;; ===== CROSS-CHAIN BRIDGE =====
(define-public (add-bridge-validator (validator principal) (stake-amount uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-principal validator) ERR-INVALID-RECIPIENT)
    (asserts! (> stake-amount u0) ERR-INVALID-AMOUNT)
    
    (map-set bridge-validators validator
      {
        active: true,
        stake: stake-amount,
        last-validation: u0
      })
    (ok true)))

(define-public (initiate-bridge-transfer (amount uint) (target-chain (string-ascii 20)) (target-address (string-ascii 64)))
  (let ((bridge-fee (unwrap! (safe-divide (* amount (var-get bridge-fee-rate)) u100000) ERR-DIVISION-BY-ZERO))
        (bridge-amount (- amount bridge-fee)))
    
    (begin
      (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
      (asserts! (not (var-get transfer-paused)) ERR-TRANSFER-PAUSED)
      (asserts! (> amount bridge-fee) ERR-INVALID-AMOUNT)
      (asserts! (>= (ft-get-balance stablecoin tx-sender) amount) ERR-INSUFFICIENT-BALANCE)
      (asserts! (> (len target-chain) u0) ERR-INVALID-AMOUNT)
      (asserts! (> (len target-address) u0) ERR-INVALID-AMOUNT)
      
      ;; Burn tokens (they will be minted on target chain)
      (try! (ft-burn? stablecoin amount tx-sender))
      (var-set total-supply (- (var-get total-supply) amount))
      
      ;; Create bridge request
      (var-set bridge-counter (+ (var-get bridge-counter) u1))
      (map-set bridge-requests (var-get bridge-counter)
        {
          user: tx-sender,
          amount: bridge-amount,
          target-chain: target-chain,
          target-address: target-address,
          status: "pending",
          validators-signed: (list),
          created-at: stacks-block-height
        })
      
      ;; Log transaction
      (log-transaction "bridge-out" amount tx-sender tx-sender "cross-chain-transfer")
      
      (print {
        event: "bridge-initiated",
        request-id: (var-get bridge-counter),
        user: tx-sender,
        amount: bridge-amount,
        target-chain: target-chain,
        target-address: target-address
      })
      
      (ok (var-get bridge-counter)))))

(define-public (validate-bridge-request (request-id uint))
  (let ((request (unwrap! (map-get? bridge-requests request-id) ERR-BRIDGE-ERROR))
        (validator-info (unwrap! (map-get? bridge-validators tx-sender) ERR-NOT-AUTHORIZED)))
    
    (begin
      (asserts! (get active validator-info) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get status request) "pending") ERR-BRIDGE-ERROR)
      
      ;; Add validator signature
      (let ((current-signatures (get validators-signed request))
            (new-signatures (unwrap! (as-max-len? (append current-signatures tx-sender) u10) ERR-BRIDGE-ERROR)))
        
        (map-set bridge-requests request-id
          (merge request {validators-signed: new-signatures}))
        
        ;; Check if we have enough validations
        (if (>= (len new-signatures) (var-get min-validators))
            (map-set bridge-requests request-id
              (merge request {status: "validated", validators-signed: new-signatures}))
            true)
        
        ;; Update validator stats
        (map-set bridge-validators tx-sender
          (merge validator-info {last-validation: stacks-block-height}))
        
        (ok true)))))

(define-public (complete-bridge-in (request-id uint) (user principal) (amount uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED) ;; In production, this would be called by bridge validators
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (is-valid-principal user) ERR-INVALID-RECIPIENT)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (<= (+ (var-get total-supply) amount) (var-get max-supply)) ERR-MAX-SUPPLY-REACHED)
    
    ;; Mint tokens for incoming bridge transfer
    (var-set total-supply (+ (var-get total-supply) amount))
    (try! (ft-mint? stablecoin amount user))
    
    ;; Log transaction
    (log-transaction "bridge-in" amount (var-get contract-owner) user "incoming-transfer")
    
    (print {
      event: "bridge-completed",
      request-id: request-id,
      user: user,
      amount: amount
    })
    
    (ok true)))

;; ===== ENHANCED TRANSFER FUNCTIONS =====
(define-public (transfer (amount uint) (recipient principal))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (not (var-get transfer-paused)) ERR-TRANSFER-PAUSED)
    (asserts! (not (var-get emergency-mode)) ERR-TRANSFER-PAUSED)
    (asserts! (is-valid-principal recipient) ERR-INVALID-RECIPIENT)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= (ft-get-balance stablecoin tx-sender) amount) ERR-INSUFFICIENT-BALANCE)
    
    ;; Blacklist checks
    (asserts! (not (default-to false (map-get? blacklisted tx-sender))) ERR-BLACKLISTED)
    (asserts! (not (default-to false (map-get? blacklisted recipient))) ERR-BLACKLISTED)
    
    ;; Rate limiting
    (let ((last-tx (default-to {time: u0, amount: u0} (map-get? last-transfer {user: tx-sender}))))
      (asserts! (>= (- stacks-block-height (get time last-tx)) (var-get transfer-cooldown)) ERR-COOLDOWN-ACTIVE)
      (asserts! (<= amount (var-get max-transfer-amount)) ERR-INVALID-AMOUNT))
    
    ;; Update rate limiting
    (map-set last-transfer {user: tx-sender} {time: stacks-block-height, amount: amount})
    
    ;; Execute transfer
    (try! (ft-transfer? stablecoin amount tx-sender recipient))
    
    ;; Log transaction
    (log-transaction "transfer" amount tx-sender recipient "")
    
    (ok true)))

;; ===== IMPROVEMENT 10: ENHANCED GOVERNANCE WITH PROPOSALS =====
(define-public (create-proposal 
  (title (string-ascii 100)) 
  (description (string-ascii 500)) 
  (proposal-type (string-ascii 30)) 
  (target-value uint))
  (begin
    (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
    (asserts! (>= (ft-get-balance stablecoin tx-sender) (var-get min-voting-power)) ERR-INSUFFICIENT-VOTING-POWER)
    (asserts! (> (len title) u0) ERR-INVALID-AMOUNT)
    (asserts! (> (len description) u0) ERR-INVALID-AMOUNT)
    
    (var-set proposal-counter (+ (var-get proposal-counter) u1))
    (map-set governance-proposals (var-get proposal-counter)
      {
        proposer: tx-sender,
        title: title,
        description: description,
        proposal-type: proposal-type,
        target-value: target-value,
        votes-for: u0,
        votes-against: u0,
        voting-deadline: (+ stacks-block-height (var-get voting-period)),
        execution-deadline: (+ stacks-block-height (* (var-get voting-period) u2)),
        executed: false,
        cancelled: false
      })
    
    (ok (var-get proposal-counter))))

(define-public (vote-on-proposal (proposal-id uint) (vote-for bool))
  (let ((proposal (unwrap! (map-get? governance-proposals proposal-id) ERR-PROPOSAL-NOT-FOUND))
        (voting-power (ft-get-balance stablecoin tx-sender))
        (existing-vote (map-get? user-votes {user: tx-sender, proposal-id: proposal-id})))
    
    (begin
      (asserts! (var-get initialized) ERR-NOT-INITIALIZED)
      (asserts! (>= voting-power (var-get min-voting-power)) ERR-INSUFFICIENT-VOTING-POWER)
      (asserts! (<= stacks-block-height (get voting-deadline proposal)) ERR-VOTING-PERIOD-ENDED)
      (asserts! (not (get executed proposal)) ERR-INVALID-GOVERNANCE-ACTION)
      (asserts! (not (get cancelled proposal)) ERR-INVALID-GOVERNANCE-ACTION)
      (asserts! (is-none existing-vote) ERR-INVALID-GOVERNANCE-ACTION) ;; Prevent double voting
      
      ;; Record vote
      (map-set user-votes {user: tx-sender, proposal-id: proposal-id}
        {
          vote-power: voting-power,
          vote-direction: vote-for,
          vote-time: stacks-block-height
        })
      
      ;; Update proposal vote counts
      (map-set governance-proposals proposal-id
        (merge proposal {
          votes-for: (if vote-for (+ (get votes-for proposal) voting-power) (get votes-for proposal)),
          votes-against: (if vote-for (get votes-against proposal) (+ (get votes-against proposal) voting-power))
        }))
      
      (ok true))))

;; ===== EMERGENCY FUNCTIONS =====
(define-public (enable-emergency-mode)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (var-set emergency-mode true)
    (var-set transfer-paused true)
    (log-transaction "emergency" u0 tx-sender tx-sender "mode-enabled")
    (ok true)))

(define-public (disable-emergency-mode)
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (var-set emergency-mode false)
    (var-set transfer-paused false)
    (log-transaction "emergency" u0 tx-sender tx-sender "mode-disabled")
    (ok true)))

;; ===== READ-ONLY FUNCTIONS =====
(define-read-only (get-user-position (user principal) (asset principal))
  (ok (map-get? user-collateral-positions {user: user, asset: asset})))

(define-read-only (get-collateral-info (asset principal))
  (ok (map-get? collateral-types {asset: asset})))

(define-read-only (get-global-stats (asset principal))
  (ok (map-get? global-collateral-stats {asset: asset})))

(define-read-only (get-bridge-request (request-id uint))
  (ok (map-get? bridge-requests request-id)))

(define-read-only (get-price-history (index uint))
  (ok (map-get? price-history index)))

(define-read-only (balance-of (who principal))
  (ok (ft-get-balance stablecoin who)))

(define-read-only (get-total-supply)
  (ok (var-get total-supply)))

(define-read-only (get-contract-owner)
  (ok (var-get contract-owner)))

(define-read-only (is-initialized)
  (ok (var-get initialized)))

(define-read-only (get-transaction-history (tx-id uint))
  (ok (map-get? transaction-history tx-id)))

;; Read-only function that returns current price
(define-read-only (get-current-stablecoin-price)
  (ok (var-get current-price)))

(define-read-only (get-oracle-info)
  (ok {
    oracle: (var-get price-oracle),
    current-price: (var-get current-price),
    target-price: (var-get target-price)
  }))

;; Check if a position is safe for liquidation
(define-read-only (check-position-safety (user principal) (asset principal))
  (ok (is-position-safe user asset)))

;; ===== NEW READ-ONLY FUNCTIONS FOR IMPROVEMENTS =====

;; IMPROVEMENT 1: Position Health Score
(define-read-only (get-position-health (user principal) (asset principal))
  (ok (map-get? position-health-scores {user: user, asset: asset})))

;; IMPROVEMENT 2: Liquidation Rewards
(define-read-only (get-liquidation-rewards (liquidator principal))
  (ok (map-get? liquidation-rewards liquidator)))

;; IMPROVEMENT 3: Fee Information
(define-read-only (get-accumulated-fees)
  (ok (var-get accumulated-fees)))

(define-read-only (get-fee-distribution (category (string-ascii 20)))
  (ok (map-get? fee-distribution category)))

;; IMPROVEMENT 5: Batch Operation Results
(define-read-only (get-batch-operation-result (batch-id uint))
  (ok (map-get? batch-operation-results batch-id)))

;; IMPROVEMENT 6: Position Analytics
(define-read-only (get-position-analytics (user principal) (asset principal))
  (ok (map-get? position-analytics {user: user, asset: asset})))

;; IMPROVEMENT 7: Error Logs
(define-read-only (get-error-log (log-id uint))
  (ok (map-get? error-logs log-id)))

;; IMPROVEMENT 8: TWAP Data
(define-read-only (get-twap-data (asset principal) (window uint))
  (ok (map-get? twap-data {asset: asset, window: window})))

;; IMPROVEMENT 9: Collateral Utilization
(define-read-only (get-collateral-utilization (asset principal))
  (ok (map-get? collateral-utilization {asset: asset})))

;; IMPROVEMENT 10: Governance Proposals
(define-read-only (get-proposal (proposal-id uint))
  (ok (map-get? governance-proposals proposal-id)))

(define-read-only (get-user-vote (user principal) (proposal-id uint))
  (ok (map-get? user-votes {user: user, proposal-id: proposal-id})))

;; ===== GOVERNANCE FUNCTIONS =====
(define-public (update-rebase-parameters (new-threshold uint) (new-max-rate uint) (new-cooldown uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (and (> new-threshold u0) (<= new-threshold u50)) ERR-INVALID-AMOUNT) ;; 0-50% threshold
    (asserts! (and (> new-max-rate u0) (<= new-max-rate u25)) ERR-INVALID-AMOUNT)  ;; 0-25% adjustment
    (asserts! (>= new-cooldown u72) ERR-INVALID-AMOUNT)  ;; Min 12 hours
    
    (var-set rebase-threshold new-threshold)
    (var-set max-rebase-rate new-max-rate)
    (var-set rebase-cooldown new-cooldown)
    (ok true)))

(define-public (update-bridge-parameters (new-fee-rate uint) (new-min-validators uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-fee-rate u1000) ERR-INVALID-AMOUNT) ;; Max 1% fee
    (asserts! (and (>= new-min-validators u1) (<= new-min-validators u10)) ERR-INVALID-AMOUNT)
    
    (var-set bridge-fee-rate new-fee-rate)
    (var-set min-validators new-min-validators)
    (ok true)))

(define-public (blacklist-address (address principal) (blacklist bool))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (is-valid-principal address) ERR-INVALID-RECIPIENT)
    (map-set blacklisted address blacklist)
    (ok true)))

(define-public (update-transfer-limits (new-max-amount uint) (new-cooldown uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (> new-max-amount u0) ERR-INVALID-AMOUNT)
    (asserts! (>= new-cooldown u1) ERR-INVALID-AMOUNT) ;; Min 1 block cooldown
    
    (var-set max-transfer-amount new-max-amount)
    (var-set transfer-cooldown new-cooldown)
    (ok true)))

;; ===== NEW GOVERNANCE FUNCTIONS FOR IMPROVEMENTS =====

;; IMPROVEMENT 2: Update liquidation parameters
(define-public (update-liquidation-parameters (new-bonus-rate uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-bonus-rate u2000) ERR-INVALID-AMOUNT) ;; Max 20% bonus
    (var-set liquidation-bonus-rate new-bonus-rate)
    (ok true)))

;; IMPROVEMENT 3: Update fee parameters
(define-public (update-fee-parameters (new-protocol-fee uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-protocol-fee u1000) ERR-INVALID-AMOUNT) ;; Max 1% fee
    (var-set protocol-fee-rate new-protocol-fee)
    (ok true)))

;; IMPROVEMENT 5: Update batch parameters
(define-public (update-batch-parameters (new-max-batch-size uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (and (> new-max-batch-size u0) (<= new-max-batch-size u50)) ERR-INVALID-AMOUNT)
    (var-set max-batch-size new-max-batch-size)
    (ok true)))

;; IMPROVEMENT 10: Update governance parameters
(define-public (update-governance-parameters (new-voting-period uint) (new-min-voting-power uint))
  (begin
    (asserts! (is-contract-owner) ERR-NOT-AUTHORIZED)
    (asserts! (>= new-voting-period u144) ERR-INVALID-AMOUNT) ;; Min 1 day
    (asserts! (> new-min-voting-power u0) ERR-INVALID-AMOUNT)
    
    (var-set voting-period new-voting-period)
    (var-set min-voting-power new-min-voting-power)
    (ok true)))
