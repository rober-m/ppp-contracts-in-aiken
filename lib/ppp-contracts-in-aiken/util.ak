use aiken/builtin
use aiken/dict.{to_list}
use aiken/transaction/value.{MintedValue, PolicyId, from_minted_value, tokens}

pub fn trace_if_false(message: String, expr: Bool) -> Bool {
  if expr {
    expr
  } else {
    builtin.debug(message, expr)
  }
}

pub fn this_policy_minted_values(mint: MintedValue, policy_id: PolicyId) {
  mint |> from_minted_value() |> tokens(policy_id) |> to_list()
}
