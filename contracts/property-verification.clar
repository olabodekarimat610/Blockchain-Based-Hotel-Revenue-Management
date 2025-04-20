;; Property Verification Contract
;; Validates legitimate accommodation providers

(define-data-var admin principal tx-sender)

;; Property status: 0 = pending, 1 = verified, 2 = rejected
(define-map properties
  { property-id: (string-ascii 32) }
  {
    owner: principal,
    name: (string-ascii 100),
    location: (string-ascii 100),
    status: uint,
    verification-date: uint
  }
)

(define-read-only (get-property (property-id (string-ascii 32)))
  (map-get? properties { property-id: property-id })
)

(define-public (register-property
    (property-id (string-ascii 32))
    (name (string-ascii 100))
    (location (string-ascii 100)))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-property property-id)) (err u1)) ;; Property ID already exists
    (ok (map-set properties
      { property-id: property-id }
      {
        owner: caller,
        name: name,
        location: location,
        status: u0, ;; pending
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-property (property-id (string-ascii 32)))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u2)) ;; Not authorized
    (asserts! (is-some (get-property property-id)) (err u3)) ;; Property not found
    (ok (map-set properties
      { property-id: property-id }
      (merge (unwrap-panic (get-property property-id))
        {
          status: u1, ;; verified
          verification-date: block-height
        }
      )
    ))
  )
)

(define-public (reject-property (property-id (string-ascii 32)))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u2)) ;; Not authorized
    (asserts! (is-some (get-property property-id)) (err u3)) ;; Property not found
    (ok (map-set properties
      { property-id: property-id }
      (merge (unwrap-panic (get-property property-id))
        {
          status: u2, ;; rejected
          verification-date: block-height
        }
      )
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u2)) ;; Not authorized
    (ok (var-set admin new-admin))
  )
)
