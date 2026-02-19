#!/bin/bash
# Force QtWebEngine to ignore certain checks and use a dedicated profile
export QT_WEBENGINE_DISABLE_SANDBOX=1
export QTWEBENGINE_DISABLE_GPU=1 
export QT_LOGGING_RULES="qt.webenginecontext.debug=true"

# Launch Quickshell normally
quickshell -p "/home/zoro/.config/quickshell/ai/shell.qml"