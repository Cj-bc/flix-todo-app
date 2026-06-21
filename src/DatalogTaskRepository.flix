pub mod DatalogTaskRepository {
  use TaskRepository.AddTasks.AddTasks
  use Task.Task

  pub enum DatalogTaskRepository(#{ Task(Task) }, FilePath)

  pub def readFromFile()

  pub def getRepository(path: String): #{ Task(Task) } \ IO

  def runWithDatalog(db: #{ Task(Task) | r }, f: Unit -> a \ ef): a \ (ef - QueryTasks) =
    run { f() } with Querytasks {
    }
}