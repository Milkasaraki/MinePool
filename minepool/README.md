# MinePool

MinePool is a Clarity smart contract enabling decentralized, fractional ownership of cryptocurrency mining rigs. It facilitates transparent reward distribution and governance through hashrate-based voting, allowing miners to collectively manage and optimize mining operations.

---

## 🚀 Features

- **Rig Deployment**  
  Pool operators can deploy new mining rigs specifying model, hashrate capacity, price, rewards, and pool manager.

- **Fractional Hashrate Purchase**  
  Miners can buy hashrate shares in specific rigs, enabling collaborative ownership and rewards.

- **Automated Reward Distribution**  
  Rewards are distributed based on hashrate contribution per day, with claim tracking for fairness.

- **Optimization Governance**  
  Miners can propose technical optimizations and vote based on their hashrate stake.

- **Security Checks**  
  All functions use strict permission checks to prevent unauthorized actions.

---

## 🛠️ Contract Overview

### Constants

- `POOL_OPERATOR`: The address allowed to deploy new rigs.
- `ERR_*`: Standardized error codes for common failure cases.

### Key Maps

- `mining-rigs`: Tracks deployed rigs and their details.
- `miner-hashrate`: Tracks each miner’s hashrate per rig.
- `reward-claims`: Prevents multiple reward claims for the same day.
- `rig-optimizations`: Stores proposals for rig upgrades or changes.
- `optimization-votes`: Prevents double voting and records voter stance.

---

## 📦 Public Functions

### Deployment & Purchase

- `deploy-rig(rig-model, total-hashrate, hashrate-price, daily-rewards, pool-manager)`
- `buy-hashrate(rig-id, hashrate-amount)`

### Rewards

- `distribute-rewards(rig-id, day)`
- `claim-rewards(rig-id, day)`

### Optimization Governance

- `create-optimization(rig-id, name, details, voting-period)`
- `vote-optimization(optimization-id, supports)`

---

## 🔍 Read-only Functions

- `get-rig(rig-id)`
- `get-hashrate-balance(rig-id, miner)`
- `get-optimization(optimization-id)`
- `calculate-reward-share(rig-id, miner)`

---

## 📋 Example Workflow

1. **Operator** deploys a new rig.
2. **Miners** buy shares of hashrate.
3. **Pool Manager** distributes rewards daily.
4. **Miners** claim their rewards.
5. **Miners** propose or vote on rig optimizations.

---

## 🧪 Notes

- All votes are weighted by hashrate.
- Rewards are calculated daily based on the proportion of hashrate owned.
- Voting period is set during optimization proposal creation.
- Contract assumes reward payments are off-chain or via an extended function.

