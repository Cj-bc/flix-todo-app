/// The renderable view of the application at a single step.
///
/// The CLI is a REPL whose tasks live in the `TaskRepository` effects, so this
/// is not a persistent application state but a sum type describing "what should
/// be drawn right now". A `Renderer` turns one of these into output.
pub mod AppState {
  use Task.Task

  pub enum AppState {
    case Welcome              // startup banner
    case Prompt               // the "> " input prompt (no trailing newline)
    case Goodbye              // "bye"
    case TaskList(List[Task]) // result of `list`
    case Added(Task)          // a freshly added task
    case Help                 // command help
    case Message(String)      // a one-line message (usage / done / removed / errors)
  }
}
