pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var todos: []

    // Use FileView for reliable file reading
    FileView {
        id: todoFile
        path: "/home/zoro/.config/quickshell/todo_data.json"
        onLoaded: root.loadTodos()
        onTextChanged: root.loadTodos()
    }

    function loadTodos() {
        var raw = todoFile.text()
        if (raw && raw.trim() !== "") {
            try {
                root.todos = JSON.parse(raw)
                console.log("[TodoService] Loaded " + root.todos.length + " tasks via FileView")
            } catch (e) {
                console.error("[TodoService] JSON Parse error:", e)
            }
        }
    }

    Component.onCompleted: loadTodos()

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

    function removeTodo(index) {
        if (index >= 0 && index < todos.length) {
            var newTodos = todos.slice()
            newTodos.splice(index, 1)
            todos = newTodos
            saveTodos()
        }
    }

    function toggleTodo(index) {
        if (index >= 0 && index < todos.length) {
            var newTodos = todos.slice()
            newTodos[index].completed = !newTodos[index].completed
            todos = newTodos
            saveTodos()
        }
    }

    readonly property int completedCount: {
        var count = 0
        for (var i = 0; i < todos.length; i++) {
            if (todos[i].completed) count++
        }
        return count
    }

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

    function saveTodos() {
        var jsonString = JSON.stringify(todos)
        var cmd = "mkdir -p ~/.config/quickshell && echo '" + jsonString + "' > ~/.config/quickshell/todo_data.json"
        Quickshell.execDetached(["sh", "-c", cmd])
    }
}
