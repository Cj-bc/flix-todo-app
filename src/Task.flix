pub mod Task {
  use Functor.map

  pub enum Task({
    id = TaskId,
    title = String,
    description = Option[String],
    status = StatusSelf,
    dependsOn = Option[Nel[TaskId]]
  })

  pub enum TaskId(Int64)

  pub def newTask(title: String, description: Option[String],
              status: StatusSelf, dependsOn: Option[Nel[Task]]): Task =
    Task({title = title, description = description
         , status = status, dependsOn = map(map(taskId), dependsOn)
         , id = TaskId.TaskId(-1i64)})

  // getters
  pub def taskId(task: Task): TaskId = let Task(v) = task; v#id
  pub def title(task: Task): String = let Task(v) = task; v#title
  pub def description(task: Task): Option[String] = let Task(v) = task; v#description
  pub def status(task: Task): StatusSelf = let Task(v) = task; v#status
  pub def dependsOn(task: Task): Option[Nel[TaskId]] = let Task(v) = task; v#dependsOn

  pub def withTitle(task: Task, title: String): Task = let Task(v) = task; Task({ title = title | v})
  pub def withDescription(task: Task, description: Option[String]): Task = let Task(v) = task; Task({ description = description | v})
  pub def withStatus(task: Task, status: StatusSelf): Task = let Task(v) = task; Task({ status = status | v})
  pub def withDependsOn(task: Task, dependsOn: Option[Nel[Task]]): Task = let Task(v) = task; Task({ dependsOn = map(map(taskId), dependsOn) | v})

  pub enum StatusSelf {
    case NotPlanned
    case Later
    // case Scheduled(LocalDateTime)
    case Done
  }

  pub enum StatusPropagated {
    case NotPlanned
    case PartiallyPlanned
    case Scheduled
    case BlockedBy(Nel[Task])
    case PartiallyDone
    case Dome
  }
}
