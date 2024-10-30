use aiken/interval.{Finite, Interval}
use cardano/transaction.{Transaction}

pub type CustomDatum {
  CustomDatum { deadline: Int }
}

validator negative_r_timed {
  spend(datum: Option<CustomDatum>, redeemer: Int, _uxto_ref, tx: Transaction) {
    expect Some(d) = datum
    let Transaction { validity_range: Interval { lower_bound, .. }, .. } = tx
    let is_deadline_reached =
      when lower_bound.bound_type is {
        Finite(tx_earliest_time) -> d.deadline <= tx_earliest_time
        _ -> False
      }

    // Validator checks
    (redeemer <= 0)? && is_deadline_reached?
  }

  else(_) {
    fail
  }
}
