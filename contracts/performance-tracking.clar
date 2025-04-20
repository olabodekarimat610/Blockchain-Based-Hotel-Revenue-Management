;; Performance Tracking Contract
;; Monitors revenue against competitors

(define-data-var admin principal tx-sender)

;; Revenue data by property and date
(define-map revenue-data
  {
    property-id: (string-ascii 32),
    date: uint
  }
  {
    room-revenue: uint,
    other-revenue: uint,
    occupancy-percentage: uint,  ;; 0-100
    adr: uint,                   ;; Average Daily Rate
    revpar: uint                 ;; Revenue Per Available Room
  }
)

;; Competitor sets
(define-map competitor-sets
  {
    set-id: (string-ascii 32)
  }
  {
    name: (string-ascii 100),
    owner: principal
  }
)

;; Properties in competitor sets
(define-map competitor-set-properties
  {
    set-id: (string-ascii 32),
    property-id: (string-ascii 32)
  }
  {
    is-member: bool
  }
)

;; Aggregate competitor data
(define-map competitor-aggregate-data
  {
    set-id: (string-ascii 32),
    date: uint
  }
  {
    avg-occupancy: uint,
    avg-adr: uint,
    avg-revpar: uint,
    property-count: uint
  }
)

;; Read-only function to get revenue data
(define-read-only (get-revenue-data
    (property-id (string-ascii 32))
    (date uint))
  (map-get? revenue-data { property-id: property-id, date: date })
)

;; Read-only function to get competitor set
(define-read-only (get-competitor-set (set-id (string-ascii 32)))
  (map-get? competitor-sets { set-id: set-id })
)

;; Read-only function to check if property is in competitor set
(define-read-only (is-property-in-competitor-set
    (set-id (string-ascii 32))
    (property-id (string-ascii 32)))
  (let
    ((membership (map-get? competitor-set-properties { set-id: set-id, property-id: property-id })))
    (if (is-some membership)
      (get is-member (unwrap-panic membership))
      false
    )
  )
)

;; Read-only function to get competitor aggregate data
(define-read-only (get-competitor-aggregate-data
    (set-id (string-ascii 32))
    (date uint))
  (map-get? competitor-aggregate-data { set-id: set-id, date: date })
)

;; Record revenue data for a property
(define-public (record-revenue-data
    (property-id (string-ascii 32))
    (date uint)
    (room-revenue uint)
    (other-revenue uint)
    (occupancy-percentage uint)
    (adr uint))
  (let
    ((caller tx-sender)
     (revpar (calculate-revpar adr occupancy-percentage)))

    (asserts! (<= occupancy-percentage u100) (err u1)) ;; Invalid occupancy percentage

    (ok (map-set revenue-data
      { property-id: property-id, date: date }
      {
        room-revenue: room-revenue,
        other-revenue: other-revenue,
        occupancy-percentage: occupancy-percentage,
        adr: adr,
        revpar: revpar
      }
    ))
  )
)

;; Helper function to calculate RevPAR
(define-private (calculate-revpar (adr uint) (occupancy-percentage uint))
  (/ (* adr occupancy-percentage) u100)
)

;; Create a competitor set
(define-public (create-competitor-set
    (set-id (string-ascii 32))
    (name (string-ascii 100)))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-competitor-set set-id)) (err u2)) ;; Competitor set already exists
    (ok (map-set competitor-sets
      { set-id: set-id }
      {
        name: name,
        owner: caller
      }
    ))
  )
)

;; Add a property to a competitor set
(define-public (add-property-to-competitor-set
    (set-id (string-ascii 32))
    (property-id (string-ascii 32)))
  (let
    ((caller tx-sender)
     (competitor-set (get-competitor-set set-id)))

    (asserts! (is-some competitor-set) (err u3)) ;; Competitor set not found
    (asserts! (is-eq caller (get owner (unwrap-panic competitor-set))) (err u4)) ;; Not the owner

    (ok (map-set competitor-set-properties
      { set-id: set-id, property-id: property-id }
      {
        is-member: true
      }
    ))
  )
)

;; Remove a property from a competitor set
(define-public (remove-property-from-competitor-set
    (set-id (string-ascii 32))
    (property-id (string-ascii 32)))
  (let
    ((caller tx-sender)
     (competitor-set (get-competitor-set set-id)))

    (asserts! (is-some competitor-set) (err u3)) ;; Competitor set not found
    (asserts! (is-eq caller (get owner (unwrap-panic competitor-set))) (err u4)) ;; Not the owner

    (ok (map-set competitor-set-properties
      { set-id: set-id, property-id: property-id }
      {
        is-member: false
      }
    ))
  )
)

;; Update competitor aggregate data
;; In a real implementation, this would be triggered by an oracle or off-chain process
(define-public (update-competitor-aggregate-data
    (set-id (string-ascii 32))
    (date uint)
    (avg-occupancy uint)
    (avg-adr uint)
    (avg-revpar uint)
    (property-count uint))
  (let
    ((caller tx-sender)
     (competitor-set (get-competitor-set set-id)))

    (asserts! (is-some competitor-set) (err u3)) ;; Competitor set not found
    (asserts! (is-eq caller (var-get admin)) (err u5)) ;; Not authorized

    (ok (map-set competitor-aggregate-data
      { set-id: set-id, date: date }
      {
        avg-occupancy: avg-occupancy,
        avg-adr: avg-adr,
        avg-revpar: avg-revpar,
        property-count: property-count
      }
    ))
  )
)

;; Compare property performance against competitor set
(define-read-only (compare-performance
    (property-id (string-ascii 32))
    (set-id (string-ascii 32))
    (date uint))
  (let
    ((property-data (get-revenue-data property-id date))
     (competitor-data (get-competitor-aggregate-data set-id date)))

    (asserts! (is-some property-data) (err u6)) ;; Property data not found
    (asserts! (is-some competitor-data) (err u7)) ;; Competitor data not found

    (let
      ((prop-data (unwrap-panic property-data))
       (comp-data (unwrap-panic competitor-data)))

      (ok {
        occupancy-index: (calculate-index
                           (get occupancy-percentage prop-data)
                           (get avg-occupancy comp-data)),
        adr-index: (calculate-index
                     (get adr prop-data)
                     (get avg-adr comp-data)),
        revpar-index: (calculate-index
                        (get revpar prop-data)
                        (get avg-revpar comp-data))
      })
    )
  )
)

;; Helper function to calculate performance index
;; Returns percentage of property metric compared to competitor average (100 = equal)
(define-private (calculate-index (property-value uint) (competitor-avg uint))
  (if (> competitor-avg u0)
    (/ (* property-value u100) competitor-avg)
    u0
  )
)
