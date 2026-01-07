module batch_transfer::batch_transfer;
use sui::coin::{Self, Coin};
use sui::balance::Self;
use sui::event;
use std::type_name::{Self,TypeName};

// Error codes
const EMismatchedLengths: u64 = 0;
const EInsufficientBalance: u64 = 1;
const EEmptyRecipients: u64 = 2;

// Event emitted when a batch transfer is completed
public struct BatchTransferEvent has copy, drop {
    sender: address,
    total_recipients: u64,
    total_amount: u64,
    coin_type: TypeName

}

// Batch transfer tokens to multiple recipients
#[allow(lint(self_transfer))]
public fun batch_transfer<T>(
    coin: Coin<T>,
    recipients: vector<address>,
    amounts: vector<u64>,
    ctx: &mut TxContext
) {
    let recipients_len = vector::length(&recipients);
    let amounts_len = vector::length(&amounts);

    assert!(recipients_len == amounts_len, EMismatchedLengths);
    assert!(recipients_len > 0, EEmptyRecipients);
    
    let mut total_amount = 0u64;
    let mut i = 0;
    
    while (i < amounts_len) {
        let amount = *vector::borrow(&amounts, i);
        total_amount = total_amount + amount;
        i = i + 1;
    };
    
    let coin_value = coin::value(&coin);
    assert!(coin_value >= total_amount, EInsufficientBalance);
    
    let mut balance = coin::into_balance(coin);
    
    i = 0;
    while (i < recipients_len) {
        let recipient = *vector::borrow(&recipients, i);
        let amount = *vector::borrow(&amounts, i);
        
        let split_balance = balance::split(&mut balance, amount);
        let split_coin = coin::from_balance(split_balance, ctx);
        transfer::public_transfer(split_coin, recipient);
        
        i = i + 1;
    };
    
    if (balance::value(&balance) > 0) {
        let remaining_coin = coin::from_balance(balance, ctx);
        transfer::public_transfer(remaining_coin, tx_context::sender(ctx));
    } else {
        balance::destroy_zero(balance);
    };
    
    event::emit(BatchTransferEvent {
        sender: tx_context::sender(ctx),
        total_recipients: recipients_len,
        total_amount,
        coin_type: type_name::with_defining_ids<T>()
    });
}

// Batch transfer with equal amounts to all recipients
#[allow(lint(self_transfer))]
public fun batch_transfer_equal<T>(
    coin: Coin<T>,
    recipients: vector<address>,
    amount_each: u64,
    ctx: &mut TxContext
) {
    let recipients_len = vector::length(&recipients);
    assert!(recipients_len > 0, EEmptyRecipients);
    
    let total_amount = amount_each * recipients_len;
    let coin_value = coin::value(&coin);
    assert!(coin_value >= total_amount, EInsufficientBalance);
    
    let mut balance = coin::into_balance(coin);
    let mut i = 0;
    
    while (i < recipients_len) {
        let recipient = *vector::borrow(&recipients, i);
        let split_balance = balance::split(&mut balance, amount_each);
        let split_coin = coin::from_balance(split_balance, ctx);
        transfer::public_transfer(split_coin, recipient);
        i = i + 1;
    };
    
    if (balance::value(&balance) > 0) {
        let remaining_coin = coin::from_balance(balance, ctx);
        transfer::public_transfer(remaining_coin, tx_context::sender(ctx));
    } else {
        balance::destroy_zero(balance);
    };
    
    event::emit(BatchTransferEvent {
        sender: tx_context::sender(ctx),
        total_recipients: recipients_len,
        total_amount,
        coin_type: type_name::with_defining_ids<T>()
    });
}
