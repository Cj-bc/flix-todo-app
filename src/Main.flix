/// The main entry point.
///
/// Resolves every effect the CLI frontend performs by chaining handler
/// functions after `run ... with`: the in-memory interpreter for the four
/// TaskRepository capabilities, and the standard library's interpreter for the
/// Console capability.
def main(): Unit \ IO =
    run {
        Cli.start()
    } with TaskRepository.InMemory.runInMemory
      with Sys.Console.runWithIO
