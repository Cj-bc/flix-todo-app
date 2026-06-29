pub mod Task {
  use Functor.{map, <$>}
  use Util.Json
  use Util.Json.Json.{JObject, JString, JNumber}
  use Util.Json.JsonError.{JsonError, DecodeErrorKind}
  use Util.Json.FromJson.{FromJson, decodeAtKey, decodeAtKeyOpt}
  use Util.Json.ToJson.{ToJson, toJson}
  use Util.Json.JsonPath.{JsonPath, JsonStep, empty}

  pub enum Task({
    id = TaskId,
    title = String,
    description = Option[String],
    status = StatusSelf,
    dependsOn = Option[Nel[TaskId]]
  })

  pub enum TaskId(Int64) with Eq, Order

  instance FromJson[TaskId] {
    pub def fromJson(j: Json): Result[JsonError, TaskId] =
      match (j) {
        case JNumber(n) => TaskId.TaskId <$> (BigDecimal.tryToInt64(n) |> Option.toOk(JsonError.Decode(empty(), DecodeErrorKind.TypeMismatch(""))))
        case _ => Err(JsonError.Decode(empty(), DecodeErrorKind.TypeMismatch("")))
      }
  }

  instance ToJson[TaskId] {
    pub def toJson(x: TaskId): Json = let TaskId.TaskId(n) = x; toJson(n)
  }

  pub def newTask(id: Int64, title: String, description: Option[String],
              status: StatusSelf, dependsOn: Option[Nel[Task]]): Task =
    Task({title = title, description = description
         , status = status, dependsOn = map(map(taskId), dependsOn)
         , id = TaskId.TaskId(id)})

  // getters
  pub def taskId(task: Task): TaskId = let Task(v) = task; v#id
  pub def title(task: Task): String = let Task(v) = task; v#title
  pub def description(task: Task): Option[String] = let Task(v) = task; v#description
  pub def status(task: Task): StatusSelf = let Task(v) = task; v#status
  pub def dependsOn(task: Task): Option[Nel[TaskId]] = let Task(v) = task; v#dependsOn

  pub def withTitle(title: String, task: Task): Task = let Task(v) = task; Task({ title = title | v})
  pub def withDescription(description: Option[String], task: Task): Task = let Task(v) = task; Task({ description = description | v})
  pub def withStatus(status: StatusSelf, task: Task): Task = let Task(v) = task; Task({ status = status | v})
  pub def withDependsOn(dependsOn: Option[Nel[Task]], task: Task): Task = let Task(v) = task; Task({ dependsOn = map(map(taskId), dependsOn) | v})

  instance FromJson[Task] {
    pub def fromJson(j: Json): Result[JsonError, Task] =
      forM (
        id <- decodeAtKey("id", j);
        title <- decodeAtKey("title", j);
        description <- decodeAtKey("description", j);
        status <- decodeAtKey("status", j);
        dependsOn <- List.toNel <$> decodeAtKey("dependsOn", j)
      ) yield Task({id = TaskId.TaskId(id), title = title, description = description, status = status, dependsOn = dependsOn})
  }

  instance ToJson[Task] {
    pub def toJson(x: Task): Json =
      JObject(Map#{"id" => toJson(taskId(x))
                  , "title" => toJson(title(x))
                  , "description" => toJson(x |> description |> Option.getWithDefault(""))
                  , "status" => toJson(x |> status)
                  , "dependsOn" => toJson(x |> dependsOn |> map(Nel.toList) |> Option.getWithDefault(List#{}))})
  }

  pub enum StatusSelf with Eq, Order, ToString {
    case NotPlanned
    case Later
    // case Scheduled(LocalDateTime)
    case Done
  }

  def guard(f: Unit -> Bool \ ef, path: JsonPath): Result[JsonError, Unit] \ ef =
    if (f()) Ok(()) else Err(JsonError.Decode(path, DecodeErrorKind.TypeMismatch("")))

  def strToStatusSelf(s: String, err: err): Result[err, StatusSelf] =
    match (s) {
      case  "NotPlanned" => Ok(StatusSelf.NotPlanned)
      case  "Later" => Ok(StatusSelf.Later)
      // case  "Scheduled" => 
      case  "Done" => Ok(StatusSelf.Done)
      case _ => Err(err)
    }

  instance FromJson[StatusSelf] {
    pub def fromJson(j: Json): Result[JsonError, StatusSelf] =
      forM (
        vtype <- decodeAtKey("$type", j);
        _ <- guard(() -> vtype == "StatusSelf",
                   JsonPath(List#{JsonStep.Key("$type")}));
        v <- decodeAtKey("value", j);
        status <- strToStatusSelf(v, 
          JsonError.Decode(JsonPath(List#{JsonStep.Key("value")}), DecodeErrorKind.TypeMismatch("")))
      ) yield status
  }

  instance ToJson[StatusSelf] {
    pub def toJson(x: StatusSelf): Json =
      JObject(Map#{"$type" => JString("StatusSelf"), "value" => match (x) {
        case StatusSelf.NotPlanned => JString("NotPlanned")
        case StatusSelf.Later => JString("Later")
        case StatusSelf.Done => JString("Done")
      }})
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
