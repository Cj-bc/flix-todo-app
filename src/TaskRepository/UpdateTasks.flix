pub mod TaskRepository.UpdateTasks {
  use Task.Task

  pub eff UpdateTask {
    def updateTask(task: Task): Unit
  }

}