pub mod TaskRepository.DeleteTask {
  use TaskRepository.TaskRepositoryError

  pub eff DeleteTask {
    def deleteTask(task: Task): Option[TaskRepositoryError]
  }
}
