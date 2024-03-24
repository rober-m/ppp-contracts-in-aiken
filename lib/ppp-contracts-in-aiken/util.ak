use aiken/builtin
use aiken/dict.{to_list}
use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{Script, VerificationKey}
use aiken/transaction/value.{MintedValue, PolicyId, from_minted_value, tokens}

pub type PKH =
  Hash<Blake2b_224, VerificationKey>

pub type ScriptHash =
  Hash<Blake2b_224, Script>

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
