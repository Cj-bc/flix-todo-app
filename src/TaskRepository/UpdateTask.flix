pub mod TaskRepository.UpdateTask {
  use Task.Task

  pub eff UpdateTask {
    def updateTask(task: Task): Unit
  }
}
