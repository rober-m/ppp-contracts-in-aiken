use cardano/script_context.{ScriptContext}

/// "Gift" (always true) validator
/// Always returns true
validator always_true {
  else(_) {
    True
  }
}

/// "Burn" (always false) validator
/// Always returns false
validator always_false {
  else(_) {
    trace @"this is a trace message"
    trace @"this is another trace message"
    False
  }
}

/// "42" (check for exact value of redeemer) validator
/// Returns true if the redeemer is 42
validator forty_two {
  else(ctx: ScriptContext) {
    expect redeemer: Int = ctx.redeemer
    42 == redeemer
  }
}
