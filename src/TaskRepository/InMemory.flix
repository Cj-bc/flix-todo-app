/// In-memory adapter for the TaskRepository capability effects.
///
/// `runInMemory` interprets the four `TaskRepository` effects against a mutable
/// store that lives only for the duration of the call (process memory). Each
/// effect is supplied by its own `with handler`, so a computation can only
/// perform an operation that has been granted here.
pub mod TaskRepository.InMemory {
  use Task.Task
  use Task.TaskId
  use TaskRepository.CreateTask.CreateTask
  use TaskRepository.QueryTasks.QueryTasks
  use TaskRepository.UpdateTask.UpdateTask
  use TaskRepository.DeleteTask.DeleteTask
  use TaskRepository.TaskRepositoryError.TaskRepositoryError

  /// Raw `Int64` behind a `TaskId`, used as the store key (TaskId has no Order).
  def idValue(task: Task): Int64 =
    let TaskId.TaskId(n) = Task.taskId(task);
    n

  /// Run `f`, handling every TaskRepository effect against a fresh in-memory store.
  /// All four capabilities are discharged here, so the result keeps only `ef`.
  pub def runInMemory(f: Unit -> a \ ef): a \ (ef - CreateTask - QueryTasks - UpdateTask - DeleteTask) =
    region rc {
      let nextId = Ref.fresh(rc, 1i64);
      let tasks = Ref.fresh(rc, (Map.empty(): Map[Int64, Task]));
      run {
        f()
      } with handler CreateTask {
        def createTask(title, description, dependsOn, resume) = {
          let id = Ref.get(nextId);
          Ref.put(id + 1i64, nextId);
          let task = Task.newTask(id, title, description, Task.StatusSelf.NotPlanned, dependsOn);
          Ref.put(Map.insert(id, task, Ref.get(tasks)), tasks);
          resume(Ok(task))
        }
      } with handler QueryTasks {
        def queryTasks(filter, resume) =
          resume(Ref.get(tasks) |> Map.valuesOf |> List.filter(filter))
      } with handler UpdateTask {
        def updateTask(task, resume) = {
          Ref.put(Map.insert(idValue(task), task, Ref.get(tasks)), tasks);
          resume()
        }
      } with handler DeleteTask {
        def deleteTask(task, resume) = {
          let id = idValue(task);
          let current = Ref.get(tasks);
          let existed = Map.memberOf(id, current);
          Ref.put(Map.remove(id, current), tasks);
          resume(if (existed) None else Some(TaskRepositoryError.Delete))
        }
      }
    }
}
