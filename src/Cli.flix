/// A small interactive command-line frontend that drives the TaskRepository
/// capability effects directly.
///
/// Two ideas are on display here:
///   * Each use-case function lists in its effect row exactly the repository
///     capabilities it needs (e.g. `listTasks` only `QueryTasks`,
///     `completeTask` both `QueryTasks` and `UpdateTask`). The compiler then
///     guarantees a use case cannot perform an operation it was not granted.
///   * All output is produced through a `Renderer`: the frontend builds an
///     `AppState` describing what to show and hands it to `Renderer.render`,
///     so it is generic over any renderer rather than tied to one. The console
///     renderer is supplied at the edge in `Main`.
mod Cli {
  use Sys.Console.Console
  use Plugin.Renderer.Renderer
  use AppState.AppState
  use Task.Task
  use Task.TaskId
  use Task.StatusSelf
  use TaskRepository.CreateTask
  use TaskRepository.QueryTasks
  use TaskRepository.UpdateTask
  use TaskRepository.DeleteTask
  use TaskRepository.TaskRepositoryError.TaskRepositoryError

  /// Look up a single task by its raw Int64 id, using `Eq[TaskId]`.
  def findById(id: Int64): Option[Task] \ QueryTasks =
    QueryTasks.queryTasks(t -> Task.taskId(t) == TaskId.TaskId(id)) |> List.head

  // ----- Use cases (effect rows declare the required capabilities) -----

  /// Needs only the capability to create a task.
  pub def addTask(title: String): Result[TaskRepositoryError, Task] \ CreateTask =
    CreateTask.createTask(title, None, None)

  /// Needs only the capability to read tasks.
  pub def listTasks(): List[Task] \ QueryTasks =
    QueryTasks.queryAllTasks()

  /// Needs to read a task and then write it back.
  pub def completeTask(id: Int64): Result[String, Unit] \ { QueryTasks, UpdateTask } =
    match findById(id) {
      case Some(task) => Ok(UpdateTask.updateTask(task |> Task.withStatus(StatusSelf.Done)))
      case None       => Err("no task with id ${id}")
    }

  /// Needs to read a task and then delete it.
  pub def removeTask(id: Int64): Result[String, Unit] \ { QueryTasks, DeleteTask } =
    match findById(id) {
      case Some(task) => match DeleteTask.deleteTask(task) {
        case None    => Ok(())
        case Some(_) => Err("could not delete task ${id}")
      }
      case None => Err("no task with id ${id}")
    }

  // ----- Rendering -----

  /// Draw one application state through the supplied renderer.
  def show(renderer: r, state: AppState): Unit \ Renderer.Aef[r] with Renderer[r] =
    Renderer.render(renderer, state)

  /// Parse an Int64 id from `s`, then run `k`, or report a parse error.
  def withId(renderer: r, s: String, k: Int64 -> Unit \ ef): Unit \ ef + Renderer.Aef[r] with Renderer[r] =
    match Int64.fromString(String.trim(s)) {
      case Some(id) => k(id)
      case None     => show(renderer, AppState.Message("not a valid id: '${String.trim(s)}'"))
    }

  // ----- Command dispatch -----

  /// Split `s` into its first whitespace-delimited word and the remaining text.
  def splitFirstWord(s: String): (String, String) =
    let t = String.trim(s);
    match String.indexOfLeft({ substr = " " }, t) {
      case None    => (t, "")
      case Some(i) => (String.takeLeft(i, t), String.dropLeft(i, t) |> String.trim)
    }

  def handle(renderer: r, line: String): Unit \ { CreateTask, QueryTasks, UpdateTask, DeleteTask } + Renderer.Aef[r] with Renderer[r] =
    let (cmd, arg) = splitFirstWord(line);
    if (cmd == "add")
      if (String.isEmpty(arg))
        show(renderer, AppState.Message("usage: add <title>"))
      else
        match addTask(arg) {
          case Ok(task) => show(renderer, AppState.Added(task))
          case Err(_)   => show(renderer, AppState.Message("could not add task"))
        }
    else if (cmd == "list")
      show(renderer, AppState.TaskList(listTasks()))
    else if (cmd == "done")
      if (String.isEmpty(arg))
        show(renderer, AppState.Message("usage: done <id>"))
      else
        withId(renderer, arg, id ->
          match completeTask(id) {
            case Ok(())   => show(renderer, AppState.Message("done: ${id}"))
            case Err(msg) => show(renderer, AppState.Message(msg))
          })
    else if (cmd == "rm")
      if (String.isEmpty(arg))
        show(renderer, AppState.Message("usage: rm <id>"))
      else
        withId(renderer, arg, id ->
          match removeTask(id) {
            case Ok(())   => show(renderer, AppState.Message("removed: ${id}"))
            case Err(msg) => show(renderer, AppState.Message(msg))
          })
    else if (cmd == "help")
      show(renderer, AppState.Help)
    else
      show(renderer, AppState.Message("unknown command: '${cmd}' (type 'help')"))

  // ----- REPL -----

  def loop(renderer: r): Unit \ { Console, CreateTask, QueryTasks, UpdateTask, DeleteTask } + Renderer.Aef[r] with Renderer[r] = {
    show(renderer, AppState.Prompt);
    match Console.readln() {
      case None => show(renderer, AppState.Goodbye)
      case Some(raw) =>
        let line = String.trim(raw);
        if (line == "quit" or line == "exit")
          show(renderer, AppState.Goodbye)
        else {
          (if (String.isEmpty(line)) () else handle(renderer, line));
          loop(renderer)
        }
    }
  }

  /// Entry point of the frontend. Assumes the four TaskRepository effects are
  /// already supplied by an interpreter (see `TaskRepository.InMemory`) and is
  /// given a `Renderer` to drive all output.
  pub def start(renderer: r): Unit \ { Console, CreateTask, QueryTasks, UpdateTask, DeleteTask } + Renderer.Aef[r] with Renderer[r] = {
    show(renderer, AppState.Welcome);
    loop(renderer)
  }
}
