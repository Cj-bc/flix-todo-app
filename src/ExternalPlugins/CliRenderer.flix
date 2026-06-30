/// A `Renderer` that draws the application to the `Sys.Console.Console`
/// capability. This holds the look of the CLI frontend that previously lived in
/// `Cli`: status labels, task line formatting, the task list and the help text.
pub mod ExternalPlugins.CliRenderer {
  use Sys.Console.Console
  use Plugin.Renderer.Renderer
  use Task.{Task, TaskId, StatusSelf}
  use AppState.AppState

  /// A singleton renderer value. Unlike the empty `RemainingTasksMatcher` enum,
  /// this carries one case so `Renderer.render` can be called with a value.
  pub enum CliRenderer { case CliRenderer }

  instance Renderer[CliRenderer] {
    type Aef = { Console }
    pub def render(_: CliRenderer, state: AppState): Unit \ { Console } =
      match state {
        case AppState.Welcome      => Console.println("flix-todo - type 'help' for commands")
        case AppState.Prompt       => Console.print("> ")
        case AppState.Goodbye      => Console.println("bye")
        case AppState.TaskList(ts) => printTasks(ts)
        case AppState.Added(t)     => Console.println("added: ${renderTask(t)}")
        case AppState.Help         => printHelp()
        case AppState.Message(m)   => Console.println(m)
      }
  }

  /// Raw Int64 behind a TaskId, for display.
  def idValue(task: Task): Int64 =
    let TaskId.TaskId(n) = Task.taskId(task);
    n

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
}
