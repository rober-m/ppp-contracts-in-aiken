use aiken/crypto.{Blake2b_224, Hash, Script, VerificationKey}

pub type PKH =
  Hash<Blake2b_224, VerificationKey>

pub type ScriptHash =
  Hash<Blake2b_224, Script>
