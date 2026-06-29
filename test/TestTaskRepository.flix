mod TestTaskRepository {
  use Task.Task
  use Task.TaskId
  use Task.StatusSelf
  use TaskRepository.InMemory.runInMemory

  /// Raw Int64 id of a task.
  def idOf(task: Task): Int64 =
    let TaskId.TaskId(n) = Task.taskId(task);
    n

  /// Id of the first task returned by `addTask`, or -1 on failure.
  def addedId(r: Result[e, Task]): Int64 = match r {
    case Ok(task) => idOf(task)
    case Err(_)   => -1i64
  }

  @Test
  def addThenList_findsTask(): Unit \ Assert =
    runInMemory(() -> {
      let _ = Cli.addTask("buy milk");
      Assert.assertEq(expected = 1, List.length(Cli.listTasks()))
    })

  @Test
  def newTask_startsNotPlanned(): Unit \ Assert =
    runInMemory(() -> {
      let _ = Cli.addTask("buy milk");
      let st = Cli.listTasks() |> List.head |> Option.map(Task.status) |> Option.getWithDefault(StatusSelf.Done);
      Assert.assertEq(expected = StatusSelf.NotPlanned, st)
    })

  @Test
  def createTask_assignsIncreasingIds(): Unit \ Assert =
    runInMemory(() -> {
      let first = addedId(Cli.addTask("a"));
      let second = addedId(Cli.addTask("b"));
      Assert.assertEq(expected = true, first < second)
    })

  @Test
  def completeTask_setsStatusDone(): Unit \ Assert =
    runInMemory(() -> {
      let id = addedId(Cli.addTask("buy milk"));
      let _ = Cli.completeTask(id);
      let st = Cli.listTasks() |> List.head |> Option.map(Task.status) |> Option.getWithDefault(StatusSelf.NotPlanned);
      Assert.assertEq(expected = StatusSelf.Done, st)
    })

  @Test
  def completeTask_unknownId_returnsErr(): Unit \ Assert =
    runInMemory(() -> {
      Assert.assertEq(expected = true, Result.isErr(Cli.completeTask(404i64)))
    })

  @Test
  def removeTask_dropsTaskFromList(): Unit \ Assert =
    runInMemory(() -> {
      let id = addedId(Cli.addTask("buy milk"));
      let _ = Cli.removeTask(id);
      Assert.assertEq(expected = 0, List.length(Cli.listTasks()))
    })

  @Test
  def removeTask_unknownId_returnsErr(): Unit \ Assert =
    runInMemory(() -> {
      Assert.assertEq(expected = true, Result.isErr(Cli.removeTask(404i64)))
    })
}
