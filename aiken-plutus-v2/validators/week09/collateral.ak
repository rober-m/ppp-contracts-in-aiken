use aiken/list.{has}
use aiken/transaction.{ScriptContext, Spend}
use ppp_contracts_in_aiken/stablecoin_shared.{
  CollateralDatum, get_total_minted_stablecoin,
}

type CollateralRedeemer {
  Redeem
  Liquidate
}

validator {
  fn collateral(
    datum: CollateralDatum,
    redeemer: CollateralRedeemer,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        // /// Check if the transaction is signed by the collateral owner
        // /// I only care about this in the "Redeem" case.
        let check_signed_by_col_owner =
          has(ctx.transaction.extra_signatories, datum.col_owner)

        // /// Get the number (as Int) of the amount of tokens minted in this transaction.
        let stablecoin_minted =
          get_total_minted_stablecoin(ctx, datum.col_minting_policy_id)
        // /// Check if I'm burning in this transaction the same amount that was minted in
        // /// the transaction that created the collateral.
        // /// I care about this in all cases.
        let check_stablecoin_amount =
          -datum.col_stablecoin_amount == stablecoin_minted
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
      _ -> False
    }
  }
}
