;; IronBio - Biometric Bitcoin Recovery System
;; Distributed biometric data storage for hardware wallet recovery

;; Contract constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u100))
(define-constant ERR-NOT-FOUND (err u101))
(define-constant ERR-INVALID-THRESHOLD (err u102))
(define-constant ERR-INSUFFICIENT-SHARDS (err u103))
(define-constant ERR-ALREADY-EXISTS (err u104))
(define-constant ERR-INVALID-SHARD (err u105))
(define-constant ERR-RECOVERY-LOCKED (err u106))

;; Data structures
(define-map biometric-vaults
  { vault-id: (buff 32) }
  {
    owner: principal,
    threshold: uint,
    total-shards: uint,
    created-at: uint,
    recovery-locked: bool,
    wallet-hash: (buff 32)
  }
)

(define-map biometric-shards
  { vault-id: (buff 32), shard-index: uint }
  {
    shard-hash: (buff 32),
    node-address: principal,
    timestamp: uint,
    verified: bool
  }
)

(define-map recovery-attempts
  { vault-id: (buff 32), attempt-id: uint }
  {
    requester: principal,
    timestamp: uint,
    shards-provided: uint,
    status: (string-ascii 20)
  }
)

(define-map node-registry
  { node-address: principal }
  {
    reputation-score: uint,
    total-shards: uint,
    successful-recoveries: uint,
    last-active: uint,
    status: (string-ascii 10)
  }
)

;; Data variables
(define-data-var vault-counter uint u0)
(define-data-var recovery-counter uint u0)
(define-data-var min-threshold uint u3)
(define-data-var max-threshold uint u7)

;; Public functions

;; Create a new biometric vault
(define-public (create-vault (vault-id (buff 32)) (threshold uint) (total-shards uint) (wallet-hash (buff 32)))
  (let ((current-block block-height))
    (asserts! (and (>= threshold (var-get min-threshold)) 
                   (<= threshold (var-get max-threshold))) ERR-INVALID-THRESHOLD)
    (asserts! (>= total-shards threshold) ERR-INVALID-THRESHOLD)
    (asserts! (is-none (map-get? biometric-vaults {vault-id: vault-id})) ERR-ALREADY-EXISTS)
    
    (map-set biometric-vaults 
      {vault-id: vault-id}
      {
        owner: tx-sender,
        threshold: threshold,
        total-shards: total-shards,
        created-at: current-block,
        recovery-locked: false,
        wallet-hash: wallet-hash
      })
    
    (var-set vault-counter (+ (var-get vault-counter) u1))
    (ok vault-id)
  )
)

;; Store a biometric shard
(define-public (store-shard (vault-id (buff 32)) (shard-index uint) (shard-hash (buff 32)))
  (let ((vault-data (unwrap! (map-get? biometric-vaults {vault-id: vault-id}) ERR-NOT-FOUND)))
    (asserts! (is-eq (get owner vault-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (< shard-index (get total-shards vault-data)) ERR-INVALID-SHARD)
    (asserts! (is-none (map-get? biometric-shards {vault-id: vault-id, shard-index: shard-index})) ERR-ALREADY-EXISTS)
    
    (map-set biometric-shards
      {vault-id: vault-id, shard-index: shard-index}
      {
        shard-hash: shard-hash,
        node-address: tx-sender,
        timestamp: block-height,
        verified: false
      })
    
    ;; Update node registry
    (update-node-stats tx-sender)
    (ok true)
  )
)

;; Register as a storage node
(define-public (register-node)
  (begin
    (map-set node-registry
      {node-address: tx-sender}
      {
        reputation-score: u100,
        total-shards: u0,
        successful-recoveries: u0,
        last-active: block-height,
        status: "active"
      })
    (ok true)
  )
)

;; Initiate recovery process
(define-public (initiate-recovery (vault-id (buff 32)) (provided-shards (list 10 uint)))
  (let (
    (vault-data (unwrap! (map-get? biometric-vaults {vault-id: vault-id}) ERR-NOT-FOUND))
    (attempt-id (var-get recovery-counter))
    (shard-count (len provided-shards))
  )
    (asserts! (not (get recovery-locked vault-data)) ERR-RECOVERY-LOCKED)
    (asserts! (>= shard-count (get threshold vault-data)) ERR-INSUFFICIENT-SHARDS)
    
    ;; Verify provided shards exist and are valid
    (asserts! (verify-shards vault-id provided-shards) ERR-INVALID-SHARD)
    
    (map-set recovery-attempts
      {vault-id: vault-id, attempt-id: attempt-id}
      {
        requester: tx-sender,
        timestamp: block-height,
        shards-provided: shard-count,
        status: "pending"
      })
    
    (var-set recovery-counter (+ attempt-id u1))
    (ok attempt-id)
  )
)

;; Verify recovery and unlock wallet
(define-public (complete-recovery (vault-id (buff 32)) (attempt-id uint) (biometric-proof (buff 64)))
  (let (
    (vault-data (unwrap! (map-get? biometric-vaults {vault-id: vault-id}) ERR-NOT-FOUND))
    (attempt-data (unwrap! (map-get? recovery-attempts {vault-id: vault-id, attempt-id: attempt-id}) ERR-NOT-FOUND))
  )
    (asserts! (is-eq (get requester attempt-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (is-eq (get status attempt-data) "pending") ERR-UNAUTHORIZED)
    
    ;; Update attempt status
    (map-set recovery-attempts
      {vault-id: vault-id, attempt-id: attempt-id}
      (merge attempt-data {status: "completed"}))
    
    ;; Temporarily lock vault for security
    (map-set biometric-vaults
      {vault-id: vault-id}
      (merge vault-data {recovery-locked: true}))
    
    (ok {wallet-hash: (get wallet-hash vault-data), recovery-proof: biometric-proof})
  )
)

;; Admin function to unlock vault after recovery
(define-public (unlock-vault (vault-id (buff 32)))
  (let ((vault-data (unwrap! (map-get? biometric-vaults {vault-id: vault-id}) ERR-NOT-FOUND)))
    (asserts! (is-eq (get owner vault-data) tx-sender) ERR-UNAUTHORIZED)
    
    (map-set biometric-vaults
      {vault-id: vault-id}
      (merge vault-data {recovery-locked: false}))
    
    (ok true)
  )
)

;; Read-only functions

(define-read-only (get-vault-info (vault-id (buff 32)))
  (map-get? biometric-vaults {vault-id: vault-id})
)

(define-read-only (get-shard-info (vault-id (buff 32)) (shard-index uint))
  (map-get? biometric-shards {vault-id: vault-id, shard-index: shard-index})
)

(define-read-only (get-node-info (node-address principal))
  (map-get? node-registry {node-address: node-address})
)

(define-read-only (get-recovery-attempt (vault-id (buff 32)) (attempt-id uint))
  (map-get? recovery-attempts {vault-id: vault-id, attempt-id: attempt-id})
)

(define-read-only (get-vault-shard-count (vault-id (buff 32)))
  (let ((vault-data (map-get? biometric-vaults {vault-id: vault-id})))
    (match vault-data
      vault (some (get total-shards vault))
      none
    )
  )
)

;; Private functions

(define-private (verify-shards (vault-id (buff 32)) (shard-indices (list 10 uint)))
  (get valid (fold verify-single-shard shard-indices {vault-id: vault-id, valid: true}))
)

(define-private (verify-single-shard (shard-index uint) (context {vault-id: (buff 32), valid: bool}))
  (if (get valid context)
    (let ((shard-exists (is-some (map-get? biometric-shards {vault-id: (get vault-id context), shard-index: shard-index}))))
      {vault-id: (get vault-id context), valid: shard-exists}
    )
    context
  )
)

(define-private (update-node-stats (node-address principal))
  (let ((current-stats (default-to 
                         {reputation-score: u100, total-shards: u0, successful-recoveries: u0, last-active: u0, status: "active"}
                         (map-get? node-registry {node-address: node-address}))))
    (map-set node-registry
      {node-address: node-address}
      (merge current-stats {
        total-shards: (+ (get total-shards current-stats) u1),
        last-active: block-height
      }))
  )
)

;; Contract owner functions

(define-public (set-thresholds (min-thresh uint) (max-thresh uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (< min-thresh max-thresh) ERR-INVALID-THRESHOLD)
    (var-set min-threshold min-thresh)
    (var-set max-threshold max-thresh)
    (ok true)
  )
)