# 💰 Financial Literacy Reward Program DAO

> 🎓 A decentralized autonomous organization that rewards users with tokens for completing educational modules on personal finance.

## 🌟 Features

- 📚 **Educational Module System** - Create, manage, and track completion of financial literacy courses
- 🪙 **Token Rewards** - Earn FinLit Tokens (FLT) for completing educational modules
- 🗳️ **DAO Governance** - Token-holder voting on proposals to update modules and rewards
- 👥 **User Progress Tracking** - Monitor individual learning progress and achievements  
- ⚡ **Real-time Minting** - Automatic token rewards upon module completion
- 🔐 **Admin Controls** - Pause/unpause functionality and administrative safeguards
- 📊 **Transparency** - All activities recorded on-chain with full audit trail

## 🚀 Quick Start

### Prerequisites

- [Clarinet](https://docs.hiro.so/stacks/clarinet) installed
- [Node.js](https://nodejs.org/) v16+ for testing
- Basic understanding of Stacks blockchain and Clarity smart contracts

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/Financial-Literacy-Reward-Program.git
   cd Financial-Literacy-Reward-Program
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Check contract compilation**
   ```bash
   clarinet check
   ```

4. **Run tests**
   ```bash
   npm test
   ```

## 📖 Usage Guide

### For Learners 🎯

#### Complete Educational Modules
```clarity
(contract-call? .financial-literacy-reward-program complete-module u1)
```

#### Check Your Progress
```clarity
(contract-call? .financial-literacy-reward-program get-user-stats tx-sender)
```

#### View Your Token Balance
```clarity
(contract-call? .financial-literacy-reward-program get-balance tx-sender)
```

### For Administrators 👨‍💼

#### Create New Educational Module
```clarity
(contract-call? .financial-literacy-reward-program create-module 
  "Budgeting Basics" 
  "Learn fundamental budgeting principles and create your first budget" 
  u1000000) ;; 1 FLT reward
```

#### Update Module Rewards
```clarity
(contract-call? .financial-literacy-reward-program update-module 
  u1 
  u2000000 ;; 2 FLT reward
  true) ;; keep active
```

#### Pause Contract (Emergency)
```clarity
(contract-call? .financial-literacy-reward-program pause-contract)
```

### For DAO Members 🏛️

#### Create Governance Proposal
```clarity
(contract-call? .financial-literacy-reward-program create-proposal
  "Increase Module 1 Reward"
  "Proposal to increase budgeting basics module reward from 1 to 2 FLT"
  "update-module"
  (some u1) ;; target module
  (some u2000000) ;; new reward amount
  none
  none)
```

#### Vote on Proposal
```clarity
;; Vote YES (true) or NO (false)
(contract-call? .financial-literacy-reward-program vote-proposal u1 true)
```

#### Execute Approved Proposal
```clarity
(contract-call? .financial-literacy-reward-program execute-proposal u1)
```

## 🏗️ Contract Architecture

### Core Components

- **🪙 Token System**: Custom fungible token with minting capabilities
- **📚 Module Management**: CRUD operations for educational content
- **👤 User Progress**: Individual completion tracking and rewards
- **🗳️ DAO Governance**: Proposal creation, voting, and execution
- **🛡️ Admin Controls**: Emergency functions and contract management

### Key Functions

| Function | Description | Access Level |
|----------|-------------|-------------|
| `complete-module` | 🎓 Mark module as completed, receive rewards | Public |
| `create-module` | ➕ Add new educational module | Admin Only |
| `create-proposal` | 📝 Create DAO governance proposal | Token Holders |
| `vote-proposal` | 🗳️ Vote on active proposals | Token Holders |
| `execute-proposal` | ⚡ Execute approved proposals | Public |
| `pause-contract` | ⏸️ Emergency pause functionality | Admin Only |

### Data Structures

#### Modules Map
```clarity
{
  title: (string-ascii 64),
  description: (string-ascii 256), 
  reward-amount: uint,
  is-active: bool,
  created-at: uint,
  total-completions: uint
}
```

#### Proposals Map  
```clarity
{
  proposer: principal,
  title: (string-ascii 128),
  description: (string-ascii 512),
  action-type: (string-ascii 32),
  votes-for: uint,
  votes-against: uint,
  start-height: uint,
  end-height: uint,
  executed: bool
}
```

## 🎮 Testing

### Run Unit Tests
```bash
npm test
```

### Run Integration Tests
```bash
npm run test:integration
```

### Test Coverage
```bash
npm run coverage
```

## 🔧 Configuration

### Token Parameters
- **Name**: FinLit Token
- **Symbol**: FLT  
- **Decimals**: 6
- **Initial Supply**: 10,000 FLT (admin)

### Governance Parameters
- **Minimum Voting Power**: 1 FLT
- **Voting Period**: 1,008 blocks (~1 week)
- **Execution Delay**: 144 blocks (~1 day)
- **Proposal Deposit**: 500 FLT

## 🛡️ Security Features

- ✅ **Access Control**: Role-based permissions for critical functions
- ✅ **Reentrancy Protection**: Safe state updates and token transfers
- ✅ **Input Validation**: Comprehensive parameter checking
- ✅ **Emergency Controls**: Pause functionality for security incidents
- ✅ **Transparent Governance**: All votes and proposals on-chain

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♀️ Support

For questions and support:
- 📧 Email: support@finlit-dao.com
- 💬 Discord: [FinLit DAO Community](https://discord.gg/finlit-dao)
- 🐦 Twitter: [@FinLitDAO](https://twitter.com/FinLitDAO)

## 🗺️ Roadmap

- [ ] 🎨 Web3 frontend interface
- [ ] 📱 Mobile app integration  
- [ ] 🏆 NFT certificates for course completion
- [ ] 🔗 Cross-chain token bridging
- [ ] 📈 Advanced analytics dashboard
- [ ] 🤖 AI-powered personalized learning paths

---

**Built with ❤️ for financial education and blockchain innovation**

# Financial Literacy Reward Program

