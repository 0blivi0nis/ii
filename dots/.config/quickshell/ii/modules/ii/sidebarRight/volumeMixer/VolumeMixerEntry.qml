import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire

Item {
    id: root
    required property PwNode node
    PwObjectTracker {
        objects: [node]
    }

    implicitHeight: rowLayout.implicitHeight

    RowLayout {
        id: rowLayout
        anchors.fill: parent
        spacing: 6

        Image {
            property real size: 36
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            visible: source != ""
            sourceSize.width: size
            sourceSize.height: size
            source: {
                let icon;
                icon = AppSearch.guessIcon(root.node?.properties["application.icon-name"] ?? "");
                if (AppSearch.iconExists(icon))
                    return Quickshell.iconPath(icon, "image-missing");
                icon = AppSearch.guessIcon(root.node?.properties["node.name"] ?? "");
                return Quickshell.iconPath(icon, "image-missing");
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: -4

            StyledText {
                Layout.fillWidth: true
                font.pixelSize: Appearance.font.pixelSize.small
                color: Appearance.colors.colSubtext
                elide: Text.ElideRight
                text: {
                    // application.name -> description -> name
                    const app = root.node?.properties["application.name"] ?? (root.node.description != "" ? root.node.description : root.node.name);
                    const media = root.node.properties["media.name"];
                    return media != undefined ? `${app} • ${media}` : app;
                }
            }

            RowLayout {
                StyledSlider {
                    id: slider
                    value: root.node?.audio.volume ?? 0
                    onMoved: root.node.audio.volume = value
                    configuration: StyledSlider.Configuration.S
                }

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: (root.node.audio?.muted ?? false) ? 
                           Appearance.m3colors.m3error : 
                           Qt.rgba(Appearance.colors.colOnLayer1.r, Appearance.colors.colOnLayer1.g, Appearance.colors.colOnLayer1.b, 0.1)
                    border.color: Qt.rgba(1, 1, 1, 0.15)
                    border.width: 0
                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: (root.node.audio?.muted ?? false) ? "volume_off" : "volume_up"
                        iconSize: Appearance.font.pixelSize.small
                        color: (root.node.audio?.muted ?? false) ? 
                               Appearance.m3colors.m3errorContainer : 
                               Appearance.colors.colOnLayer1
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (root.node.audio) {
                                root.node.audio.muted = !root.node.audio.muted;
                            }
                        }
                    }
                }
            }
        }
    }
}
