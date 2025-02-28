;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-not-authorized (err u100))
(define-constant err-invalid-amount (err u101))
(define-constant err-invalid-loan (err u102))
(define-constant err-already-funded (err u103))
(define-constant err-loan-not-funded (err u104))
(define-constant err-insufficient-collateral (err u105))

;; Data variables
(define-data-var loan-counter uint u0)

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

;; Request a loan
(define-public (request-loan (amount uint) (repayment uint) (duration uint))
  (let ((loan-id (+ (var-get loan-counter) u1))
        (collateral (/ (* amount u12) u10))) ;; 120% collateral requirement
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
    (ok loan-id)))

;; Fund a loan
(define-public (fund-loan (loan-id uint))
  (let ((loan (unwrap! (map-get? loans loan-id) err-invalid-loan)))
    (asserts! (is-eq (get status loan) "REQUESTED") err-already-funded)
    (try! (stx-transfer? (get amount loan) tx-sender (get borrower loan)))
    (map-set loans loan-id 
      (merge loan {
        status: "FUNDED",
        lender: (some tx-sender)
      }))
    (ok true)))

;; Repay a loan
(define-public (repay-loan (loan-id uint))
  (let ((loan (unwrap! (map-get? loans loan-id) err-invalid-loan)))
    (asserts! (is-eq (get borrower loan) tx-sender) err-not-authorized)
    (asserts! (is-eq (get status loan) "FUNDED") err-loan-not-funded)
    (try! (stx-transfer? (get repayment loan) tx-sender (unwrap! (get lender loan) err-invalid-loan)))
    (try! (as-contract (stx-transfer? (get collateral loan) tx-sender tx-sender)))
    (map-set loans loan-id 
      (merge loan { status: "REPAID" }))
    (ok true)))

;; Claim defaulted loan collateral
(define-public (claim-collateral (loan-id uint))
  (let ((loan (unwrap! (map-get? loans loan-id) err-invalid-loan))
        (current-height block-height))
    (asserts! (is-eq (unwrap! (get lender loan) err-invalid-loan) tx-sender) err-not-authorized)
    (asserts! (is-eq (get status loan) "FUNDED") err-loan-not-funded)
    (asserts! (>= current-height (+ (get timestamp loan) (get duration loan))) err-invalid-loan)
    (try! (as-contract (stx-transfer? (get collateral loan) tx-sender tx-sender)))
    (map-set loans loan-id 
      (merge loan { status: "DEFAULTED" }))
    (ok true)))

;; Read-only functions
(define-read-only (get-loan-data (loan-id uint))
  (ok (unwrap! (map-get? loans loan-id) err-invalid-loan)))
