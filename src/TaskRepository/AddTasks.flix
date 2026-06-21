pub mod TaskRepository.AddTasks {
  pub eff AddTasks {
    def addTask(task: Task): Option[AddTaskError]
  }
}