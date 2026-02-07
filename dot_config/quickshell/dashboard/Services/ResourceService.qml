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

    property string netUp: "0 B/s"
    property string netDown: "0 B/s"
    
    // Internal state for calc
    property var lastRx: 0
    property var lastTx: 0
    property var lastTime: 0

    function formatBytes(bytes) {
        if (bytes === 0) return "0 B/s";
        var k = 1024;
        var sizes = ['B/s', 'KB/s', 'MB/s', 'GB/s'];
        var i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(1)) + ' ' + sizes[i];
    }

    function update() {
        resourceProc.running = true
    }

    Process {
        id: resourceProc
        // 1. CPU %, 2. RAM %, 3. Disk %, 4. CPU Temp, 5. GPU %, 6. GPU Temp, 7. RX Bytes, 8. TX Bytes
        command: ["sh", "-c", "\n            top -bn1 | grep \"Cpu(s)\" | awk '{print $2 + $4}';\n            free | grep Mem | awk '{print $3/$2 * 100.0}';\n            df -h / | tail -1 | awk '{print $5}';\n            \n            # CPU Temp
            cat /sys/class/thermal/thermal_zone*\/temp 2>/dev/null | head -n1 | awk '{print $1/1000}';\n            \n            # GPU Stats
            if command -v nvidia-smi >/dev/null; then
                nvidia-smi --query-gpu=utilization.gpu,temperature.gpu --format=csv,noheader,nounits | awk -F', ' '{print $1; print $2}';
            else
                echo \"0\"; echo \"0\";
            fi\n
            # Network Bytes (Sum of all interfaces)
            awk '{if(NR>2) {rx+=$2; tx+=$10}} END {print rx; print tx}' /proc/net/dev
        "]
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text) return
                var lines = text.trim().split("\n")
                if (lines.length >= 8) {
                    root.cpu = parseFloat(lines[0])
                    root.ram = parseFloat(lines[1])
                    root.disk = lines[2]
                    root.cpuTemp = parseFloat(lines[3])
                    root.gpu = parseFloat(lines[4])
                    root.gpuTemp = parseFloat(lines[5])
                    
                    var currentRx = parseInt(lines[6])
                    var currentTx = parseInt(lines[7])
                    var currentTime = new Date().getTime()
                    
                    if (root.lastTime > 0) {
                        var dt = (currentTime - root.lastTime) / 1000.0
                        var rxSpeed = (currentRx - root.lastRx) / dt
                        var txSpeed = (currentTx - root.lastTx) / dt
                        
                        root.netDown = root.formatBytes(rxSpeed)
                        root.netUp = root.formatBytes(txSpeed)
                    }
                    
                    root.lastRx = currentRx
                    root.lastTx = currentTx
                    root.lastTime = currentTime
                }
            }
        }
    }

    Timer { interval: 2000; running: true; repeat: true; onTriggered: update() }
    Component.onCompleted: update()
}