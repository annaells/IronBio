# IronBio 🔐

**Biometric Bitcoin Recovery System**

A decentralized hardware wallet recovery solution using distributed biometric data stored across Stacks smart contracts. IronBio eliminates single points of failure by splitting biometric authentication data across multiple network nodes while maintaining privacy and security.

## 🚀 Features

- **Distributed Security**: Biometric data is split into shards and distributed across multiple storage nodes
- **Threshold Recovery**: Configurable recovery thresholds (3-7 shards) prevent single point compromises
- **Privacy First**: Only cryptographic hashes of biometric data are stored on-chain
- **Node Reputation**: Built-in reputation system for storage node reliability
- **Bitcoin Integration**: Seamless recovery for Bitcoin hardware wallets
- **Audit Trail**: Complete recovery attempt logging and transparency

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Hardware      │    │   IronBio       │    │   Storage       │
│   Wallet        │◄──►│   Contract      │◄──►│   Nodes         │
│                 │    │   (Stacks)      │    │   Network       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                        │                        │
         │                        │                        │
         ▼                        ▼                        ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Biometric     │    │   Recovery      │    │   Distributed   │
│   Authentication│    │   Process       │    │   Shard Storage │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 📋 Prerequisites

- Stacks blockchain node or access to Stacks network
- Clarinet for local development and testing
- Node.js and npm for frontend integration
- Hardware wallet with biometric capabilities

## 🛠️ Installation

### Clone the Repository
```bash
git clone https://github.com/annaells/IronBio.git
cd IronBio
```

### Install Clarinet
```bash
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xz
sudo mv clarinet /usr/local/bin
```

### Initialize Project
```bash
clarinet new ironbio-project
cd ironbio-project
```

### Deploy Contract
```bash
clarinet console
(contract-call? .ironbio create-vault 0x1234... u5 u7 0xabcd...)
```

## 📖 Usage

### Creating a Biometric Vault

```clarity
;; Create a new vault with 5-of-7 threshold
(contract-call? .ironbio create-vault 
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef  ;; vault-id
  u5                                                                    ;; threshold
  u7                                                                    ;; total-shards
  0xfedcba0987654321fedcba0987654321fedcba0987654321fedcba0987654321) ;; wallet-hash
```

### Storing Biometric Shards

```clarity
;; Store shard 0
(contract-call? .ironbio store-shard
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef  ;; vault-id
  u0                                                                  ;; shard-index
  0x9876543210fedcba9876543210fedcba9876543210fedcba9876543210fedcba) ;; shard-hash
```

### Recovery Process

```clarity
;; Initiate recovery with 5 shards
(contract-call? .ironbio initiate-recovery
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef  ;; vault-id
  (list u0 u1 u2 u3 u4))                                             ;; provided-shards

;; Complete recovery with biometric proof
(contract-call? .ironbio complete-recovery
  0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef  ;; vault-id
  u0                                                                  ;; attempt-id
  0x1a2b3c4d5e6f7890a1b2c3d4e5f67890a1b2c3d4e5f67890a1b2c3d4e5f67890) ;; biometric-proof
```

### Registering as Storage Node

```clarity
;; Register as a storage node
(contract-call? .ironbio register-node)
```

## 🔍 Contract Functions

### Public Functions

| Function | Description | Parameters |
|----------|-------------|------------|
| `create-vault` | Create new biometric vault | vault-id, threshold, total-shards, wallet-hash |
| `store-shard` | Store biometric shard | vault-id, shard-index, shard-hash |
| `register-node` | Register as storage node | none |
| `initiate-recovery` | Start recovery process | vault-id, provided-shards |
| `complete-recovery` | Finalize recovery | vault-id, attempt-id, biometric-proof |
| `unlock-vault` | Unlock vault after recovery | vault-id |

### Read-Only Functions

| Function | Description | Returns |
|----------|-------------|---------|
| `get-vault-info` | Get vault details | Vault metadata |
| `get-shard-info` | Get shard information | Shard details |
| `get-node-info` | Get node statistics | Node reputation data |
| `get-recovery-attempt` | Get recovery attempt details | Attempt metadata |

## 🧪 Testing

### Run Unit Tests
```bash
clarinet test
```

### Integration Testing
```bash
clarinet console
::set_epoch 2.1
(contract-call? .ironbio create-vault ...)
```

### Load Testing
```bash
# Test with multiple concurrent operations
clarinet run scripts/load-test.ts
```

## 🔒 Security Considerations

- **Biometric Privacy**: Only cryptographic hashes stored on-chain
- **Threshold Security**: Minimum 3-of-5 shard requirement prevents single point failure
- **Node Distribution**: Shards distributed across independent storage nodes
- **Recovery Locking**: Temporary vault locking during active recovery attempts
- **Access Control**: Owner-only vault management operations

## 🌐 Network

### Mainnet Deployment
- Contract Address: `SP1234...ABCD.ironbio` (TBD)
- Network: Stacks Mainnet
- Bitcoin Integration: Native Stacks-Bitcoin bridge

### Testnet
- Contract Address: `ST1234...ABCD.ironbio`
- Network: Stacks Testnet
- Faucet: Available for testing

### Development Setup
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Code Standards
- Follow Clarity best practices
- Include comprehensive tests
- Document all public functions
- Maintain security-first approach

## 📊 Roadmap

- [x] Core smart contract implementation
- [x] Basic recovery mechanism
- [ ] Frontend dashboard
- [ ] Mobile biometric integration
- [ ] Hardware wallet partnerships
- [ ] Multi-signature support
- [ ] Cross-chain compatibility
- [ ] Enterprise features
