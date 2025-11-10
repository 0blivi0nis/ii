import qs.modules.common.widgets
import qs
import Quickshell.Io
import Quickshell

QuickToggleButton {
    id: root
    
    property string currentProfile: ""

    // Start hidden by default - only show if power-profiles-daemon is available
    visible: false
    
    
    // Dynamic icon based on current power profile
    buttonIcon: {
        switch(currentProfile) {
            case "integrated": return "energy_savings_leaf"
            case "nvidia": return "speed"
            case "hybrid": return "join_inner"
            default: return "directory_sync"
        }
    }
    
    // Visual state - show as "toggled" when not in integrated mode
    toggled: currentProfile !== "integrated"
    
    onClicked: {
        let nextProfile = getNextProfile()
        setNextProfile(nextProfile)
    }
    
    function getNextProfile() {
        switch(currentProfile) {
            case "nvidia":
                return "hybrid"
            case "hybrid":
                return "integrated"
            case "integrated":
                return "nvidia"
            default:
                // Fallback if something weird happens
                return "unknown"
        }
    }
    
    function setNextProfile(profile) {
        Quickshell.execDetached(["qt-sudo", "envycontrol", "-s", profile, "--dm", "sddm"]);
        GlobalStates.sidebarRightOpen = false;
    }
    
    function sendNotification(profile) {
        let message = ""
        switch(profile) {
            case "nvidia":
                message = "Switched to Hybrid, Please Reboot"
                break
            case "hybrid":
                message = "Switched to Integrated, Please Reboot"
                break
            case "integrated":
                message = "Switched to Nvidia, Please Reboot"
                break
            default:
                message = "Error, Reset to Hybrid, Please Reboot"
        }
        
        Quickshell.execDetached([
            "notify-send", 
            "GPU Profile", 
            message,
            "-a", "QuickShell"
        ])
    }

    // Check if power-profiles-daemon is available
    Process {
        id: checkDependency
        running: true
        command: ["bash", "-c", "command -v envycontrol"]
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
        command: ["envycontrol", "-v"]
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
        command: ["envycontrol", "-q"]
        stdout: StdioCollector {
            id: profileCollector
            onStreamFinished: {
                let profile = profileCollector.text.trim()
                if (profile && (profile === "nvidia" || profile === "hybrid" || profile === "integrated")) {
                    root.currentProfile = profile
                } else {
                    root.currentProfile = "integrated"
                }
            }
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                // Command failed, default to integrated
                root.currentProfile = "integrated"
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
                // Handle error - reset to integrated and notify
                root.currentProfile = "integrated"
                Quickshell.execDetached([
                    "notify-send", 
                    "GPU Profile", 
                    "Failed to change gpu profile - Reset to Hybrid, Please Reboot",
                    "-a", "QuickShell"
                ])
            }
        }
    }
    
    StyledToolTip {
        text: `GPU Profile: ${root.currentProfile}`
    }
}