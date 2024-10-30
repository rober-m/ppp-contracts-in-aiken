use aiken/interval.{Finite, Interval}
use aiken/time.{PosixTime}
use aiken/transaction.{ScriptContext, Spend, Transaction}

type CustomDatum {
  CustomDatum { deadline: PosixTime }
}

validator {
  fn negative_r_timed(
    datum: CustomDatum,
    redeemer: Int,
    ctx: ScriptContext,
  ) -> Bool {
    when ctx.purpose is {
      Spend(_) -> {
        let Transaction { validity_range: Interval { lower_bound, .. }, .. } =
          ctx.transaction
        let is_deadline_reached =
          when lower_bound.bound_type is {
            Finite(tx_earliest_time) -> datum.deadline <= tx_earliest_time
            _ -> False
          }

        // Validator checks
        (redeemer <= 0)? && is_deadline_reached?
      }
      _ -> False
    }
  }
}
