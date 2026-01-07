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

- [Sui CLI](https://docs.sui.io/build/install) installed 
- A Sui wallet with sufficient balance for gas fees
- Basic understanding of Sui Move and command-line operations

## Installation

### 1. Clone the Repository

```bash
git clone <your-repo-url>
cd batch_transfer
```

### 2. Project Structure

```
batch_transfer/
├── Move.toml
└── sources/
    └── batch_transfer.move
```

### 3. Configure Move.toml

Create a `Move.toml` file in the project root:

```toml
[package]
name = "batch_transfer"
version = "0.0.1"
edition = "2024.beta"

[dependencies]
Sui = { git = "https://github.com/MystenLabs/sui.git", subdir = "crates/sui-framework/packages/sui-framework", rev = "framework/mainnet" }

[addresses]
batch_transfer = "0x0"
```

### 4. Build the Contract

```bash
sui move build
```

If successful, you should see:

```
BUILDING batch_transfer
```

### 5. Deploy to Sui Network

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

### Merge Multiple Coins (Optional)

If you have multiple small coin objects, merge them first:

```bash
sui client merge-coin \
  --primary-coin <COIN_ID_1> \
  --coin-to-merge <COIN_ID_2> \
  --gas-budget 5000000
```

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

### Example 3: Using Programmable Transaction Blocks (PTB)

For more complex operations, use PTBs:

```bash
sui client ptb \
  --split-coins gas '[1000000000, 2000000000]' \
  --assign splits \
  --move-call <PACKAGE_ID>::batch_transfer::batch_transfer \
    '<0x2::sui::SUI>' \
    '@splits.0' \
    '["0xrecipient1","0xrecipient2"]' \
    '[1000000000,2000000000]' \
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

### Viewing Events

After a transaction, view events using:

```bash
sui client events --digest <TRANSACTION_DIGEST>
```

Or query all events for the package:

```bash
sui client events --package <PACKAGE_ID>
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

## Best Practices

### 1. Test on Testnet First

Always test your batch transfers on testnet before using mainnet:

```bash
sui client switch --env testnet
```

### 2. Verify Addresses

Double-check all recipient addresses before executing. Wrong addresses cannot be reversed.

### 3. Calculate Gas Budget

Estimate gas based on number of recipients:

- 1-10 recipients: 10000000 (0.01 SUI)
- 11-50 recipients: 20000000 (0.02 SUI)
- 51-100 recipients: 50000000 (0.05 SUI)

### 4. Split Large Batches

For very large airdrops (100+ recipients), split into multiple transactions to avoid gas limits.

### 5. Keep Transaction Records

Save transaction digests for auditing:

```bash
sui client call ... > transaction_record.txt
```

## Troubleshooting

### Issue: "Insufficient gas"

**Solution**: Increase the `--gas-budget` parameter:

```bash
--gas-budget 20000000
```

### Issue: "Object not found"

**Solution**: Verify the coin object ID exists and you own it:

```bash
sui client objects
```

### Issue: "Type mismatch"

**Solution**: Ensure the `--type-args` matches your coin object's type exactly.

### Issue: Command line truncates long vectors

**Solution**: Save arguments to a file and use:

```bash
sui client call --package <PACKAGE_ID> --module batch_transfer --function batch_transfer @args.json
```

Where `args.json` contains:

```json
{
  "type_args": ["0x2::sui::SUI"],
  "args": [
    "0xCOIN_OBJECT_ID",
    ["0xaddr1", "0xaddr2", "0xaddr3"],
    [1000000000, 2000000000, 3000000000]
  ]
}
```

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
