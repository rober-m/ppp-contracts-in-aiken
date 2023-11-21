use aiken/dict.{to_list}
use aiken/hash.{Blake2b_224, Hash}
use aiken/list
use aiken/transaction.{Mint, OutputReference, ScriptContext, Transaction}
use aiken/transaction/credential.{VerificationKey}
use aiken/transaction/value.{from_minted_value, tokens}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

// Free tokens minting policy
validator {
  fn free_tokens(_r: Data, _ctx: ScriptContext) -> Bool {
    True
  }
}

// Tokens only a specific user can mint
validator {
  fn signed_tokens(vkh: VerificationKeyHash, ctx: ScriptContext) -> Bool {
    when ctx.purpose is {
      // If it's a minting transaction, check if it's signed by the right user
      Mint(_) -> list.has(ctx.transaction.extra_signatories, vkh)?
      // If it's not a minting transaction, reject it
      _ -> False
    }
  }
}

// NFT policy
validator(utxo_ref: OutputReference, token_name: ByteArray) {
  fn nft_policy(_r: Data, ctx: ScriptContext) -> Bool {
    // Pattern-match to get policy_id and Fail if it's not a minting transaction
    expect Mint(policy_id) = ctx.purpose
    // Pattern-match to get the transaction inputs and minted values
    let ScriptContext { transaction: Transaction { inputs, mint, .. }, .. } =
      ctx
    // Pattern-match to get the minted tokens and Fail if it's not a single asset minted
    expect [(asset_name, amount)] =
      mint |> from_minted_value() |> tokens(policy_id) |> to_list()
    // Check if the transaction consumes the utxo_ref passed as parameter
    let is_ouput_consumed =
      list.any(inputs, fn(input) { input.output_reference == utxo_ref })
    // Final checks
    is_ouput_consumed? && (1 == amount)? && (asset_name == token_name)?
  }
}
// TODO: Test the policies
