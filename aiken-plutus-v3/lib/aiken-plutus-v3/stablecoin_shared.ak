use aiken_plutus_v3/util.{PKH}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{Transaction}

const stablecoinTokenName = "stablecoin"

/// Get the number (as Int) of the amount of tokens minted in this transaction.
pub fn get_total_minted_stablecoin(tx: Transaction, policy_id: PolicyId) -> Int {
  tx.mint
    |> quantity_of(policy_id, stablecoinTokenName)
}

pub type CollateralDatum {
  col_minting_policy_id: PolicyId,
  col_owner: PKH,
  col_stablecoin_amount: Int,
}
