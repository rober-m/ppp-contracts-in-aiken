use aiken/builtin
use aiken/hash.{Blake2b_224, Hash}
use aiken/transaction/credential.{Script, VerificationKey}

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
