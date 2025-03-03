;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-invalid-loan (err u102))
(define-constant err-already-funded (err u103))
(define-constant err-loan-not-funded (err u104))
(define-constant err-insufficient-collateral (err u105))
(define-constant err-zero-amount (err u106))
(define-constant err-reentrancy (err u107))

;; Data variables
(define-data-var loan-counter uint u0)
(define-data-var is-in-transaction bool false)

;; Define loan data structure
(define-map loans uint {
  borrower: principal,
  amount: uint,
  collateral: uint,
  repayment: uint,
  duration: uint,
  status: (string-ascii 20),
  lender: (optional principal),
  timestamp: uint
})

;; Private function to check reentrancy
(define-private (check-reentrancy)
  (if (var-get is-in-transaction)
      err-reentrancy
      (ok true)))

;; Request a loan
(define-public (request-loan (amount uint) (repayment uint) (duration uint))
  (begin
    (asserts! (> amount u0) err-zero-amount)
    (asserts! (>= repayment amount) err-invalid-amount)
    (asserts! (>= duration u1) err-invalid-amount)
    (let ((loan-id (+ (var-get loan-counter) u1))
          (collateral (try! (mul-down amount u12 u10)))) ;; 120% collateral with overflow protection
      (try! (stx-transfer? collateral tx-sender (as-contract tx-sender)))
      (map-set loans loan-id {
        borrower: tx-sender,
        amount: amount,
        collateral: collateral,
        repayment: repayment,
        duration: duration,
        status: "REQUESTED",
        lender: none,
        timestamp: block-height
      })
      (var-set loan-counter loan-id)
      (ok loan-id))))

;; Cancel unfunded loan request
(define-public (cancel-loan-request (loan-id uint))
  (let ((loan (unwrap! (map-get? loans loan-id) err-invalid-loan)))
    (asserts! (is-eq (get borrower loan) tx-sender) err-not-authorized)
    (asserts! (is-eq (get status loan) "REQUESTED") err-already-funded)
    (try! (as-contract (stx-transfer? (get collateral loan) tx-sender tx-sender)))
    (map-set loans loan-id 
      (merge loan { status: "CANCELLED" }))
    (ok true)))

;; Fund a loan
(define-public (fund-loan (loan-id uint))
  (begin
    (try! (check-reentrancy))
    (var-set is-in-transaction true)
    (let ((loan (unwrap! (map-get? loans loan-id) err-invalid-loan)))
      (asserts! (is-eq (get status loan) "REQUESTED") err-already-funded)
      (try! (stx-transfer? (get amount loan) tx-sender (get borrower loan)))
      (map-set loans loan-id 
        (merge loan {
          status: "FUNDED",
          lender: (some tx-sender)
        }))
      (var-set is-in-transaction false)
      (ok true))))

[... rest of the contract with similar improvements ...]
