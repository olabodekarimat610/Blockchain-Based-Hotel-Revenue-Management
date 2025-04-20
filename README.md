# Blockchain-Based Hotel Revenue Management

A decentralized platform for transparent hotel revenue management leveraging blockchain technology and smart contracts.

## Overview

This system provides a comprehensive solution for hotel revenue management through blockchain technology. By implementing interconnected smart contracts, the platform ensures transparent operations, dynamic pricing strategies, optimized inventory distribution, and competitive performance tracking for accommodation providers.

## Core Components

### Property Verification Contract
- Validates legitimate accommodation providers
- Stores essential property information and credentials
- Maintains compliance records and certifications
- Creates verifiable digital identity for hotels

### Rate Strategy Contract
- Defines pricing for different booking windows
- Implements dynamic pricing algorithms based on market conditions
- Manages seasonal adjustments and special event pricing
- Automates rate changes based on occupancy thresholds

### Inventory Allocation Contract
- Manages room availability by distribution channel
- Prevents overbooking through blockchain-verified inventory
- Optimizes distribution across direct and third-party channels
- Enables real-time updates to availability across all platforms

### Performance Tracking Contract
- Monitors revenue against competitors
- Calculates key performance indicators (RevPAR, ADR, Occupancy)
- Provides market share analysis through anonymous data aggregation
- Generates actionable insights for revenue optimization

## Getting Started

### Prerequisites
- Ethereum wallet (MetaMask recommended)
- Ethereum development environment (Truffle/Hardhat)
- Node.js (v16+)
- Web3.js or ethers.js

### Installation

1. Clone the repository
```
git clone https://github.com/yourusername/hotel-revenue-blockchain.git
cd hotel-revenue-blockchain
```

2. Install dependencies
```
npm install
```

3. Compile smart contracts
```
npx hardhat compile
```

4. Deploy to test network
```
npx hardhat run scripts/deploy.js --network <network-name>
```

## Usage Examples

### Register a New Property
```javascript
await propertyContract.registerProperty(
  "Oceanview Resort",
  "789 Beach Boulevard",
  4, // star rating
  250, // total rooms
  ["Pool", "Restaurant", "Conference facilities"]
);
```

### Set Dynamic Pricing
```javascript
await rateContract.setDynamicRate(
  propertyId,
  "Standard Room",
  199.00, // base rate in USD
  [
    { daysAhead: 90, discount: 15 }, // 15% off for 90+ days
    { daysAhead: 30, discount: 5 }, // 5% off for 30+ days
    { daysAhead: 7, premium: 10 } // 10% premium for <7 days
  ]
);
```

### Update Channel Inventory
```javascript
await inventoryContract.allocateInventory(
  propertyId,
  "Standard Room",
  [
    { channel: "direct", allocation: 15 },
    { channel: "OTA-A", allocation: 10 },
    { channel: "OTA-B", allocation: 5 }
  ],
  "2025-06-15" // date
);
```

### Track Performance Metrics
```javascript
await performanceContract.recordDailyMetrics(
  propertyId,
  "2025-04-19", // date
  85.5, // occupancy percentage
  219.99, // average daily rate
  188.09 // RevPAR
);
```

## Benefits

- **Transparency**: Immutable records of rates, inventory, and performance
- **Security**: Cryptographically secured transactions and data
- **Efficiency**: Automated pricing adjustments and inventory management
- **Data Integrity**: Verified competitive and market intelligence
- **Trust**: Provable property credentials and specifications

## Future Development

- Integration with property management systems (PMS)
- Tokenized guest loyalty programs
- Smart contract-based commission payments to OTAs
- Decentralized review verification system
- AI-powered revenue optimization algorithms

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
