// Gift validator
validator {
  fn gift(_datum: Data, _redeemer: Data, _ctx: Data) {
    True
  }
}

// Burn validator
validator {
  fn burn(_datum: Data, _redeemer: Data, _ctx: Data) {
    False
  }
}

// 42 validator typed
validator {
  fn forty_two_typed(_datum: Data, r: Int, _ctx: Data) {
    let redemerIs42 = r == 42
    redemerIs42?
  }
}
