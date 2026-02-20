pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property var activePlayer: {
        var players = Mpris.players.values;
        if (!players || players.length === 0) return null;
        
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing || players[i].isPlaying) {
                return players[i];
            }
        }
        return players[0];
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() {
            // Force re-evaluation of activePlayer
            root.activePlayer = root.findActive();
        }
    }

    function findActive() {
        var players = Mpris.players.values;
        if (!players || players.length === 0) return null;
        for (var i = 0; i < players.length; i++) {
            if (players[i].playbackState === MprisPlaybackState.Playing || players[i].isPlaying) return players[i];
        }
        return players[0];
    }
    
    // Auto-update timer for player selection
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: root.activePlayer = root.findActive()
    }
}