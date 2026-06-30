pub mod ExternalPlugins.RemainingTasksMatcher {
  use Plugin.Matcher
  use TaskRepository.QueryTasks

  pub enum RemainingTasksMatcher

  instance Matcher[RemainingTasksMatcher] {
    type Aef = { QueryTasks }
    type Args = Unit
    pub def doMatch(_: RemainingTasksMatcher, _: Unit): List[Task] \ { QueryTasks } =
      QueryTasks.queryTasks(Task.status >> (st -> st == Task.StatusSelf.Done))
  }
}
