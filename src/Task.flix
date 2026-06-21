pub mod Task {
  use Util.Json.FromJson.FromJson

  pub enum Task({
    title = String,
    description = Option[String],
    status = StatusSelf,
    dependsOn = Option[Nel[Task]]
  })

  instance FromJson[Task] {
    pub def fromJson(j: Json): Result[JsonError, Task] = match j {
      case JObject(t) => forA (
        title <- fromJson.getAtKey("title", json)
      )
    }
  }

  pub def newTask(title: String, description: Option[String],
              status: StatusSelf, dependsOn: Option[Nel[Task]]): Task =
    Task({title = title, description = description, status = status, dependsOn = dependsOn})

  // getters
  pub def title(task: Task): String = let Task(v) = task; v#title
  pub def description(task: Task): Option[String] = let Task(v) = task; v#description
  pub def status(task: Task): StatusSelf = let Task(v) = task; v#status
  pub def dependsOn(task: Task): Option[Nel[Task]] = let Task(v) = task; v#dependsOn

  pub def withTitle(task: Task, title: String): Task = let Task(v) = task; Task({ title = title | v})
  pub def withDescription(task: Task, description: Option[String]): Task = let Task(v) = task; Task({ description = description | v})
  pub def withStatus(task: Task, status: StatusSelf): Task = let Task(v) = task; Task({ status = status | v})
  pub def withDependsOn(task: Task, dependsOn: Option[Nel[Task]]): Task = let Task(v) = task; Task({ dependsOn = dependsOn | v})

  pub enum StatusSelf {
    case NotPlanned
    case Later
    case Scheduled(LocalDateTime)
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
