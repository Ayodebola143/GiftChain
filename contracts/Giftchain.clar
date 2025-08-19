;; --------------------------------
;; Contract: GiftChain Vault
;; Secure STX Gift System
;; --------------------------------

(define-constant CONTRACT-OWNER tx-sender)
(define-constant PLATFORM-FEE u1000) ;; micro-STX
(define-constant ERR_INVALID_AMOUNT (err u100))
(define-constant ERR_INVALID_EXPIRY (err u101))
(define-constant ERR_ALREADY_CLAIMED (err u102))
(define-constant ERR_NOT_FOUND (err u103))
(define-constant ERR_UNAUTHORIZED (err u104))
(define-constant ERR_GIFT_EXPIRED (err u105))
(define-data-var total-gifts uint u0)
(define-data-var next-pool-id uint u1)

;; Extended gift structure
(define-map gifts
  { hash-code: (buff 32) }
  {
    sender: principal,
    amount: uint,
    expiry-block: uint,
    claimed: bool,
    message: (string-utf8 100),
    pool-id: (optional uint)
  }
)

;; Gift claim logs
(define-map gift-history
  { hash-code: (buff 32), event-id: uint }
  {
    event-type: (string-ascii 20),
    actor: principal,
    amount: uint,
    block: uint
  }
)

;; Create gift with message + optional pool
(define-public (create-gift-extended
  (hash-code (buff 32))
  (amount uint)
  (expiry-block uint)
  (message (string-utf8 100))
  (pool-id (optional uint))
)
  (begin
    (asserts! (> amount u0) ERR_INVALID_AMOUNT)
    (asserts! (> expiry-block stacks-block-height) ERR_INVALID_EXPIRY)
    (asserts! (not (is-some (map-get? gifts { hash-code: hash-code }))) ERR_ALREADY_CLAIMED)

    ;; Charge platform fee
    (try! (stx-transfer? PLATFORM-FEE tx-sender CONTRACT-OWNER))
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    (map-set gifts
      { hash-code: hash-code }
      {
        sender: tx-sender,
        amount: amount,
        expiry-block: expiry-block,
        claimed: false,
        message: message,
        pool-id: pool-id
      }
    )

    (var-set total-gifts (+ (var-get total-gifts) u1))
    (ok true)
  )
)

;; Claim part of a gift
(define-public (partial-claim (hash-code (buff 32)) (claim-amount uint))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)
      (asserts! (<= stacks-block-height (get expiry-block gift)) ERR_GIFT_EXPIRED)
      (asserts! (<= claim-amount (get amount gift)) ERR_INVALID_AMOUNT)

      (try! (stx-transfer? claim-amount (as-contract tx-sender) tx-sender))

      (let ((remaining (- (get amount gift) claim-amount)))
        (if (is-eq remaining u0)
          (map-set gifts { hash-code: hash-code } (merge gift { claimed: true, amount: remaining }))
          (map-set gifts { hash-code: hash-code } (merge gift { amount: remaining }))
        )
      )

      ;; Log claim
      (map-set gift-history
        { hash-code: hash-code, event-id: stacks-block-height }
        {
          event-type: "Partial Claim",
          actor: tx-sender,
          amount: claim-amount,
          block: stacks-block-height
        }
      )

      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; Auto-refund expired gifts
(define-public (refund-expired (hash-code (buff 32)))
  (match (map-get? gifts { hash-code: hash-code })
    gift
    (begin
      (asserts! (is-eq tx-sender (get sender gift)) ERR_UNAUTHORIZED)
      (asserts! (> stacks-block-height (get expiry-block gift)) ERR_INVALID_EXPIRY)
      (asserts! (not (get claimed gift)) ERR_ALREADY_CLAIMED)

      (try! (stx-transfer? (get amount gift) (as-contract tx-sender) (get sender gift)))
      (map-set gifts { hash-code: hash-code } (merge gift { claimed: true, amount: u0 }))

      ;; Log refund
      (map-set gift-history
        { hash-code: hash-code, event-id: stacks-block-height }
        {
          event-type: "Refund",
          actor: tx-sender,
          amount: (get amount gift),
          block: stacks-block-height
        }
      )

      (ok true)
    )
    ERR_NOT_FOUND
  )
)

;; Read-only: Get message
(define-read-only (get-gift-message (hash-code (buff 32)))
  (match (map-get? gifts { hash-code: hash-code })
    gift (ok (get message gift))
    ERR_NOT_FOUND
  )
)

;; Read-only: Gift logs
(define-read-only (get-gift-history (hash-code (buff 32)))
  ;; In production, you had index multiple event IDs
  (ok (list))
)
