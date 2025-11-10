import qs.modules.common
import qs.modules.common.widgets
import qs
import Quickshell
import Quickshell.Io

QuickToggleButton {
    id: root
    
    // Start hidden by default - only show if power-profiles-daemon is available
    visible: false
    
    property string currentProfile: "balanced"
    
    // Dynamic icon based on current power profile
    buttonIcon: {
        switch(currentProfile) {
            case "power-saver": return "energy_savings_leaf"
            case "performance": return "local_fire_department"
            case "balanced":
            default: return "settings_slow_motion"
        }
    }
    
    // Visual state - show as "toggled" when in performace mode
    toggled: currentProfile == "performance"
    
    onClicked: {
        let nextProfile = getNextProfile()
        setNextProfile(nextProfile)
    }
    
    function getNextProfile() {
        switch(currentProfile) {
            case "performance":
                return "balanced"
            case "balanced":
                return "power-saver"
            case "power-saver":
                return "performance"
            default:
                // Fallback if something weird happens
                return "balanced"
        }
    }
    
    function setNextProfile(profile) {
        setProfileProcess.command = ["powerprofilesctl", "set", profile]
        setProfileProcess.running = true
    }
    
    function sendNotification(profile) {
        let message = ""
        switch(profile) {
            case "performance":
                message = "Switched to Balanced"
                break
            case "balanced":
                message = "Switched to Power Saver"
                break
            case "power-saver":
                message = "Switched to Performance"
                break
            default:
                message = "Reset to Balanced"
        }
        
        Quickshell.execDetached([
            "notify-send", 
            "Power Profile", 
            message,
            "-a", "QuickShell"
        ])
    }
    
    // Check if power-profiles-daemon is available
    Process {
        id: checkDependency
        running: true
        command: ["bash", "-c", "command -v powerprofilesctl"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // powerprofilesctl exists, now verify daemon communication
                validateDaemon.running = true
            }
            // If command fails, widget stays hidden (visible: false)
        }
    }
    
    // Validate that powerprofilesctl can communicate with daemon
    Process {
        id: validateDaemon
        command: ["powerprofilesctl", "version"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Daemon is available and working - show widget and fetch current profile
                root.visible = true
                fetchCurrentProfile.running = true
            }
            // If validation fails, widget stays hidden
        }
    }
    
    // Check current profile on startup (only runs if dependency check passes)
    Process {
        id: fetchCurrentProfile
        running: false
        command: ["powerprofilesctl", "get"]
        stdout: StdioCollector {
            id: profileCollector
            onStreamFinished: {
                let profile = profileCollector.text.trim()
                if (profile && (profile === "performance" || profile === "balanced" || profile === "power-saver")) {
                    root.currentProfile = profile
                } else {
                    root.currentProfile = "balanced"
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // Command failed, default to balanced
                root.currentProfile = "balanced"
            }
        }
    }
    
    // Set new profile
    Process {
        id: setProfileProcess
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                // Success - refresh current state and notify
                fetchCurrentProfile.running = true
                // Send notification after a brief delay to ensure state is updated
                Qt.callLater(() => sendNotification(root.currentProfile))
            } else {
                // Handle error - reset to balanced and notify
                root.currentProfile = "balanced"
                Quickshell.execDetached([
                    "notify-send", 
                    "Power Profile", 
                    "Failed to change power profile - Reset to Balanced",
                    "-a", "QuickShell"
                ])
            }
        }
    }
    
    StyledToolTip {
        text: `Power Profile: ${root.currentProfile}`
    }
}