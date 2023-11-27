use aiken/dict
use aiken/list
use aiken/transaction.{Publish, ScriptContext, WithdrawFrom}
use aiken/transaction/credential.{Address}
use aiken/transaction/value.{lovelace_of}

validator(addr: Address) {
  fn stake_validator(_r: Data, ctx: ScriptContext) -> Bool {
    when ctx.purpose is {
      // Do whatever you want with the credentials
      Publish(_) -> True
      // If you want to withdraw, you have to give half of the rewards to `addr`
      WithdrawFrom(stake_credential) -> {
        let ts = ctx.transaction
        // Number of lovelaces we are withdrawing as rewards
        expect Some(withdraw_amount) =
          ts.withdrawals |> dict.get(stake_credential)
        // Get UTxOs created in `addr`
        let addr_outputs = list.filter(ts.outputs, fn(o) { o.address == addr })
        // Caluculate total amount of lovelace sent to `addr`
        let amount_paid_to_addr =
          list.foldl(
            addr_outputs,
            value.zero(),
            fn(n, acc) { value.merge(n.value, acc) },
          )
            |> lovelace_of()
        // Validator checks
        (2 * amount_paid_to_addr >= withdraw_amount)?
      }
      // Fail in every other case (unlock UTxOs nor mint)
      _ -> False
    }
  }
}
