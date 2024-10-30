use aiken/collection/list
use aiken/collection/pairs
use cardano/address.{Address, Credential}
use cardano/assets.{lovelace_of, merge, zero}
use cardano/transaction.{Transaction}

/// Fail in every other case (unlock UTxOs nor mint)
validator stake_validator(addr: Address) {
  /// Do whatever you want with the credentials
  publish(_r, _certificate, _tx) {
    True
  }

  /// If you want to withdraw, you have to give half of the rewards to `addr`
  withdraw(_r, account: Credential, tx: Transaction) {
    // Number of lovelaces we are withdrawing as rewards
    expect Some(withdraw_amount) = tx.withdrawals |> pairs.get_first(account)
    // Get UTxOs created in `addr`
    let addr_outputs = list.filter(tx.outputs, fn(o) { o.address == addr })
    // Caluculate total amount of lovelace sent to `addr`
    let amount_paid_to_addr =
      list.foldl(addr_outputs, zero, fn(n, acc) { merge(n.value, acc) })
        |> lovelace_of()
    // Validator checks
    (2 * amount_paid_to_addr >= withdraw_amount)?
  }

  else(_) {
    fail
  }
}
