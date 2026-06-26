pub mod TaskRepository.CreateTask {
  use Task.Task

  pub eff CreateTask {
    def createTask(title: String, description: Option[String]
                   , dependsOn: Option[Nel[Task]]): Result[TaskRepository.TaskRepositoryError, Task]
  }
}
