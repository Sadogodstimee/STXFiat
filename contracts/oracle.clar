;; Mock Price Oracle Contract for Local Development

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PRICE (err u101))
(define-constant ERR-PRICE-DEVIATION (err u102))
(define-constant ERR-UPDATE-TOO-SOON (err u103))

;; Contract owner
(define-data-var contract-owner principal tx-sender)

;; Mock price data (in 8 decimal places)
(define-data-var stablecoin-price uint u100000000) ;; $1.00
(define-data-var btc-price uint u4500000000000) ;; $45,000.00
(define-data-var stx-price uint u200000000) ;; $2.00

;; Price update timestamp
(define-data-var last-update uint u0)

;; Price history for testing
(define-map price-history uint uint)
(define-data-var price-counter uint u0)

;; New validation parameters
(define-data-var max-price-deviation uint u1000) ;; 10% max deviation (in basis points)
(define-data-var min-update-delay uint u100) ;; Minimum blocks between updates
(define-data-var trusted-sources (list 10 principal) (list))

;; ===== VALIDATION FUNCTIONS =====
(define-private (validate-price-change (new-price uint) (old-price uint))
  (let ((deviation (if (> new-price old-price)
                      (/ (* (- new-price old-price) u10000) old-price)
                      (/ (* (- old-price new-price) u10000) old-price))))
    (<= deviation (var-get max-price-deviation))))

(define-private (can-update-price)
  (>= (- stacks-block-height (var-get last-update)) (var-get min-update-delay)))

;; ===== ADMIN FUNCTIONS =====
(define-public (set-stablecoin-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (asserts! (can-update-price) ERR-UPDATE-TOO-SOON)
    (asserts! (validate-price-change new-price (var-get stablecoin-price)) ERR-PRICE-DEVIATION)
    (var-set stablecoin-price new-price)
    (var-set last-update stacks-block-height)
    (var-set price-counter (+ (var-get price-counter) u1))
    (map-set price-history (var-get price-counter) new-price)
    (ok true)))

(define-public (set-btc-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (asserts! (can-update-price) ERR-UPDATE-TOO-SOON)
    (asserts! (validate-price-change new-price (var-get btc-price)) ERR-PRICE-DEVIATION)
    (var-set btc-price new-price)
    (var-set last-update stacks-block-height)
    (ok true)))

(define-public (set-stx-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (asserts! (can-update-price) ERR-UPDATE-TOO-SOON)
    (asserts! (validate-price-change new-price (var-get stx-price)) ERR-PRICE-DEVIATION)
    (var-set stx-price new-price)
    (var-set last-update stacks-block-height)
    (ok true)))

;; Emergency price update (bypasses validation for owner)
(define-public (emergency-set-price (asset-type uint) (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (if (is-eq asset-type u0)
        (var-set stablecoin-price new-price)
        (if (is-eq asset-type u1)
            (var-set btc-price new-price)
            (var-set stx-price new-price)))
    (var-set last-update stacks-block-height)
    (ok true)))

;; ===== CONFIGURATION FUNCTIONS =====
(define-public (set-max-deviation (new-deviation uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (<= new-deviation u5000) ERR-INVALID-PRICE) ;; Max 50% deviation
    (var-set max-price-deviation new-deviation)
    (ok true)))

(define-public (set-min-update-delay (new-delay uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (var-set min-update-delay new-delay)
    (ok true)))

(define-public (add-trusted-source (source principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (let ((current-sources (var-get trusted-sources)))
      (var-set trusted-sources (unwrap! (as-max-len? (append current-sources source) u10) ERR-INVALID-PRICE))
      (ok true))))

(define-public (remove-trusted-source (source principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (let ((current-sources (var-get trusted-sources)))
      (var-set trusted-sources (filter is-not-source current-sources))
      (ok true))))

(define-private (is-not-source (item principal))
  (not (is-eq item (var-get contract-owner)))) ;; Placeholder for actual source comparison

;; ===== PUBLIC PRICE FUNCTIONS =====
(define-read-only (get-stablecoin-price)
  (ok (var-get stablecoin-price)))

(define-read-only (get-price)
  (ok (var-get stablecoin-price)))

(define-read-only (get-btc-price)
  (ok (var-get btc-price)))

(define-read-only (get-stx-price)
  (ok (var-get stx-price)))

(define-read-only (get-last-update)
  (ok (var-get last-update)))

(define-read-only (get-price-history (index uint))
  (ok (map-get? price-history index)))

(define-read-only (get-max-deviation)
  (ok (var-get max-price-deviation)))

(define-read-only (get-min-update-delay)
  (ok (var-get min-update-delay)))

(define-read-only (get-trusted-sources)
  (ok (var-get trusted-sources)))

;; ===== UTILITY FUNCTIONS =====
(define-public (simulate-price-fluctuation)
  (let ((current-price (var-get stablecoin-price))
        (random-factor (mod stacks-block-height u20))) ;; Simple randomness
    (begin
      ;; Simulate price movement between $0.95 and $1.05
      (if (< random-factor u10)
          (var-set stablecoin-price (+ u95000000 (mod stacks-block-height u10000000)))
          (var-set stablecoin-price (+ u100000000 (mod stacks-block-height u5000000))))
      (var-set last-update stacks-block-height)
      (ok (var-get stablecoin-price)))))

;; Validate if price update is within acceptable range
(define-read-only (is-price-update-valid (asset-type uint) (new-price uint))
  (let ((current-price (if (is-eq asset-type u0)
                          (var-get stablecoin-price)
                          (if (is-eq asset-type u1)
                              (var-get btc-price)
                              (var-get stx-price)))))
    (ok (and (> new-price u0)
             (validate-price-change new-price current-price)
             (can-update-price)))))

;; Initialize with default prices
(var-set last-update stacks-block-height)
