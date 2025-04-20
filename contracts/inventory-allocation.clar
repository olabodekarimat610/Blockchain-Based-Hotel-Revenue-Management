;; Inventory Allocation Contract
;; Manages room availability by channel

(define-data-var admin principal tx-sender)

;; Room types for a property
(define-map room-types
  {
    property-id: (string-ascii 32),
    room-type-id: (string-ascii 32)
  }
  {
    name: (string-ascii 100),
    total-inventory: uint,
    owner: principal
  }
)

;; Distribution channels
(define-map channels
  {
    channel-id: (string-ascii 32)
  }
  {
    name: (string-ascii 100),
    active: bool
  }
)

;; Inventory allocation by date, property, room type, and channel
(define-map inventory-allocation
  {
    property-id: (string-ascii 32),
    room-type-id: (string-ascii 32),
    channel-id: (string-ascii 32),
    date: uint
  }
  {
    allocated: uint,
    booked: uint
  }
)

;; Read-only function to get a room type
(define-read-only (get-room-type
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32)))
  (map-get? room-types { property-id: property-id, room-type-id: room-type-id })
)

;; Read-only function to get a channel
(define-read-only (get-channel (channel-id (string-ascii 32)))
  (map-get? channels { channel-id: channel-id })
)

;; Read-only function to get inventory allocation
(define-read-only (get-inventory-allocation
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32))
    (channel-id (string-ascii 32))
    (date uint))
  (map-get? inventory-allocation
    {
      property-id: property-id,
      room-type-id: room-type-id,
      channel-id: channel-id,
      date: date
    }
  )
)

;; Read-only function to get available inventory
(define-read-only (get-available-inventory
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32))
    (channel-id (string-ascii 32))
    (date uint))
  (let
    ((allocation (get-inventory-allocation property-id room-type-id channel-id date)))
    (if (is-some allocation)
      (let
        ((alloc (unwrap-panic allocation)))
        (ok (- (get allocated alloc) (get booked alloc)))
      )
      (ok u0) ;; No allocation found
    )
  )
)

;; Create a new room type
(define-public (create-room-type
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32))
    (name (string-ascii 100))
    (total-inventory uint))
  (let
    ((caller tx-sender))
    (asserts! (is-none (get-room-type property-id room-type-id)) (err u1)) ;; Room type already exists
    (ok (map-set room-types
      { property-id: property-id, room-type-id: room-type-id }
      {
        name: name,
        total-inventory: total-inventory,
        owner: caller
      }
    ))
  )
)

;; Create a new channel
(define-public (create-channel
    (channel-id (string-ascii 32))
    (name (string-ascii 100)))
  (let
    ((caller tx-sender))
    (asserts! (is-eq caller (var-get admin)) (err u2)) ;; Not authorized
    (asserts! (is-none (get-channel channel-id)) (err u3)) ;; Channel already exists
    (ok (map-set channels
      { channel-id: channel-id }
      {
        name: name,
        active: true
      }
    ))
  )
)

;; Allocate inventory to a channel
(define-public (allocate-inventory
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32))
    (channel-id (string-ascii 32))
    (date uint)
    (amount uint))
  (let
    ((caller tx-sender)
     (room-type (get-room-type property-id room-type-id))
     (channel (get-channel channel-id)))

    (asserts! (is-some room-type) (err u4)) ;; Room type not found
    (asserts! (is-eq caller (get owner (unwrap-panic room-type))) (err u2)) ;; Not authorized
    (asserts! (is-some channel) (err u5)) ;; Channel not found
    (asserts! (get active (unwrap-panic channel)) (err u6)) ;; Channel not active

    ;; Check if total allocation across all channels doesn't exceed total inventory
    (let
      ((total-allocated (+ amount (get-total-allocated-for-date property-id room-type-id date))))
      (asserts! (<= total-allocated (get total-inventory (unwrap-panic room-type))) (err u7)) ;; Exceeds total inventory

      (ok (map-set inventory-allocation
        {
          property-id: property-id,
          room-type-id: room-type-id,
          channel-id: channel-id,
          date: date
        }
        {
          allocated: amount,
          booked: u0
        }
      ))
    )
  )
)

;; Helper function to get total allocated inventory for a date across all channels
(define-private (get-total-allocated-for-date
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32))
    (date uint))
  ;; In a real implementation, this would iterate through all channels
  ;; For simplicity, we're returning 0 here
  u0
)

;; Book inventory from a channel
(define-public (book-inventory
    (property-id (string-ascii 32))
    (room-type-id (string-ascii 32))
    (channel-id (string-ascii 32))
    (date uint)
    (amount uint))
  (let
    ((allocation (get-inventory-allocation property-id room-type-id channel-id date)))

    (asserts! (is-some allocation) (err u8)) ;; No allocation found

    (let
      ((alloc (unwrap-panic allocation))
       (available (- (get allocated alloc) (get booked alloc))))

      (asserts! (>= available amount) (err u9)) ;; Not enough inventory

      (ok (map-set inventory-allocation
        {
          property-id: property-id,
          room-type-id: room-type-id,
          channel-id: channel-id,
          date: date
        }
        {
          allocated: (get allocated alloc),
          booked: (+ (get booked alloc) amount)
        }
      ))
    )
  )
)
