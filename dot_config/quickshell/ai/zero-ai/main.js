const { app, BrowserWindow, ipcMain, clipboard } = require('electron')
const path = require('path')
const { spawn } = require('child_process')

let bridgeProcess = null;

function createWindow () {
  const win = new BrowserWindow({
    width: 1300,
    height: 900,
    frame: false,
    transparent: true,
    title: 'zero-ai',
    backgroundColor: '#00000000',
    webPreferences: {
      webviewTag: true,
      nodeIntegration: true,
      contextIsolation: false,
      webSecurity: false
    }
  })

  win.setMenuBarVisibility(false)
  win.loadFile('index.html')
}

// --- IPC HANDLERS ---

ipcMain.on('copy-to-clipboard', (event, text) => {
    clipboard.writeText(text)
})

ipcMain.on('launch-bridge', (event) => {
    if (bridgeProcess) return;

    console.log("[Main] Launching AI Bridge in Foot with venv...");
    
    const bridgePath = path.join(app.getPath('home'), 'OI/local_bridge.py');
    const venvPath = path.join(app.getPath('home'), 'OI/.venv/bin/activate');
    
    // Launching FOOT with venv activation
    bridgeProcess = spawn('foot', [
        '-T', 'AI-Bridge-Terminal',
        'bash', '-c', `source ${venvPath} && python3 -u ${bridgePath} || (echo 'Venv or Script Error!'; read)`
    ]);

    bridgeProcess.on('close', (code) => {
        bridgeProcess = null;
    });
})

ipcMain.on('kill-bridge', (event) => {
    if (bridgeProcess) {
        bridgeProcess.kill();
        bridgeProcess = null;
    }
})

app.on('before-quit', () => { if (bridgeProcess) bridgeProcess.kill(); })
app.commandLine.appendSwitch('enable-gpu-rasterization')
app.whenReady().then(createWindow)
app.on('window-all-closed', () => { if (process.platform !== 'darwin') app.quit() })
