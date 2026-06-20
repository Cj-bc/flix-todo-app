pub mod LocalDateTime {
  use Time.Clock
  use Time.TimeUnit

  pub enum LocalDateTime(Int64) with Eq, Order, Hash

  pub def now(): LocalDateTime \ Clock
   = LocalDateTime(Clock.currentTime(TimeUnit.Seconds))

  pub def today(): LocalDateTime \ Clock
   = LocalDateTime(Clock.currentTime(TimeUnit.Days))

  pub def between(a: LocalDateTime, b: LocalDateTime): LocalDateTime =
    let LocalDateTime(at) = a;
    let LocalDateTime(bt) = b;
    LocalDateTime(Int64.abs(at - bt))
}
