/// A small interactive command-line frontend that drives the TaskRepository
/// capability effects directly.
///
/// Two ideas are on display here:
///   * Each use-case function lists in its effect row exactly the repository
///     capabilities it needs (e.g. `listTasks` only `QueryTasks`,
///     `completeTask` both `QueryTasks` and `UpdateTask`). The compiler then
///     guarantees a use case cannot perform an operation it was not granted.
///   * Input/output is itself the `Sys.Console.Console` capability, handled at
///     the edge in `Main` via `Sys.Console.runWithIO`.
mod Cli {
  use Sys.Console.Console
  use Task.Task
  use Task.TaskId
  use Task.StatusSelf
  use TaskRepository.CreateTask
  use TaskRepository.QueryTasks
  use TaskRepository.UpdateTask
  use TaskRepository.DeleteTask
  use TaskRepository.TaskRepositoryError.TaskRepositoryError

  /// Raw Int64 behind a TaskId (TaskId has no Eq/Order instance).
  def idValue(task: Task): Int64 =
    let TaskId.TaskId(n) = Task.taskId(task);
    n

  // ----- Use cases (effect rows declare the required capabilities) -----

  /// Needs only the capability to create a task.
  pub def addTask(title: String): Result[TaskRepositoryError, Task] \ CreateTask =
    CreateTask.createTask(title, None, None)

  /// Needs only the capability to read tasks.
  pub def listTasks(): List[Task] \ QueryTasks =
    QueryTasks.queryAllTasks()

  /// Needs to read a task and then write it back.
  pub def completeTask(id: Int64): Result[String, Unit] \ { QueryTasks, UpdateTask } =
    match QueryTasks.queryTasks(t -> idValue(t) == id) |> List.head {
      case Some(task) => Ok(UpdateTask.updateTask(task |> Task.withStatus(StatusSelf.Done)))
      case None       => Err("no task with id ${id}")
    }

  /// Needs to read a task and then delete it.
  pub def removeTask(id: Int64): Result[String, Unit] \ { QueryTasks, DeleteTask } =
    match QueryTasks.queryTasks(t -> idValue(t) == id) |> List.head {
      case Some(task) => match DeleteTask.deleteTask(task) {
        case None    => Ok(())
        case Some(_) => Err("could not delete task ${id}")
      }
      case None => Err("no task with id ${id}")
    }

  // ----- Rendering -----

  def statusLabel(s: StatusSelf): String = match s {
    case StatusSelf.NotPlanned => "[ ]"
    case StatusSelf.Later      => "[~]"
    case StatusSelf.Done       => "[x]"
  }

  def renderTask(task: Task): String =
    "${statusLabel(Task.status(task))} ${idValue(task)}: ${Task.title(task)}"

  def printTasks(tasks: List[Task]): Unit \ Console =
    if (List.isEmpty(tasks))
      Console.println("  (no tasks)")
    else
      List.forEach(t -> Console.println("  ${renderTask(t)}"), tasks)

  def printHelp(): Unit \ Console = {
    Console.println("commands:");
    Console.println("  add <title>   add a task");
    Console.println("  list          list all tasks");
    Console.println("  done <id>     mark a task as done");
    Console.println("  rm <id>       delete a task");
    Console.println("  help          show this help");
    Console.println("  quit          exit")
  }

  /// Parse an Int64 id from `s`, then run `k`, or report a parse error.
  def withId(s: String, k: Int64 -> Unit \ ef): Unit \ ef + Console =
    match Int64.fromString(String.trim(s)) {
      case Some(id) => k(id)
      case None     => Console.println("not a valid id: '${String.trim(s)}'")
    }

  // ----- Command dispatch -----

  /// Split `s` into its first whitespace-delimited word and the remaining text.
  def splitFirstWord(s: String): (String, String) =
    let t = String.trim(s);
    match String.indexOfLeft({ substr = " " }, t) {
      case None    => (t, "")
      case Some(i) => (String.takeLeft(i, t), String.dropLeft(i, t) |> String.trim)
    }

  def handle(line: String): Unit \ { Console, CreateTask, QueryTasks, UpdateTask, DeleteTask } =
    let (cmd, arg) = splitFirstWord(line);
    if (cmd == "add")
      if (String.isEmpty(arg))
        Console.println("usage: add <title>")
      else
        match addTask(arg) {
          case Ok(task) => Console.println("added: ${renderTask(task)}")
          case Err(_)   => Console.println("could not add task")
        }
    else if (cmd == "list")
      printTasks(listTasks())
    else if (cmd == "done")
      if (String.isEmpty(arg))
        Console.println("usage: done <id>")
      else
        withId(arg, id ->
          match completeTask(id) {
            case Ok(())   => Console.println("done: ${id}")
            case Err(msg) => Console.println(msg)
          })
    else if (cmd == "rm")
      if (String.isEmpty(arg))
        Console.println("usage: rm <id>")
      else
        withId(arg, id ->
          match removeTask(id) {
            case Ok(())   => Console.println("removed: ${id}")
            case Err(msg) => Console.println(msg)
          })
    else if (cmd == "help")
      printHelp()
    else
      Console.println("unknown command: '${cmd}' (type 'help')")

  // ----- REPL -----

  def loop(): Unit \ { Console, CreateTask, QueryTasks, UpdateTask, DeleteTask } = {
    Console.print("> ");
    match Console.readln() {
      case None => Console.println("bye")
      case Some(raw) =>
        let line = String.trim(raw);
        if (line == "quit" or line == "exit")
          Console.println("bye")
        else {
          (if (String.isEmpty(line)) () else handle(line));
          loop()
        }
    }
  }

  /// Entry point of the frontend. Assumes the four TaskRepository effects are
  /// already supplied by an interpreter (see `TaskRepository.InMemory`).
  pub def start(): Unit \ { Console, CreateTask, QueryTasks, UpdateTask, DeleteTask } = {
    Console.println("flix-todo - type 'help' for commands");
    loop()
  }
}
