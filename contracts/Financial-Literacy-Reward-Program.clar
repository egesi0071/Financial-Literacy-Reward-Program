(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-module-not-found (err u103))
(define-constant err-module-already-completed (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-module-inactive (err u106))
(define-constant err-proposal-not-found (err u107))
(define-constant err-voting-ended (err u108))
(define-constant err-proposal-not-ready (err u109))
(define-constant err-insufficient-voting-power (err u110))
(define-constant err-already-voted (err u111))
(define-constant err-paused (err u112))
(define-constant err-not-admin (err u113))
(define-constant err-insufficient-stake (err u114))
(define-constant err-no-stake-found (err u115))
(define-constant err-stake-locked (err u116))
(define-constant err-streak-already-claimed (err u117))
(define-constant err-streak-expired (err u118))
(define-constant err-achievement-already-claimed (err u119))
(define-constant err-achievement-not-found (err u120))
(define-constant err-requirements-not-met (err u121))

(define-constant token-name "FinLit Token")
(define-constant token-symbol "FLT")
(define-constant token-uri (some u"https://finlit-dao.com/token-metadata"))
(define-constant token-decimals u6)

(define-constant min-voting-power u1000000)
(define-constant voting-period u1008)
(define-constant execution-delay u144)
(define-constant proposal-deposit u500000000)
(define-constant min-stake-amount u1000000)
(define-constant stake-lock-period u144)
(define-constant annual-yield-rate u5)
(define-constant referral-bonus-rate u10)
(define-constant streak-base-reward u100000)
(define-constant streak-multiplier u10)
(define-constant streak-window u144)

(define-data-var token-total-supply uint u0)
(define-data-var next-module-id uint u1)
(define-data-var next-proposal-id uint u1)
(define-data-var is-paused bool false)
(define-data-var admin principal contract-owner)
(define-data-var total-staked uint u0)
(define-data-var next-stake-id uint u1)
(define-data-var next-achievement-id uint u1)

(define-map token-balances principal uint)
(define-map token-supplies-approved {owner: principal, spender: principal} uint)

(define-map modules uint {
  title: (string-ascii 64),
  description: (string-ascii 256),
  reward-amount: uint,
  is-active: bool,
  created-at: uint,
  total-completions: uint
})

(define-map user-completions {user: principal, module-id: uint} bool)
(define-map user-total-rewards principal uint)
(define-map user-modules-completed principal uint)
(define-map user-referrer principal principal)

(define-map proposals uint {
  proposer: principal,
  title: (string-ascii 128),
  description: (string-ascii 512),
  action-type: (string-ascii 32),
  target-module-id: (optional uint),
  new-reward-amount: (optional uint),
  new-title: (optional (string-ascii 64)),
  new-description: (optional (string-ascii 256)),
  votes-for: uint,
  votes-against: uint,
  start-height: uint,
  end-height: uint,
  executed: bool,
  execution-height: (optional uint)
})

(define-map proposal-votes {proposal-id: uint, voter: principal} {vote: bool, power: uint})

(define-map stakes uint {
  staker: principal,
  amount: uint,
  start-height: uint,
  last-claim-height: uint,
  is-active: bool
})

(define-map user-stakes principal (list 50 uint))

(define-map user-streaks principal {
  current-streak: uint,
  last-claim-height: uint,
  longest-streak: uint,
  total-streak-rewards: uint
})

(define-map achievements uint {
  name: (string-ascii 64),
  description: (string-ascii 256),
  required-modules: uint,
  reward-amount: uint,
  total-claims: uint
})

(define-map user-achievements {user: principal, achievement-id: uint} {
  claimed-at: uint
})

(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    (asserts! (or (is-eq from tx-sender) (is-eq from contract-caller)) err-not-token-owner)
    (ft-transfer? finlit-token amount from to)
  )
)

(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (who principal))
  (ok (ft-get-balance finlit-token who))
)

(define-read-only (get-total-supply)
  (ok (ft-get-supply finlit-token))
)

(define-read-only (get-token-uri)
  (ok token-uri)
)

(define-public (approve (spender principal) (amount uint))
  (begin
    (map-set token-supplies-approved {owner: tx-sender, spender: spender} amount)
    (print {action: "approve", owner: tx-sender, spender: spender, amount: amount})
    (ok true)
  )
)

(define-public (revoke (spender principal))
  (begin
    (map-delete token-supplies-approved {owner: tx-sender, spender: spender})
    (print {action: "revoke", owner: tx-sender, spender: spender})
    (ok true)
  )
)

(define-read-only (get-allowance (owner principal) (spender principal))
  (default-to u0 (map-get? token-supplies-approved {owner: owner, spender: spender}))
)

(define-public (transfer-from (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (let (
    (allowance (get-allowance from tx-sender))
  )
    (asserts! (>= allowance amount) err-insufficient-balance)
    (try! (ft-transfer? finlit-token amount from to))
    (map-set token-supplies-approved {owner: from, spender: tx-sender} (- allowance amount))
    (print {action: "transfer-from", from: from, to: to, amount: amount, memo: memo})
    (ok true)
  )
)

(define-fungible-token finlit-token)

(define-private (mint-tokens (recipient principal) (amount uint))
  (begin
    (try! (ft-mint? finlit-token amount recipient))
    (print {action: "mint", recipient: recipient, amount: amount})
    (ok true)
  )
)

(define-public (create-module (title (string-ascii 64)) (description (string-ascii 256)) (reward-amount uint))
  (let (
    (module-id (var-get next-module-id))
  )
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (asserts! (> reward-amount u0) err-invalid-amount)
    (asserts! (not (var-get is-paused)) err-paused)
    (map-set modules module-id {
      title: title,
      description: description,
      reward-amount: reward-amount,
      is-active: true,
      created-at: stacks-block-height,
      total-completions: u0
    })
    (var-set next-module-id (+ module-id u1))
    (print {action: "create-module", module-id: module-id, title: title, reward: reward-amount})
    (ok module-id)
  )
)

(define-public (update-module (module-id uint) (new-reward-amount uint) (is-active bool))
  (let (
    (module (unwrap! (map-get? modules module-id) err-module-not-found))
  )
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (asserts! (> new-reward-amount u0) err-invalid-amount)
    (map-set modules module-id (merge module {
      reward-amount: new-reward-amount,
      is-active: is-active
    }))
    (print {action: "update-module", module-id: module-id, new-reward: new-reward-amount, active: is-active})
    (ok true)
  )
)

(define-public (complete-module (module-id uint))
  (let (
    (module (unwrap! (map-get? modules module-id) err-module-not-found))
    (reward-amount (get reward-amount module))
    (completion-key {user: tx-sender, module-id: module-id})
    (user-rewards (default-to u0 (map-get? user-total-rewards tx-sender)))
    (user-completed-count (default-to u0 (map-get? user-modules-completed tx-sender)))
    (referrer-opt (map-get? user-referrer tx-sender))
  )
    (asserts! (not (var-get is-paused)) err-paused)
    (asserts! (get is-active module) err-module-inactive)
    (asserts! (is-none (map-get? user-completions completion-key)) err-module-already-completed)
    (map-set user-completions completion-key true)
    (map-set user-total-rewards tx-sender (+ user-rewards reward-amount))
    (map-set user-modules-completed tx-sender (+ user-completed-count u1))
    (map-set modules module-id (merge module {
      total-completions: (+ (get total-completions module) u1)
    }))
    (try! (mint-tokens tx-sender reward-amount))
    (match referrer-opt
      referrer
        (let (
          (referrer-bonus (/ (* reward-amount referral-bonus-rate) u100))
        )
          (if (> referrer-bonus u0)
            (try! (mint-tokens referrer referrer-bonus))
            true
          )
        )
      true
    )
    (print {action: "complete-module", user: tx-sender, module-id: module-id, reward: reward-amount})
    (ok reward-amount)
  )
)

(define-public (set-referrer (referrer principal))
  (let (
    (existing (map-get? user-referrer tx-sender))
  )
    (asserts! (is-none existing) err-owner-only)
    (asserts! (not (is-eq referrer tx-sender)) err-owner-only)
    (map-set user-referrer tx-sender referrer)
    (print {action: "set-referrer", user: tx-sender, referrer: referrer})
    (ok true)
  )
)

(define-read-only (get-referrer (user principal))
  (map-get? user-referrer user)
)

(define-public (create-proposal (title (string-ascii 128)) (description (string-ascii 512)) (action-type (string-ascii 32)) (target-module-id (optional uint)) (new-reward-amount (optional uint)) (new-title (optional (string-ascii 64))) (new-description (optional (string-ascii 256))))
  (let (
    (proposal-id (var-get next-proposal-id))
    (user-balance (ft-get-balance finlit-token tx-sender))
    (voting-end-height (+ stacks-block-height voting-period))
  )
    (asserts! (>= user-balance min-voting-power) err-insufficient-voting-power)
    (asserts! (>= user-balance proposal-deposit) err-insufficient-balance)
    (try! (ft-transfer? finlit-token proposal-deposit tx-sender (as-contract tx-sender)))
    (map-set proposals proposal-id {
      proposer: tx-sender,
      title: title,
      description: description,
      action-type: action-type,
      target-module-id: target-module-id,
      new-reward-amount: new-reward-amount,
      new-title: new-title,
      new-description: new-description,
      votes-for: u0,
      votes-against: u0,
      start-height: stacks-block-height,
      end-height: voting-end-height,
      executed: false,
      execution-height: none
    })
    (var-set next-proposal-id (+ proposal-id u1))
    (print {action: "create-proposal", proposal-id: proposal-id, proposer: tx-sender, title: title})
    (ok proposal-id)
  )
)

(define-public (vote-proposal (proposal-id uint) (vote bool))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
    (voter-power (ft-get-balance finlit-token tx-sender))
    (vote-key {proposal-id: proposal-id, voter: tx-sender})
    (current-height stacks-block-height)
  )
    (asserts! (>= voter-power min-voting-power) err-insufficient-voting-power)
    (asserts! (<= current-height (get end-height proposal)) err-voting-ended)
    (asserts! (is-none (map-get? proposal-votes vote-key)) err-already-voted)
    (map-set proposal-votes vote-key {vote: vote, power: voter-power})
    (if vote
      (map-set proposals proposal-id (merge proposal {votes-for: (+ (get votes-for proposal) voter-power)}))
      (map-set proposals proposal-id (merge proposal {votes-against: (+ (get votes-against proposal) voter-power)}))
    )
    (print {action: "vote", proposal-id: proposal-id, voter: tx-sender, vote: vote, power: voter-power})
    (ok true)
  )
)

(define-public (execute-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) err-proposal-not-found))
    (current-height stacks-block-height)
    (votes-for (get votes-for proposal))
    (votes-against (get votes-against proposal))
    (total-votes (+ votes-for votes-against))
  )
    (asserts! (> current-height (+ (get end-height proposal) execution-delay)) err-proposal-not-ready)
    (asserts! (not (get executed proposal)) err-proposal-not-ready)
    (asserts! (> votes-for votes-against) err-proposal-not-ready)
    (asserts! (>= total-votes (/ (ft-get-supply finlit-token) u10)) err-proposal-not-ready)
    (map-set proposals proposal-id (merge proposal {
      executed: true,
      execution-height: (some current-height)
    }))
    (try! (as-contract (ft-transfer? finlit-token proposal-deposit (as-contract tx-sender) (get proposer proposal))))
    (print {action: "execute-proposal", proposal-id: proposal-id, executor: tx-sender})
    (ok true)
  )
)

(define-public (pause-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (var-set is-paused true)
    (print {action: "pause", admin: tx-sender})
    (ok true)
  )
)

(define-public (unpause-contract)
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (var-set is-paused false)
    (print {action: "unpause", admin: tx-sender})
    (ok true)
  )
)

(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (var-set admin new-admin)
    (print {action: "set-admin", old-admin: tx-sender, new-admin: new-admin})
    (ok true)
  )
)

(define-read-only (get-module (module-id uint))
  (map-get? modules module-id)
)

(define-read-only (get-user-completion (user principal) (module-id uint))
  (default-to false (map-get? user-completions {user: user, module-id: module-id}))
)

(define-read-only (get-user-stats (user principal))
  (ok {
    total-rewards: (default-to u0 (map-get? user-total-rewards user)),
    modules-completed: (default-to u0 (map-get? user-modules-completed user)),
    token-balance: (ft-get-balance finlit-token user)
  })
)

(define-read-only (get-proposal (proposal-id uint))
  (map-get? proposals proposal-id)
)

(define-read-only (get-vote (proposal-id uint) (voter principal))
  (map-get? proposal-votes {proposal-id: proposal-id, voter: voter})
)

(define-read-only (get-contract-info)
  (ok {
    total-modules: (- (var-get next-module-id) u1),
    total-proposals: (- (var-get next-proposal-id) u1),
    total-token-supply: (ft-get-supply finlit-token),
    is-paused: (var-get is-paused),
    admin: (var-get admin),
    total-staked: (var-get total-staked)
  })
)

(define-public (create-stake (amount uint))
  (let (
    (stake-id (var-get next-stake-id))
    (user-balance (ft-get-balance finlit-token tx-sender))
    (current-stakes (default-to (list) (map-get? user-stakes tx-sender)))
  )
    (asserts! (not (var-get is-paused)) err-paused)
    (asserts! (>= amount min-stake-amount) err-insufficient-stake)
    (asserts! (>= user-balance amount) err-insufficient-balance)
    (try! (ft-transfer? finlit-token amount tx-sender (as-contract tx-sender)))
    (map-set stakes stake-id {
      staker: tx-sender,
      amount: amount,
      start-height: stacks-block-height,
      last-claim-height: stacks-block-height,
      is-active: true
    })
    (map-set user-stakes tx-sender (unwrap! (as-max-len? (append current-stakes stake-id) u50) err-insufficient-stake))
    (var-set next-stake-id (+ stake-id u1))
    (var-set total-staked (+ (var-get total-staked) amount))
    (print {action: "create-stake", stake-id: stake-id, staker: tx-sender, amount: amount})
    (ok stake-id)
  )
)

(define-public (claim-yield (stake-id uint))
  (let (
    (stake-data (unwrap! (map-get? stakes stake-id) err-no-stake-found))
    (staker (get staker stake-data))
    (amount (get amount stake-data))
    (last-claim (get last-claim-height stake-data))
    (current-height stacks-block-height)
    (blocks-elapsed (- current-height last-claim))
    (yield-amount (/ (* (* amount annual-yield-rate) blocks-elapsed) (* u100 u52560)))
  )
    (asserts! (is-eq tx-sender staker) err-not-token-owner)
    (asserts! (get is-active stake-data) err-no-stake-found)
    (asserts! (> yield-amount u0) err-invalid-amount)
    (map-set stakes stake-id (merge stake-data {
      last-claim-height: current-height
    }))
    (try! (mint-tokens tx-sender yield-amount))
    (print {action: "claim-yield", stake-id: stake-id, staker: tx-sender, yield: yield-amount})
    (ok yield-amount)
  )
)

(define-public (unstake (stake-id uint))
  (let (
    (stake-data (unwrap! (map-get? stakes stake-id) err-no-stake-found))
    (staker (get staker stake-data))
    (amount (get amount stake-data))
    (start-height (get start-height stake-data))
    (current-height stacks-block-height)
  )
    (asserts! (is-eq tx-sender staker) err-not-token-owner)
    (asserts! (get is-active stake-data) err-no-stake-found)
    (asserts! (>= (- current-height start-height) stake-lock-period) err-stake-locked)
    (try! (claim-yield stake-id))
    (map-set stakes stake-id (merge stake-data {
      is-active: false
    }))
    (try! (as-contract (ft-transfer? finlit-token amount (as-contract tx-sender) staker)))
    (var-set total-staked (- (var-get total-staked) amount))
    (print {action: "unstake", stake-id: stake-id, staker: tx-sender, amount: amount})
    (ok amount)
  )
)

(define-read-only (get-stake (stake-id uint))
  (map-get? stakes stake-id)
)

(define-read-only (get-user-stakes (user principal))
  (default-to (list) (map-get? user-stakes user))
)

(define-read-only (calculate-pending-yield (stake-id uint))
  (match (map-get? stakes stake-id)
    stake-data
      (let (
        (amount (get amount stake-data))
        (last-claim (get last-claim-height stake-data))
        (current-height stacks-block-height)
        (blocks-elapsed (- current-height last-claim))
        (yield-amount (/ (* (* amount annual-yield-rate) blocks-elapsed) (* u100 u52560)))
      )
        (if (get is-active stake-data)
          (ok yield-amount)
          (ok u0)
        )
      )
    (ok u0)
  )
)

(define-read-only (get-staking-info)
  (ok {
    total-staked: (var-get total-staked),
    total-stakes: (- (var-get next-stake-id) u1),
    min-stake: min-stake-amount,
    annual-rate: annual-yield-rate,
    lock-period: stake-lock-period
  })
)

(define-public (claim-daily-streak)
  (let (
    (current-height stacks-block-height)
    (user-streak-data (default-to {
      current-streak: u0,
      last-claim-height: u0,
      longest-streak: u0,
      total-streak-rewards: u0
    } (map-get? user-streaks tx-sender)))
    (last-claim (get last-claim-height user-streak-data))
    (current-streak (get current-streak user-streak-data))
    (longest-streak (get longest-streak user-streak-data))
    (total-rewards (get total-streak-rewards user-streak-data))
    (blocks-since-last (- current-height last-claim))
    (is-first-claim (is-eq last-claim u0))
    (is-within-window (and (> blocks-since-last u0) (<= blocks-since-last (* u2 streak-window))))
    (is-new-day (> blocks-since-last streak-window))
  )
    (asserts! (not (var-get is-paused)) err-paused)
    (asserts! (or is-first-claim is-new-day) err-streak-already-claimed)
    (let (
      (new-streak (if (or is-first-claim is-within-window)
        (+ current-streak u1)
        u1
      ))
      (streak-reward (+ streak-base-reward (* streak-base-reward (* (- new-streak u1) streak-multiplier) (/ u1 u100))))
      (new-longest (if (> new-streak longest-streak) new-streak longest-streak))
    )
      (map-set user-streaks tx-sender {
        current-streak: new-streak,
        last-claim-height: current-height,
        longest-streak: new-longest,
        total-streak-rewards: (+ total-rewards streak-reward)
      })
      (try! (mint-tokens tx-sender streak-reward))
      (print {action: "claim-streak", user: tx-sender, streak: new-streak, reward: streak-reward})
      (ok {streak: new-streak, reward: streak-reward})
    )
  )
)

(define-read-only (get-user-streak (user principal))
  (default-to {
    current-streak: u0,
    last-claim-height: u0,
    longest-streak: u0,
    total-streak-rewards: u0
  } (map-get? user-streaks user))
)

(define-read-only (get-streak-status (user principal))
  (let (
    (user-streak-data (get-user-streak user))
    (last-claim (get last-claim-height user-streak-data))
    (current-height stacks-block-height)
    (blocks-since-last (if (is-eq last-claim u0) u0 (- current-height last-claim)))
    (can-claim (or (is-eq last-claim u0) (> blocks-since-last streak-window)))
    (streak-alive (or (is-eq last-claim u0) (<= blocks-since-last (* u2 streak-window))))
  )
    {
      current-streak: (get current-streak user-streak-data),
      longest-streak: (get longest-streak user-streak-data),
      total-rewards: (get total-streak-rewards user-streak-data),
      can-claim-now: can-claim,
      streak-alive: streak-alive,
      blocks-until-claim: (if can-claim u0 (- streak-window blocks-since-last))
    }
  )
)

(define-public (create-achievement (name (string-ascii 64)) (description (string-ascii 256)) (required-modules uint) (reward-amount uint))
  (let (
    (achievement-id (var-get next-achievement-id))
  )
    (asserts! (is-eq tx-sender (var-get admin)) err-not-admin)
    (asserts! (not (var-get is-paused)) err-paused)
    (asserts! (> reward-amount u0) err-invalid-amount)
    (asserts! (> required-modules u0) err-invalid-amount)
    (map-set achievements achievement-id {
      name: name,
      description: description,
      required-modules: required-modules,
      reward-amount: reward-amount,
      total-claims: u0
    })
    (var-set next-achievement-id (+ achievement-id u1))
    (print {action: "create-achievement", achievement-id: achievement-id, name: name})
    (ok achievement-id)
  )
)

(define-public (claim-achievement (achievement-id uint))
  (let (
    (achievement (unwrap! (map-get? achievements achievement-id) err-achievement-not-found))
    (user-completed (default-to u0 (map-get? user-modules-completed tx-sender)))
    (claim-key {user: tx-sender, achievement-id: achievement-id})
  )
    (asserts! (not (var-get is-paused)) err-paused)
    (asserts! (is-none (map-get? user-achievements claim-key)) err-achievement-already-claimed)
    (asserts! (>= user-completed (get required-modules achievement)) err-requirements-not-met)
    (map-set user-achievements claim-key {
      claimed-at: stacks-block-height
    })
    (map-set achievements achievement-id (merge achievement {
      total-claims: (+ (get total-claims achievement) u1)
    }))
    (try! (mint-tokens tx-sender (get reward-amount achievement)))
    (print {action: "claim-achievement", user: tx-sender, achievement-id: achievement-id, reward: (get reward-amount achievement)})
    (ok (get reward-amount achievement))
  )
)

(define-read-only (get-achievement (achievement-id uint))
  (map-get? achievements achievement-id)
)

(define-read-only (get-user-achievement (user principal) (achievement-id uint))
  (map-get? user-achievements {user: user, achievement-id: achievement-id})
)

(define-read-only (has-achievement (user principal) (achievement-id uint))
  (is-some (map-get? user-achievements {user: user, achievement-id: achievement-id}))
)

(mint-tokens contract-owner u10000000000)

