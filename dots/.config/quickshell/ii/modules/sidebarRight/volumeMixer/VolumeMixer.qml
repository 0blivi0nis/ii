import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Qt5Compat.GraphicalEffects
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire


Item {
    id: root
    property bool showDeviceSelector: false
    property bool deviceSelectorInput
    property int dialogMargins: 16
    property PwNode selectedDevice
    readonly property list<PwNode> appPwNodes: Pipewire.nodes.values.filter((node) => {
        // return node.type == "21" // Alternative, not as clean
        return node.isSink && node.isStream
    })

    function showDeviceSelectorDialog(input: bool) {
        root.selectedDevice = null
        root.showDeviceSelector = true
        root.deviceSelectorInput = input
    }

    Keys.onPressed: (event) => {
        // Close dialog on pressing Esc if open
        if (event.key === Qt.Key_Escape && root.showDeviceSelector) {
            root.showDeviceSelector = false
            event.accepted = true;
        }
    }

    ColumnLayout {
        anchors.fill: parent
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            StyledListView {
                id: listView
                model: root.appPwNodes
                clip: true
                anchors {
                    fill: parent
                    topMargin: 10
                    bottomMargin: 10
                }
                spacing: 6

                delegate: VolumeMixerEntry {
                    // Layout.fillWidth: true
                    anchors {
                        left: parent.left
                        right: parent.right
                        leftMargin: 10
                        rightMargin: 10
                    }
                    required property var modelData
                    node: modelData
                }
            }

            // Placeholder when list is empty
            PagePlaceholder {
                shown: root.appPwNodes.length === 0
                icon: "notifications_active"
                description: Translation.tr("No Audio Source")
                shape: MaterialShape.Shape.Gem
                descriptionHorizontalAlignment: Text.AlignHCenter
            }
        }
        // output / input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 100
            radius: Appearance.rounding.large
            color: Qt.rgba(
                Appearance.colors.colLayer1.r,
                Appearance.colors.colLayer1.g,
                Appearance.colors.colLayer1.b,
                0.3
            )
            RowLayout {
                id: deviceSelectorRowLayout
                uniformCellSizes: true
                anchors.fill: parent
                ColumnLayout {
                    // Output
                    AudioDeviceSelectorButton {
                        Layout.fillWidth: true
                        input: false
                        downAction: () => root.showDeviceSelectorDialog(input)
                    }
                    // Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        StyledSlider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1.0
                            value: Pipewire.defaultAudioSink?.audio.volume ?? 0
                            enabled: !(Pipewire.defaultAudioSink?.audio.muted ?? false)
                            opacity: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? 0.5 : 1.0
                            onValueChanged: {
                                if (Pipewire.defaultAudioSink?.audio) {
                                    Pipewire.defaultAudioSink.audio.volume = value
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? 
                                   Appearance.m3colors.m3error : 
                                   Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1)
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                            border.width: 0
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? "volume_off" : "volume_up"
                                iconSize: Appearance.font.pixelSize.small
                                color: (Pipewire.defaultAudioSink?.audio.muted ?? false) ? 
                                       Appearance.m3colors.m3errorContainer : 
                                       Appearance.colors.colOnLayer1
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (Pipewire.defaultAudioSink?.audio) {
                                        Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    // Input
                    AudioDeviceSelectorButton {
                        Layout.fillWidth: true
                        input: true
                        downAction: () => root.showDeviceSelectorDialog(input)
                    }
                    // Slider
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        StyledSlider {
                            Layout.fillWidth: true
                            from: 0
                            to: 1.0
                            value: Pipewire.defaultAudioSource?.audio?.volume ?? 0
                            enabled: !(Pipewire.defaultAudioSource?.audio?.muted ?? false)
                            opacity: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? 0.5 : 1.0
                            onValueChanged: {
                                if (Pipewire.defaultAudioSource?.audio) {
                                    Pipewire.defaultAudioSource.audio.volume = value
                                }
                            }
                        }
                        Rectangle {
                            Layout.preferredWidth: 32
                            Layout.preferredHeight: 32
                            radius: 16
                            color: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? 
                                   Appearance.m3colors.m3error : 
                                   Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1)
                            border.color: Qt.rgba(1, 1, 1, 0.15)
                            border.width: 0
                            MaterialSymbol {
                                anchors.centerIn: parent
                                text: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? "mic_off" : "mic"
                                iconSize: Appearance.font.pixelSize.small
                                color: (Pipewire.defaultAudioSource?.audio?.muted ?? false) ? 
                                       Appearance.m3colors.m3errorContainer : 
                                       Appearance.colors.colOnLayer1
                            }
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    if (Pipewire.defaultAudioSource?.audio) {
                                        Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    WindowDialog {
        anchors.fill: parent
        show: root.showDeviceSelector
        visible: show
        onDismiss: root.showDeviceSelector = false
        backgroundHeight: 250

        WindowDialogTitle {
            text: root.deviceSelectorInput ? Translation.tr("Select input device") : Translation.tr("Select output device")
        }

        WindowDialogSeparator {
            Layout.leftMargin: 0
            Layout.rightMargin: 0
        }


        DialogSectionListView {
            Layout.fillHeight: true
            
            model: ScriptModel {
                values: Pipewire.nodes.values.filter(node => {
                    return !node.isStream && node.isSink !== root.deviceSelectorInput && node.audio
                })
            }
            delegate: StyledRadioButton {
                id: radioButton
                Layout.fillWidth: true
                required property var modelData

                anchors {
                    left: parent?.left
                    right: parent?.right
                }

                description: modelData.description
                checked: modelData.id === (root.deviceSelectorInput ? Pipewire.defaultAudioSource?.id : Pipewire.defaultAudioSink?.id)
                
                Connections {
                    target: root
                    function onShowDeviceSelectorChanged() {
                        if(!root.showDeviceSelector) return;
                        radioButton.checked = (modelData.id === (root.deviceSelectorInput ? Pipewire.defaultAudioSource?.id : Pipewire.defaultAudioSink?.id))
                    }
                }
                onCheckedChanged: {
                    if (checked) {
                        root.selectedDevice = modelData
                    }
                }
            }
        }
            

        WindowDialogSeparator {
            Layout.leftMargin: 0
            Layout.rightMargin: 0
        }

        WindowDialogButtonRow {
            DialogButton {
                buttonText: Translation.tr("Details")
                onClicked: {
                    Quickshell.execDetached(["bash", "-c", `${Config.options.apps.volumeMixer}`]);
                    GlobalStates.sidebarRightOpen = false;
                }
            }

            Item {
                Layout.fillWidth: true
            }
            
            DialogButton {
                buttonText: Translation.tr("Cancel")
                onClicked: {
                    root.showDeviceSelector = false
                }
            }
            DialogButton {
                buttonText: Translation.tr("OK")
                onClicked: {
                    root.showDeviceSelector = false
                    if (root.selectedDevice) {
                        if (root.deviceSelectorInput) {
                            Pipewire.preferredDefaultAudioSource = root.selectedDevice
                        } else {
                            Pipewire.preferredDefaultAudioSink = root.selectedDevice
                        }
                    }
                }
            }
        }


        component DialogSectionListView: StyledListView {
            Layout.fillWidth: true
            Layout.topMargin: -22
            Layout.bottomMargin: -16
            Layout.leftMargin: -Appearance.rounding.large
            Layout.rightMargin: -Appearance.rounding.large
            topMargin: 12
            bottomMargin: 12
            leftMargin: 20
            rightMargin: 20

            clip: true
            spacing: 4
            animateAppearance: false
        }
    }

}
