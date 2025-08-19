# GiftChain Smart Contract

A secure and flexible STX token gifting system built on Stacks blockchain using Clarity.

## Features

- 🎁 Create gifts with custom messages and optional pool support
- 💸 Partial claiming mechanism
- ⏰ Auto-refund system for expired gifts
- 📝 Transaction history tracking
- 🔒 Secure hash-based gift identification
- 💰 Platform fee implementation

## Contract Details

### Constants
```clarity
PLATFORM-FEE: 1000 micro-STX
```

### Error Codes

| Code | Description |
|------|-------------|
| 100  | Invalid amount |
| 101  | Invalid expiry |
| 102  | Already claimed |
| 103  | Gift not found |
| 104  | Unauthorized |
| 105  | Gift expired |

## Public Functions

### 1. Create Gift
```clarity
(create-gift-extended (hash-code (buff 32)) 
                     (amount uint)
                     (expiry-block uint)
                     (message (string-utf8 100))
                     (pool-id (optional uint)))
```

### 2. Claim Gift
```clarity
(partial-claim (hash-code (buff 32)) 
              (claim-amount uint))
```

### 3. Refund Expired Gift
```clarity
(refund-expired (hash-code (buff 32)))
```

## Read-Only Functions

- `get-gift-message`: Retrieve gift message
- `get-gift-history`: Get transaction history for a gift

## Security Features

- Expiry-based access control
- Sender authentication
- Amount validation
- Safe partial claiming mechanism
- Transaction logging

## Usage Example

```clarity
;; Create a new gift
(contract-call? .giftchain create-gift-extended 
    0x1234567890 
    u1000000 
    u100000 
    "Happy Birthday!" 
    none)

;; Claim part of a gift
(contract-call? .giftchain partial-claim 
    0x1234567890 
    u500000)
```

## Development

### Prerequisites
- Clarinet
- Stacks Wallet
- Node.js

### Testing
```bash
clarinet test
```



---
Built with ❤️ for the Stacks ecosystem
