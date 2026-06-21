use Task.Task
use Task.StatusSelf

// The main entry point.
def main(): Unit \ IO =
    let t = Task({title =  "a", description = None, status = StatusSelf.NotPlanned, dependsOn = None});
    println(Task.title(t))
