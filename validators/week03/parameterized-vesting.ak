use aiken/hash.{Blake2b_224, Hash}
use aiken/interval.{Finite}
use aiken/list
use aiken/time.{PosixTime}
use aiken/transaction.{ScriptContext, Spend, ValidityRange}
use aiken/transaction/credential.{VerificationKey}

type VerificationKeyHash =
  Hash<Blake2b_224, VerificationKey>

type VestingParameters {
  VestingParameters { beneficiary: VerificationKeyHash, deadline: PosixTime }
}

// Create non-parameterized vesting validator
validator(params: VestingParameters) {
  fn vesting(_d: Data, _r: Data, ctx: ScriptContext) -> Bool {
    // Pattern match on the transaction purpose
    when ctx.purpose is {
      // It's a spending transaction
      Spend(_) -> and {
          // The transaction must be signed by the beneficiary
          must_be_signed_by(
            ctx.transaction.extra_signatories,
            params.beneficiary,
          )?,
          // The transaction must be after the deadline
          must_be_after_deadline(
            ctx.transaction.validity_range,
            params.deadline,
          )?,
        }
      // The transaction purpose is something else
      _ -> False
    }
  }
}

fn must_be_signed_by(signatories, beneficiary) -> Bool {
  // Check if the beneficiary is in the list of signatories
  list.has(signatories, beneficiary)
}

fn must_be_after_deadline(range: ValidityRange, deadline: PosixTime) -> Bool {
  // Pattern match for the type of the lower bound
  when range.lower_bound.bound_type is {
    // If the lower bound is finite, check if it's after the deadline
    Finite(tx_earliest_time) -> deadline <= tx_earliest_time
    // Else, the lower bound is infinite, so we fail
    _ -> False
  }
}

// Tests
test must_start_after_succeed_when_lower_bound_is_after() {
  must_be_after_deadline(interval.after(2), 1)
}

test must_start_after_succeed_when_lower_bound_is_equal() {
  must_be_after_deadline(interval.after(2), 2)
}

test must_start_after_fail_when_lower_bound_is_before() {
  !must_be_after_deadline(interval.after(2), 3)
}
