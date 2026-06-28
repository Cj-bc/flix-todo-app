/// The main entry point.
///
/// The CLI frontend (`Cli.run`) performs the four TaskRepository capability
/// effects plus the `Console` effect. Here at the edge we supply interpreters
/// for all of them: an in-memory store for the repository, and real stdin/stdout
/// for the console.
def main(): Unit \ IO =
    Sys.Console.runWithIO(() ->
        TaskRepository.InMemory.runInMemory(() ->
            Cli.start()))
