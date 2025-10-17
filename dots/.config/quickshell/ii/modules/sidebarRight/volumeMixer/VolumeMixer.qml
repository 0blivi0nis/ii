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
            Item {
                anchors.fill: listView

                visible: opacity > 0
                opacity: (root.appPwNodes.length === 0) ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Appearance.animation.menuDecel.duration
                        easing.type: Appearance.animation.menuDecel.type
                    }
                }

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    MaterialSymbol {
                        Layout.alignment: Qt.AlignHCenter
                        iconSize: 55
                        color: Appearance.m3colors.m3outline
                        text: "brand_awareness"
                    }
                    StyledText {
                        Layout.alignment: Qt.AlignHCenter
                        font.pixelSize: Appearance.font.pixelSize.normal
                        color: Appearance.m3colors.m3outline
                        horizontalAlignment: Text.AlignHCenter
                        text: Translation.tr("No audio source")
                    }
                }
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

    // Device selector dialog
    Item {
        anchors.fill: parent
        z: 9999

        visible: opacity > 0
        opacity: root.showDeviceSelector ? 1 : 0
        Behavior on opacity {
            NumberAnimation { 
                duration: Appearance.animation.elementMoveFast.duration
                easing.type: Appearance.animation.elementMoveFast.type
                easing.bezierCurve: Appearance.animation.elementMoveFast.bezierCurve
            }
        }

        Rectangle { // Scrim
            id: scrimOverlay
            anchors.fill: parent
            radius: Appearance.rounding.small
            color: Appearance.colors.colScrim
            MouseArea {
                hoverEnabled: true
                anchors.fill: parent
                preventStealing: true
                propagateComposedEvents: false
            }
        }

        Rectangle { // The dialog
            id: dialog
            color: Appearance.colors.colSurfaceContainerHigh
            radius: Appearance.rounding.normal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.margins: 30
            implicitHeight: dialogColumnLayout.implicitHeight
            
            ColumnLayout {
                id: dialogColumnLayout
                anchors.fill: parent
                spacing: 16

                StyledText {
                    id: dialogTitle
                    Layout.topMargin: dialogMargins
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                    Layout.alignment: Qt.AlignLeft
                    color: Appearance.m3colors.m3onSurface
                    font.pixelSize: Appearance.font.pixelSize.larger
                    text: root.deviceSelectorInput ? Translation.tr("Select input device") : Translation.tr("Select output device")
                }

                Rectangle {
                    color: Appearance.m3colors.m3outline
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                }

                StyledFlickable {
                    id: dialogFlickable
                    Layout.fillWidth: true
                    clip: true
                    implicitHeight: Math.min(scrimOverlay.height - dialogMargins * 8 - dialogTitle.height - dialogButtonsRowLayout.height, devicesColumnLayout.implicitHeight)
                    
                    contentHeight: devicesColumnLayout.implicitHeight

                    ColumnLayout {
                        id: devicesColumnLayout
                        anchors.fill: parent
                        Layout.fillWidth: true
                        spacing: 0

                        Repeater {
                            model: ScriptModel {
                                values: Pipewire.nodes.values.filter(node => {
                                    return !node.isStream && node.isSink !== root.deviceSelectorInput && node.audio
                                })
                            }

                            // This could and should be refractored, but all data becomes null when passed wtf
                            delegate: StyledRadioButton {
                                id: radioButton
                                required property var modelData
                                Layout.leftMargin: root.dialogMargins
                                Layout.rightMargin: root.dialogMargins
                                Layout.fillWidth: true

                                description: modelData.description
                                checked: modelData.id === Pipewire.defaultAudioSink?.id

                                Connections {
                                    target: root
                                    function onShowDeviceSelectorChanged() {
                                        if(!root.showDeviceSelector) return;
                                        radioButton.checked = (modelData.id === Pipewire.defaultAudioSink?.id)
                                    }
                                }

                                onCheckedChanged: {
                                    if (checked) {
                                        root.selectedDevice = modelData
                                    }
                                }
                            }
                        }
                        Item {
                            implicitHeight: dialogMargins
                        }
                    }
                }

                Rectangle {
                    color: Appearance.m3colors.m3outline
                    implicitHeight: 1
                    Layout.fillWidth: true
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                }

                RowLayout {
                    id: dialogButtonsRowLayout
                    Layout.bottomMargin: dialogMargins
                    Layout.leftMargin: dialogMargins
                    Layout.rightMargin: dialogMargins
                    Layout.alignment: Qt.AlignRight

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
            }
        }
    }

}