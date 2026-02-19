const { ipcRenderer } = require('electron');

let isBridgeOnline = false;

const UI = {
    blocks: 'pre, .code-block, [class*="code-block"], .code-container, .ql-syntax',
    inputs: [
        '#prompt-textarea',
        'div[contenteditable="true"]',
        '.ProseMirror',
        'textarea',
        '[role="textbox"]'
    ]
};

function injectButtons() {
    if (!isBridgeOnline) return;
    
    const blocks = document.querySelectorAll(UI.blocks);
    blocks.forEach(block => {
        if (block.getAttribute('data-has-runner') || block.innerText.length < 3) return;
        block.setAttribute('data-has-runner', 'true');

        // Create Button
        const btn = document.createElement('button');
        btn.className = 'run-sys-btn';
        btn.innerHTML = "<span>▶</span> Run System";
        btn.style.cssText = "position: absolute; top: -35px; right: 0; z-index: 99999; background: #89dceb; color: #111; border: none; padding: 5px 12px; border-radius: 6px; cursor: pointer; font-weight: 800; font-size: 11px; box-shadow: 0 4px 8px rgba(0,0,0,0.4);";
        
        btn.onclick = (e) => {
            e.preventDefault(); e.stopPropagation();
            btn.innerText = "Sending...";
            
            // Capture code ONLY from the block (ignoring our button which is now a sibling or handled)
            const code = block.innerText.trim();
            ipcRenderer.sendToHost('run-code', code);
        };

        // Ensure container is relative so button stays attached to it
        if (getComputedStyle(block).position === 'static') block.style.position = 'relative';
        
        // Append button
        block.appendChild(btn);
    });
}

// --- IPC SIGNALS ---

ipcRenderer.on('bridge-status', (event, online) => {
    isBridgeOnline = online;
    injectButtons();
});

ipcRenderer.on('code-result', (event, status) => {
    document.querySelectorAll('.run-sys-btn').forEach(b => {
        if (b.innerText === "Sending...") {
            b.innerText = "Done ✓"; b.style.background = "#a6e3a1";
            setTimeout(() => { b.innerHTML = "<span>▶</span> Run System"; b.style.background = "#89dceb"; }, 3000);
        }
    });
});

setInterval(injectButtons, 2000);
const obs = new MutationObserver(injectButtons);
obs.observe(document.body, { childList: true, subtree: true });
