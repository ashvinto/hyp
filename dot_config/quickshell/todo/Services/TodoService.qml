pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Property to hold the list of todos
    property var todos: []

    // Initialize
    Component.onCompleted: {
        loadTodos()
    }

    // Function to add a new todo
    function addTodo(task) {
        if (task && task.trim() !== "") {
            var newTodo = {
                "task": task,
                "completed": false,
                "timestamp": new Date().toISOString()
            }
            var newTodos = todos.slice()
            newTodos.push(newTodo)
            todos = newTodos
            saveTodos()
        }
    }

    // Function to remove a todo
    function removeTodo(index) {
        if (index >= 0 && index < todos.length) {
            var newTodos = todos.slice()
            newTodos.splice(index, 1)
            todos = newTodos
            saveTodos()
        }
    }

    // Function to toggle a todo's completion status
    function toggleTodo(index) {
        if (index >= 0 && index < todos.length) {
            var newTodos = todos.slice()
            newTodos[index].completed = !newTodos[index].completed
            todos = newTodos
            saveTodos()
        }
    }

    // Function to get the count of completed todos
    readonly property int completedCount: {
        var count = 0
        for (var i = 0; i < todos.length; i++) {
            if (todos[i].completed) count++
        }
        return count
    }

    // Function to get the count of pending todos
    readonly property int pendingCount: {
        var count = 0
        for (var i = 0; i < todos.length; i++) {
            if (!todos[i].completed) count++
        }
        return count
    }

    function clearCompleted() {
        var newTodos = []
        for (var i = 0; i < todos.length; i++) {
            if (!todos[i].completed) {
                newTodos.push(todos[i])
            }
        }
        todos = newTodos
        saveTodos()
    }

    // Process object to load todos
    Process {
        id: loadProc
        command: ["cat", "/home/zoro/.config/quickshell/todo_data.json"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text && text.trim() !== "") {
                    try {
                        root.todos = JSON.parse(text)
                    } catch (e) {
                        console.log("Error parsing todo data:", e)
                        root.todos = []
                    }
                }
            }
        }
    }

    // Load todos
    function loadTodos() {
        loadProc.running = true
    }

    // Save todos to a file
    function saveTodos() {
        var jsonString = JSON.stringify(todos)
        Quickshell.execDetached(["sh", "-c", `mkdir -p ~/.config/quickshell && echo '${jsonString}' > ~/.config/quickshell/todo_data.json`])
    }
}
