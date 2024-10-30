use aiken/collection/list.{has}
use aiken_plutus_v3/stablecoin_shared.{
  CollateralDatum, get_total_minted_stablecoin,
}
use aiken_plutus_v3/util.{ScriptHash}
use cardano/address.{Script}
use cardano/assets.{PolicyId, lovelace_of}
use cardano/transaction.{
  DatumHash, InlineDatum, Input, NoDatum, Output, Transaction,
  find_script_outputs,
}

pub type MintingParams {
  mp_oracle_validator: ScriptHash,
  mp_collateral_minPercent: Int,
}

pub type MintingRedeemer {
  Minting
  Burning
  Liquidating
}

pub type CollateralRedeemer {
  Redeem
  Liquidate
}

validator mint_stablecoins(params: MintingParams) {
  spend(
    datum: Option<CollateralDatum>,
    redeemer: CollateralRedeemer,
    _utxo,
    tx: Transaction,
  ) {
    // We  only allow to consume collateral with datums
    expect Some(d) = datum
    // /// Check if the transaction is signed by the collateral owner
    // /// I only care about this in the "Redeem" case.
    let check_signed_by_col_owner = has(tx.extra_signatories, d.col_owner)

    // /// Get the number (as Int) of the amount of tokens minted in this transaction.
    let stablecoin_minted =
      get_total_minted_stablecoin(tx, d.col_minting_policy_id)
    // /// Check if I'm burning in this transaction the same amount that was minted in
    // /// the transaction that created the collateral.
    // /// I care about this in all cases.
    let check_stablecoin_amount = -d.col_stablecoin_amount == stablecoin_minted
    // Final Checks
    when redeemer is {
      // /// If I'm Liquidating, I only need to make sure I'm burning the correct
      // /// amount of stablecoins.
      Liquidate -> check_stablecoin_amount?
      // /// If I'm redeemeing, I have to make sure I'm burning the same amount of 
      // /// stablecoins I minted previously and that I'm the owner of the collateral.
      Redeem -> check_stablecoin_amount? && check_signed_by_col_owner?
    }
  }

  mint(redeemer: MintingRedeemer, policy_id: PolicyId, tx: Transaction) {
    // ////////////////////////////////////////////////////////////////////////////////////
    // ///////////////////////////////// ORACLE ///////////////////////////////////////////
    // Get oracle's reference rate.
    // get_oracle_rate() Fails if there are more than one input or if the oracle's output is not an Int
    let oracle_rate: Int =
      get_oracle_rate(tx.reference_inputs, params.mp_oracle_validator)
    // ////////////////////////////////////////////////////////////////////////////////////
    // ///////////////////////////// COLLATERAL OUTPUT ////////////////////////////////////
    // /// Get collateral output
    expect [collateral_output]: List<Output> =
      find_script_outputs(tx.outputs, policy_id)
    // /// Parse collateral output datum
    let collateral_output_datum: CollateralDatum =
      get_collateral_datum(collateral_output)
    // /// Get collateral's output amount of lovelaces being locked
    let collateral_output_amount: Int = lovelace_of(collateral_output.value)

    // /// Check that the collateral's output datum has the correct values
    let check_collateral_output_datum: Bool = and {
        collateral_output_datum.col_stablecoin_amount == collateral_output_amount,
        collateral_output_datum.col_minting_policy_id == policy_id,
        list.has(tx.extra_signatories, collateral_output_datum.col_owner),
      }
    // ////////////////////////////////////////////////////////////////////////////////////
    // ////////////////////////////// COLLATERAL INPUT ////////////////////////////////////
    // /// Get collateral input
    expect [collateral_input]: List<Output> =
      find_script_outputs(list.map(tx.inputs, fn(i) { i.output }), policy_id)
    // /// Parse collateral input datum
    let collateral_input_datum: CollateralDatum =
      get_collateral_datum(collateral_input)
    // /// Get collateral's input amount of lovelaces being unlocked
    let collateral_input_amount: Int = lovelace_of(collateral_input.value)
    // ////////////////////////////////////////////////////////////////////////////////////
    // ////////////////////////////////// MINTING /////////////////////////////////////////
    // /// Get amount of stablecoins minted in this transaction
    let stablecoin_minted_amount: Int =
      get_total_minted_stablecoin(tx, policy_id)
    // /// Check that the amount of stablecoins minted is positive
    let check_mint_positive = stablecoin_minted_amount > 0
    // /// Check that the amount of stablecoins burned is negative
    let check_burn_negative = stablecoin_minted_amount < 0
    // /// Check that the amount of stablecoins minted does not exceed the maximum
    let check_max_mint: Bool =
      max_mint(
        collateral_output_amount,
        oracle_rate,
        params.mp_collateral_minPercent,
      ) >= stablecoin_minted_amount
    // /// Check that the amount of stablecoins burned matches the amont at the collateral's datum
    let check_burn_matches_datum: Bool =
      -collateral_input_datum.col_stablecoin_amount == stablecoin_minted_amount
    // /// Check if the collateral's value is low enough to liquidate
    let check_liquidation: Bool =
      max_mint(
        collateral_input_amount,
        oracle_rate,
        params.mp_collateral_minPercent,
      ) < -stablecoin_minted_amount
    // ////////////////////////////////////////////////////////////////////////////////////
    // //////////////////////////////// OWNER CHECKS //////////////////////////////////////
    // /// Check that collateral's owner signature is present
    let check_owner_signature: Bool =
      list.has(tx.extra_signatories, collateral_input_datum.col_owner)
    // ////////////////////////////////////////////////////////////////////////////////////
    // //////////////////////////////// FINAL CHECKS //////////////////////////////////////
    when redeemer is {
      Minting -> and {
          check_mint_positive?,
          check_collateral_output_datum?,
          check_max_mint?,
        }
      Burning -> and {
          check_burn_negative?,
          check_burn_matches_datum?,
          check_owner_signature?,
        }
      Liquidating -> and {
          check_liquidation?,
          check_burn_matches_datum?,
          check_burn_negative?,
        }
    }
  }

  else(_) {
    fail
  }
}

fn get_oracle_rate(reference_inputs: List<Input>, oracle_val: ScriptHash) -> Int {
  // /// Filter all reference inputs to only the ones that come from the oracle script
  expect [oracle_input] =
    list.filter(
      reference_inputs,
      fn(i) {
        when i.output.address.payment_credential is {
          // /// If the input is from a script, save it if it's the oracle's one
          Script(scriptHash) -> scriptHash == oracle_val
          // /// If the input is from a PKH, drop it 
          _ -> False
        }
      },
    )
  // /// Get oracle's rate from the datum
  expect oracle_rate: Int =
    when oracle_input.output.datum is {
      NoDatum -> fail @"Couldn't find oracle's datum"
      DatumHash(_datum_hash) -> fail @"Oracle's datum is not inlined"
      InlineDatum(datum) -> datum
    }
  oracle_rate
}

fn get_collateral_datum(output: Output) -> CollateralDatum {
  expect output_datum: CollateralDatum =
    when output.datum is {
      NoDatum -> fail @"Collateral output datum is missing"
      DatumHash(_datum_hash) -> fail @"Collateral output datum is not inlined"
      InlineDatum(datum) -> datum
    }
  output_datum
}

// /// max_mint calculates the maximum amount of stablecoins that can be minted with the given collateral.
//
// /// Oracle has ada price in USD cents [USD¢] ($1 is ¢100 in the oracle's datum). So rate needs to be divided by 100.
// /// Also, collateral_output_amount is in lovelaces [L], so final calculation needs to be divided by 1_000_000.
//
// /// ca = col_amount
// /// CMP = mp_collateral_min_percent
//
//
// ///                   ca [L]        rate [USD¢/ADA]                 ca [L]       
// ///              --------------- * ------------------           --------------- * rate [USD/ADA]
// ///                   CMP [%]        100 [USD¢/USD]                   CMP                         
// ///                 ---------                                               
// ///                   100 [%]                                               
// /// max_mint = ------------------------------------------- =  ------------------------------------- = [USD]
// ///                     1_000_000 [L/A]                                1_000_000 [L/A]
// /// 
fn max_mint(col_amount: Int, rate: Int, col_min_percent: Int) -> Int {
  col_amount / col_min_percent * rate / 1_000_000
}
