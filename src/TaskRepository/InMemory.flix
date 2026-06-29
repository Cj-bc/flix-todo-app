/// In-memory backing store for the TaskRepository capability effects.
///
/// The store logic lives in plain functions (`create`/`queryBy`/`update`/`delete`)
/// over a process-local pair of `Ref`s. Effect resolution is done with
/// `run ... with handler` at the edges that need it: `runInMemory` (used by the
/// tests) here, and `main` for the real program. Both simply delegate their
/// handler bodies to the functions below, so the store logic is not duplicated.
pub mod TaskRepository.InMemory {
  use Task.Task
  use Task.TaskId
  use TaskRepository.CreateTask.CreateTask
  use TaskRepository.QueryTasks.QueryTasks
  use TaskRepository.UpdateTask.UpdateTask
  use TaskRepository.DeleteTask.DeleteTask
  use TaskRepository.TaskRepositoryError.TaskRepositoryError

  /// A mutable in-memory store: the next id to assign and the tasks by id.
  pub type alias Store[r: Region] = { nextId = Ref[Int64, r], tasks = Ref[Map[TaskId, Task], r] }

  /// Create an empty store in region `r`.
  pub def freshStore(rc: Region[r]): Store[r] \ r =
    { nextId = Ref.fresh(rc, 1i64), tasks = Ref.fresh(rc, Map.empty()) }

  pub def create(store: Store[r], title: String, description: Option[String],
                 dependsOn: Option[Nel[Task]]): Result[TaskRepositoryError, Task] \ r =
    let id = Ref.get(store#nextId);
    Ref.put(id + 1i64, store#nextId);
    let task = Task.newTask(id, title, description, Task.StatusSelf.NotPlanned, dependsOn);
    Ref.put(Map.insert(Task.taskId(task), task, Ref.get(store#tasks)), store#tasks);
    Ok(task)

  pub def queryBy(store: Store[r], filter: Task -> Bool): List[Task] \ r =
    Ref.get(store#tasks) |> Map.valuesOf |> List.filter(filter)

  pub def update(store: Store[r], task: Task): Unit \ r =
    Ref.put(Map.insert(Task.taskId(task), task, Ref.get(store#tasks)), store#tasks)

  pub def delete(store: Store[r], task: Task): Option[TaskRepositoryError] \ r =
    let id = Task.taskId(task);
    let current = Ref.get(store#tasks);
    let existed = Map.memberOf(id, current);
    Ref.put(Map.remove(id, current), store#tasks);
    if (existed) None else Some(TaskRepositoryError.Delete)

  /// Run `f`, handling every TaskRepository effect against a fresh in-memory
  /// store. All four capabilities are discharged here, so the result keeps `ef`.
  pub def runInMemory(f: Unit -> a \ ef): a \ (ef - CreateTask - QueryTasks - UpdateTask - DeleteTask) =
    region rc {
      let store = freshStore(rc);
      run {
        f()
      } with handler CreateTask {
        def createTask(title, description, dependsOn, resume) =
          resume(create(store, title, description, dependsOn))
      } with handler QueryTasks {
        def queryTasks(filter, resume) =
          resume(queryBy(store, filter))
      } with handler UpdateTask {
        def updateTask(task, resume) = {
          update(store, task);
          resume()
        }
      } with handler DeleteTask {
        def deleteTask(task, resume) =
          resume(delete(store, task))
      }
    }
}
