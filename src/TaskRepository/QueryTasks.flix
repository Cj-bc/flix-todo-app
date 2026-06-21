pub mod TaskRepository.QueryTasks {
  use Task.Task

  pub eff QueryTasks {
    def queryTasks(filter: Task -> Bool): List[Task]
  }

//   // pub def queryDependencies(task: Task): List[Task] \ QueryTasks
//   //   = {
      
//   //   https://github.com/ababup1192/flix_todo_list}

  pub def queryAllTasks(): List[Task] \ QueryTasks = queryTasks(constant(true))
  
  pub def runWithTaskRepository(f: Unit -> a \ ef): a \ (ef - QueryTasks) + TaskRepository =
    run { f() } with handler QueryTasks {
      def queryTasks
    }
}
