pub mod JsonTaskRepository {
  use Fs.ReadFile.ReadFile
  use Util.Json

  pub enum JsonTaskRepository({filePath: String, tasks: List[Task]})

  pub fromFile(filePath: String): JsonTaskRepository \ ReadFile =
    let json = ReadFile.readFile(filePath);
    match (Json.decode) {
      case 
    }
    
}