use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId, from_minted_value, quantity_of}
use ppp_contracts_in_aiken/util.{PKH}

const stablecoinTokenName = "stablecoin"

/// Get the number (as Int) of the amount of tokens minted in this transaction.
pub fn get_total_minted_stablecoin(
  ctx: ScriptContext,
  policy_id: PolicyId,
) -> Int {
  ctx.transaction.mint
    |> from_minted_value()
    |> quantity_of(policy_id, stablecoinTokenName)
}

pub type CollateralDatum {
  col_minting_policy_id: PolicyId,
  col_owner: PKH,
  col_stablecoin_amount: Int,
}
