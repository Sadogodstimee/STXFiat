;; Mock Price Oracle Contract for Local Development

(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-INVALID-PRICE (err u101))

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

;; ===== ADMIN FUNCTIONS =====
(define-public (set-stablecoin-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (var-set stablecoin-price new-price)
    (var-set last-update stacks-block-height)
    (var-set price-counter (+ (var-get price-counter) u1))
    (map-set price-history (var-get price-counter) new-price)
    (ok true)))

(define-public (set-btc-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (var-set btc-price new-price)
    (var-set last-update stacks-block-height)
    (ok true)))

(define-public (set-stx-price (new-price uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR-NOT-AUTHORIZED)
    (asserts! (> new-price u0) ERR-INVALID-PRICE)
    (var-set stx-price new-price)
    (var-set last-update stacks-block-height)
    (ok true)))

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

;; Initialize with default prices
(var-set last-update stacks-block-height)