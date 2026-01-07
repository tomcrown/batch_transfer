# Sui Batch Transfer Contract

A Sui Move smart contract for efficiently sending tokens to multiple recipients in a single transaction. Perfect for airdrops, payroll distributions, and bulk payments.

## Features

- **Batch Transfer with Custom Amounts**: Send different amounts to different recipients
- **Equal Amount Distribution**: Send the same amount to all recipients (gas-optimized)
- **Automatic Refunds**: Any leftover tokens are automatically returned to sender
- **Type Safety**: Works with any Sui coin type (SUI, USDC, etc.)
- **Event Tracking**: Emits detailed events for every batch transfer
- **Error Handling**: Comprehensive validation and clear error messages

## Prerequisites

- [Sui CLI](https://docs.sui.io/guides/developer/getting-started/sui-install) installed 
- A Sui wallet with sufficient balance for gas fees
- Basic understanding of Sui Move and command-line operations

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/tomcrown/batch_transfer.git
cd batch_transfer
```

### 2. Project Structure

```
batch_transfer/
├── Move.toml
└── sources/
    └── batch_transfer.move
```

### 3. Build the Contract

```bash
sui move build
```

If successful, you should see:

```
BUILDING batch_transfer
```

### 4. Deploy to Sui Network

#### Deploy to Testnet

```bash
sui client publish --gas-budget 100000000
```

#### Deploy to Mainnet

```bash
sui client publish --gas-budget 100000000
```

After deployment, save the **Package ID** from the output. You'll need this for all function calls.

Example output:

```
Published Objects:
  PackageID: 0x1234567890abcdef...
```

## Usage

### Function 1: batch_transfer

Send different amounts to different recipients.

#### Parameters

- `coin`: The coin object to split and distribute
- `recipients`: Vector of recipient addresses (must be in JSON array format)
- `amounts`: Vector of amounts corresponding to each recipient (in the smallest unit)
- `type-args`: The coin type (e.g., `0x2::sui::SUI`)

#### Example: Send Different Amounts

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module batch_transfer \
  --function batch_transfer \
  --type-args 0x2::sui::SUI \
  --args <COIN_OBJECT_ID> \
         '["0xRECIPIENT_ADDRESS_1","0xRECIPIENT_ADDRESS_2","0xRECIPIENT_ADDRESS_3"]' \
         '[1000000000,2000000000,3000000000]' \
  --gas-budget 10000000
```

This example sends:

- 1 SUI to recipient 1
- 2 SUI to recipient 2
- 3 SUI to recipient 3

### Function 2: batch_transfer_equal

Send the same amount to all recipients (more gas-efficient for equal distributions).

#### Parameters

- `coin`: The coin object to split and distribute
- `recipients`: Vector of recipient addresses
- `amount_each`: Amount to send to each recipient
- `type-args`: The coin type

#### Example: Send Equal Amounts

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module batch_transfer \
  --function batch_transfer_equal \
  --type-args 0x2::sui::SUI \
  --args <COIN_OBJECT_ID> \
         '["0xRECIPIENT_ADDRESS_1","0xRECIPIENT_ADDRESS_2","0xRECIPIENT_ADDRESS_3"]' \
         1000000000 \
  --gas-budget 10000000
```

This sends 1 SUI to each of the three recipients.

## Understanding Coin Amounts

Sui tokens use different decimal places. Always specify amounts in the smallest unit:

| Token | Decimals | 1 Token    | Example Amount      |
| ----- | -------- | ---------- | ------------------- |
| SUI   | 9        | 1000000000 | 0.1 SUI = 100000000 |
| USDC  | 6        | 1000000    | 1 USDC = 1000000    |
| USDT  | 6        | 1000000    | 1 USDT = 1000000    |

### Amount Calculation Examples

```
0.5 SUI = 500000000
10 SUI = 10000000000
100 USDC = 100000000
0.01 USDC = 10000
```

## Getting Coin Objects

Before calling the contract, you need a coin object ID.

### List Your Coins

```bash
sui client gas
```

This shows all your coin objects with their IDs and amounts.


## Using Different Coin Types

The contract works with any Sui coin type. Replace the `--type-args` parameter:

### SUI (Native Token)

```bash
--type-args 0x2::sui::SUI
```

### USDC

```bash
--type-args <USDC_PACKAGE_ID>::usdc::USDC
```

### Custom Token

```bash
--type-args <TOKEN_PACKAGE_ID>::<MODULE_NAME>::<TYPE_NAME>
```

## Advanced Usage Examples

### Example 1: Airdrop to 10 Recipients

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module batch_transfer \
  --function batch_transfer_equal \
  --type-args 0x2::sui::SUI \
  --args <COIN_OBJECT_ID> \
         '["0xaddr1","0xaddr2","0xaddr3","0xaddr4","0xaddr5","0xaddr6","0xaddr7","0xaddr8","0xaddr9","0xaddr10"]' \
         100000000 \
  --gas-budget 20000000
```

### Example 2: Payroll with Different Salaries

```bash
sui client call \
  --package <PACKAGE_ID> \
  --module batch_transfer \
  --function batch_transfer \
  --type-args 0x2::sui::SUI \
  --args <COIN_OBJECT_ID> \
         '["0xemployee1","0xemployee2","0xemployee3"]' \
         '[5000000000,3000000000,2000000000]' \
  --gas-budget 10000000
```

## Events

Each successful batch transfer emits a `BatchTransferEvent` with:

```rust
{
    sender: address,           // Address that initiated the transfer
    total_recipients: u64,     // Number of recipients
    total_amount: u64,         // Total amount transferred
    coin_type: TypeName        // Type of coin used (e.g., "0x2::sui::SUI")
}
```


## Error Codes

| Code | Constant             | Description                                           |
| ---- | -------------------- | ----------------------------------------------------- |
| 0    | EMismatchedLengths   | Recipients and amounts vectors have different lengths |
| 1    | EInsufficientBalance | Coin balance is less than the total amount needed     |
| 2    | EEmptyRecipients     | Recipients vector is empty                            |

### Common Error Solutions

**Error: "EMismatchedLengths"**

- Ensure recipients and amounts arrays have the same length
- Check for missing commas in your vectors

**Error: "EInsufficientBalance"**

- Verify your coin has enough balance
- Check you're using the correct decimal places
- Use `sui client gas` to verify coin balance

**Error: "EEmptyRecipients"**

- Ensure your recipients vector is not empty
- Check JSON array formatting

**Error: "Cannot convert string arg to vector"**

- Wrap addresses in double quotes within square brackets
- Use proper JSON array format: `'["0xaddr1","0xaddr2"]'`


## Security Considerations

1. **Immutable Contract**: Once deployed, the contract cannot be modified
2. **No Admin Functions**: No special privileges or backdoors
3. **Automatic Refunds**: Leftover funds automatically return to sender
4. **Type Safety**: Generic type system prevents sending wrong token types
5. **Validation**: All inputs are validated before execution

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test thoroughly on testnet
4. Submit a pull request with detailed description
