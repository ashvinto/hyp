pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property real cpu: 0
    property real ram: 0
    property string disk: "0%"
    
    property real cpuTemp: 0
    property real gpu: 0
    property real gpuTemp: 0

    function update() {
        resourceProc.running = true
    }

    Process {
        id: resourceProc
        // 1. CPU %, 2. RAM %, 3. Disk %, 4. CPU Temp, 5. GPU %, 6. GPU Temp
        command: ["sh", "-c", "\n            top -bn1 | grep \"Cpu(s)\" | awk '{print $2 + $4}';\n            free | grep Mem | awk '{print $3/$2 * 100.0}';\n            df -h / | tail -1 | awk '{print $5}';\n            \n            # CPU Temp
            cat /sys/class/thermal/thermal_zone*\/temp 2>/dev/null | head -n1 | awk '{print $1/1000}';\n            \n            # GPU Stats (Try nvidia-smi, fallback to 0)
            if command -v nvidia-smi >/dev/null; then
                nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | awk -F', ' '{print $1; print $2}';
            else
                echo \"0\"; echo \"0\";
            fi\n        "]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                var lines = text.trim().split("\n")
                if (lines.length >= 6) {
                    root.cpu = parseFloat(lines[0])
                    root.ram = parseFloat(lines[1])
                    root.disk = lines[2]
                    root.cpuTemp = parseFloat(lines[3])
                    root.gpu = parseFloat(lines[4])
                    root.gpuTemp = parseFloat(lines[5])
                }
            }
        }
    }

    Timer { interval: 10000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()
}