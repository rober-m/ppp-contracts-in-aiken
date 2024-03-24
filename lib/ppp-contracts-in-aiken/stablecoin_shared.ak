use aiken/dict
use aiken/list
use aiken/transaction.{ScriptContext}
use aiken/transaction/value.{PolicyId, from_minted_value, tokens}
use ppp_contracts_in_aiken/util.{PKH}

const stablecoinTokenName = "stablecoin"

/// Get the number (as Int) of the amount of tokens minted in this transaction.
pub fn get_total_minted_stablecoin(
  ctx: ScriptContext,
  policy_id: PolicyId,
) -> Int {
  ctx.transaction.mint
    |> from_minted_value()
    |> tokens(policy_id)
    |> dict.filter(fn(asset_name, _v) { asset_name == stablecoinTokenName })
    |> dict.values()
    |> list.foldl(0, fn(n, total) { n + total })
}

pub type CollateralDatum {
  col_minting_policy_id: PolicyId,
  col_owner: PKH,
  col_stablecoin_amount: Int,
}
