pub mod WriteTasks {
  use Task.Task

  pub eff WriteTasks {
    def write(task: Task): Unit
  }
}