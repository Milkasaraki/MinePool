;; Cryptocurrency Mining Pool Contract
;; Enables fractional ownership of mining rigs with automated reward distribution

;; Constants
(define-constant POOL_OPERATOR tx-sender)
(define-constant ERR_UNAUTHORIZED_MINER (err u900))
(define-constant ERR_INSUFFICIENT_HASHRATE (err u901))
(define-constant ERR_RIG_NOT_FOUND (err u902))
(define-constant ERR_INVALID_AMOUNT (err u903))
(define-constant ERR_OPTIMIZATION_NOT_FOUND (err u904))
(define-constant ERR_ALREADY_VOTED (err u905))

;; Data Variables
(define-data-var next-rig-id uint u1)
(define-data-var next-optimization-id uint u1)

;; Mining Rig Structure
(define-map mining-rigs 
  { rig-id: uint }
  {
    rig-model: (string-ascii 100),
    total-hashrate: uint,
    hashrate-price: uint,
    daily-rewards: uint,
    pool-manager: principal,
    is-mining: bool
  }
)

;; Hashrate Ownership
(define-map miner-hashrate
  { rig-id: uint, miner: principal }
  { hashrate: uint }
)

;; Optimization Proposals
(define-map rig-optimizations
  { optimization-id: uint }
  {
    rig-id: uint,
    optimization-name: (string-ascii 100),
    technical-details: (string-ascii 500),
    proposer: principal,
    support-votes: uint,
    oppose-votes: uint,
    voting-deadline: uint,
    implemented: bool
  }
)

;; Voting Records
(define-map optimization-votes
  { optimization-id: uint, voter: principal }
  { voted: bool, supports: bool }
)

;; Reward Distribution Tracking
(define-map reward-claims
  { rig-id: uint, miner: principal, day: uint }
  { claimed: bool }
)

;; Rig Deployment
(define-public (deploy-rig 
  (rig-model (string-ascii 100))
  (total-hashrate uint)
  (hashrate-price uint)
  (daily-rewards uint)
  (pool-manager principal))
  (let ((rig-id (var-get next-rig-id)))
    (asserts! (is-eq tx-sender POOL_OPERATOR) ERR_UNAUTHORIZED_MINER)
    (asserts! (> total-hashrate u0) ERR_INVALID_AMOUNT)
    (asserts! (> hashrate-price u0) ERR_INVALID_AMOUNT)
    
    (map-set mining-rigs
      { rig-id: rig-id }
      {
        rig-model: rig-model,
        total-hashrate: total-hashrate,
        hashrate-price: hashrate-price,
        daily-rewards: daily-rewards,
        pool-manager: pool-manager,
        is-mining: true
      }
    )
    
    (var-set next-rig-id (+ rig-id u1))
    (ok rig-id)
  )
)

;; Purchase Mining Hashrate
(define-public (buy-hashrate (rig-id uint) (hashrate-amount uint))
  (let (
    (rig (unwrap! (map-get? mining-rigs { rig-id: rig-id }) ERR_RIG_NOT_FOUND))
    (total-cost (* hashrate-amount (get hashrate-price rig)))
    (current-hashrate (default-to u0 (get hashrate (map-get? miner-hashrate { rig-id: rig-id, miner: tx-sender }))))
  )
    (asserts! (get is-mining rig) ERR_RIG_NOT_FOUND)
    (asserts! (> hashrate-amount u0) ERR_INVALID_AMOUNT)
    
    (map-set miner-hashrate
      { rig-id: rig-id, miner: tx-sender }
      { hashrate: (+ current-hashrate hashrate-amount) }
    )
    
    (ok hashrate-amount)
  )
)

;; Distribute Mining Rewards
(define-public (distribute-rewards (rig-id uint) (day uint))
  (let (
    (rig (unwrap! (map-get? mining-rigs { rig-id: rig-id }) ERR_RIG_NOT_FOUND))
    (daily-rewards (get daily-rewards rig))
    (total-hashrate (get total-hashrate rig))
  )
    (asserts! (is-eq tx-sender (get pool-manager rig)) ERR_UNAUTHORIZED_MINER)
    (asserts! (get is-mining rig) ERR_RIG_NOT_FOUND)
    
    (ok true)
  )
)

;; Claim Mining Rewards
(define-public (claim-rewards (rig-id uint) (day uint))
  (let (
    (rig (unwrap! (map-get? mining-rigs { rig-id: rig-id }) ERR_RIG_NOT_FOUND))
    (hashrate-balance (default-to u0 (get hashrate (map-get? miner-hashrate { rig-id: rig-id, miner: tx-sender }))))
    (already-claimed (default-to false (get claimed (map-get? reward-claims { rig-id: rig-id, miner: tx-sender, day: day }))))
    (daily-rewards (get daily-rewards rig))
    (total-hashrate (get total-hashrate rig))
    (reward-share (/ (* daily-rewards hashrate-balance) total-hashrate))
  )
    (asserts! (> hashrate-balance u0) ERR_INSUFFICIENT_HASHRATE)
    (asserts! (not already-claimed) ERR_UNAUTHORIZED_MINER)
    
    (map-set reward-claims
      { rig-id: rig-id, miner: tx-sender, day: day }
      { claimed: true }
    )
    
    (ok reward-share)
  )
)

;; Create Optimization Proposal
(define-public (create-optimization 
  (rig-id uint)
  (optimization-name (string-ascii 100))
  (technical-details (string-ascii 500))
  (voting-period uint))
  (let (
    (optimization-id (var-get next-optimization-id))
    (hashrate-balance (default-to u0 (get hashrate (map-get? miner-hashrate { rig-id: rig-id, miner: tx-sender }))))
    (voting-deadline (+ block-height voting-period))
  )
    (asserts! (> hashrate-balance u0) ERR_UNAUTHORIZED_MINER)
    
    (map-set rig-optimizations
      { optimization-id: optimization-id }
      {
        rig-id: rig-id,
        optimization-name: optimization-name,
        technical-details: technical-details,
        proposer: tx-sender,
        support-votes: u0,
        oppose-votes: u0,
        voting-deadline: voting-deadline,
        implemented: false
      }
    )
    
    (var-set next-optimization-id (+ optimization-id u1))
    (ok optimization-id)
  )
)

;; Vote on Optimization
(define-public (vote-optimization (optimization-id uint) (supports bool))
  (let (
    (optimization (unwrap! (map-get? rig-optimizations { optimization-id: optimization-id }) ERR_OPTIMIZATION_NOT_FOUND))
    (rig-id (get rig-id optimization))
    (hashrate-balance (default-to u0 (get hashrate (map-get? miner-hashrate { rig-id: rig-id, miner: tx-sender }))))
    (already-voted (default-to false (get voted (map-get? optimization-votes { optimization-id: optimization-id, voter: tx-sender }))))
    (current-support (get support-votes optimization))
    (current-oppose (get oppose-votes optimization))
  )
    (asserts! (> hashrate-balance u0) ERR_UNAUTHORIZED_MINER)
    (asserts! (<= block-height (get voting-deadline optimization)) ERR_UNAUTHORIZED_MINER)
    (asserts! (not already-voted) ERR_ALREADY_VOTED)
    
    (map-set optimization-votes
      { optimization-id: optimization-id, voter: tx-sender }
      { voted: true, supports: supports }
    )
    
    (if supports
      (map-set rig-optimizations
        { optimization-id: optimization-id }
        (merge optimization { support-votes: (+ current-support hashrate-balance) })
      )
      (map-set rig-optimizations
        { optimization-id: optimization-id }
        (merge optimization { oppose-votes: (+ current-oppose hashrate-balance) })
      )
    )
    
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-rig (rig-id uint))
  (map-get? mining-rigs { rig-id: rig-id })
)

(define-read-only (get-hashrate-balance (rig-id uint) (miner principal))
  (default-to u0 (get hashrate (map-get? miner-hashrate { rig-id: rig-id, miner: miner })))
)

(define-read-only (get-optimization (optimization-id uint))
  (map-get? rig-optimizations { optimization-id: optimization-id })
)

(define-read-only (calculate-reward-share (rig-id uint) (miner principal))
  (let (
    (rig (unwrap! (map-get? mining-rigs { rig-id: rig-id }) ERR_RIG_NOT_FOUND))
    (hashrate-balance (default-to u0 (get hashrate (map-get? miner-hashrate { rig-id: rig-id, miner: miner }))))
    (daily-rewards (get daily-rewards rig))
    (total-hashrate (get total-hashrate rig))
  )
    (if (> hashrate-balance u0)
      (ok (/ (* daily-rewards hashrate-balance) total-hashrate))
      (ok u0)
    )
  )
)