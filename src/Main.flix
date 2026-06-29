use TaskRepository.CreateTask.CreateTask
use TaskRepository.QueryTasks.QueryTasks
use TaskRepository.UpdateTask.UpdateTask
use TaskRepository.DeleteTask.DeleteTask
use TaskRepository.InMemory

/// The main entry point.
///
/// Resolves every effect the CLI frontend performs. The four TaskRepository
/// capabilities are discharged here with an explicit `run ... with handler` over
/// a process-local in-memory store; the handler bodies delegate to the shared
/// store helpers in `TaskRepository.InMemory`. The Console capability is handled
/// at the edge by the standard library's interpreter.
def main(): Unit \ IO =
    Sys.Console.runWithIO(() ->
        region rc {
            let store = InMemory.freshStore(rc);
            run {
                Cli.start()
            } with handler CreateTask {
                def createTask(title, description, dependsOn, resume) =
                    resume(InMemory.create(store, title, description, dependsOn))
            } with handler QueryTasks {
                def queryTasks(filter, resume) =
                    resume(InMemory.queryBy(store, filter))
            } with handler UpdateTask {
                def updateTask(task, resume) = {
                    InMemory.update(store, task);
                    resume()
                }
            } with handler DeleteTask {
                def deleteTask(task, resume) =
                    resume(InMemory.delete(store, task))
            }
        })
