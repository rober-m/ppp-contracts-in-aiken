use aiken/collection/dict.{to_pairs}
use aiken/collection/list
use aiken/crypto.{Blake2b_224, Hash, VerificationKey}
use cardano/assets.{PolicyId, tokens}
use cardano/transaction.{OutputReference, Transaction}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

/// Free tokens minting policy
/// This has the same effect than the `always_true` policy for minting purpose but
/// unlike the `always_true` policy, it doesn't allow for any other purpose than minting.
validator free_tokens {
  mint(_r, _policy_id, _tx) {
    True
  }

  else(_) {
    fail
  }
}

/// Tokens only a specific user can mint
/// This policy allows minting tokens only if the transaction is signed by a
/// specific user. It doesn't allow for any other purpose.
validator signed_tokens {
  mint(vkh: VerificationKeyHash, _policy_id, tx: Transaction) {
    // Check if it's signed by the right user
    list.has(tx.extra_signatories, vkh)?
  }

  else(_) {
    fail
  }
}

// NFT ("one shot") policy
validator nft(utxo_ref: OutputReference, token_name: ByteArray) {
  mint(_r, policy_id: PolicyId, tx: Transaction) {
    // Pattern-match to get the transaction inputs and minted values
    let Transaction { inputs, mint, .. } = tx
    // Pattern-match to get the minted tokens and Fail if it's not a single asset minted
    expect [Pair(asset_name, amount)] = mint |> tokens(policy_id) |> to_pairs()
    // Check if the transaction consumes the utxo_ref passed as parameter
    let is_ouput_consumed =
      list.any(inputs, fn(input) { input.output_reference == utxo_ref })
    // Final checks
    is_ouput_consumed? && (1 == amount)? && (asset_name == token_name)?
  }

  else(_) {
    fail
  }
}
