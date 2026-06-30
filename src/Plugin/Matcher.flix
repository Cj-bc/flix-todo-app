pub mod Plugin.Matcher {
  pub trait Matcher[t] {
    type Aef: Eff
    type Args

    // can run any effect required to match
    // I named this "matcher" rather than "filter" because of side effect
    // also, I couldn't use "match" as function name because it is reserved keyword.
    pub def doMatch(t: t, args: Matcher.Args[t]): List[Task] \ Matcher.Aef[t]
  }
}
