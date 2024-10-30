use aiken/collection/list
use aiken_plutus_v3/util.{PKH}
use cardano/address.{Script}
use cardano/assets.{AssetName, PolicyId, quantity_of}
use cardano/transaction.{
  DatumHash, InlineDatum, Input, NoDatum, Output, OutputReference, Transaction,
  find_datum,
}

// Uniquely identify an asset
pub type AssetClass {
  policy_id: PolicyId,
  name: AssetName,
}

// Script parameterized by OracleParams
pub type OracleParams {
  o_nft: AssetClass,
  o_operator: PKH,
}

// Oracle's Redeemer
pub type OracleRedeemer {
  Update
  Delete
}

// Oracle's Datum
type Rate =
  Int

validator oracle(params: OracleParams) {
  spend(
    _datum: Option<Rate>,
    redeemer: OracleRedeemer,
    utxo_ref: OutputReference,
    tx: Transaction,
  ) {
    let is_signed_by_operator =
      list.has(tx.extra_signatories, params.o_operator)
    when redeemer is {
      Update -> {
        // Get the oracle's input
        expect Some(oracle_input) =
          tx.inputs
            |> transaction.find_input(utxo_ref)
        // Fail if oracle's input doesn't contain NFT
        expect
          1 == quantity_of(
            oracle_input.output.value,
            params.o_nft.policy_id,
            params.o_nft.name,
          )
        // Get the oracle's script hash
        expect Script(oracle_hash) =
          oracle_input.output.address.payment_credential
        // Get the oracle's output
        expect [oracle_output] =
          list.filter(
            tx.outputs,
            fn(o) {
              when o.address.payment_credential is {
                Script(output_hash) -> oracle_hash == output_hash
                _ -> False
              }
            },
          )
        // Fail if oracle's output doesn't contain NFT
        expect
          1 == quantity_of(
            oracle_output.value,
            params.o_nft.policy_id,
            params.o_nft.name,
          )
        // Get and parse the oracle's output datum
        let is_valid_output_datum =
          when oracle_output.datum is {
            NoDatum -> False
            DatumHash(dh) -> {
              // Fail if the datum is not there
              expect Some(d) = find_datum([oracle_output], tx.datums, dh)
              // Fail if the datum is not an integer
              expect Some(_rate): Option<Rate> = d
              True
            }
            InlineDatum(d) -> {
              // Fail if the datum is not an integer
              expect Some(_rate): Option<Rate> = d
              True
            }
          }

        // Final checks
        // Only the operator can delete the oracle &&
        // Fail if the oracle's output datum is not valid
        is_signed_by_operator? && is_valid_output_datum?
      }
      Delete ->
        // Only the operator can delete the oracle
        is_signed_by_operator?
    }
  }

  else(_) {
    fail
  }
}
