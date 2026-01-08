import qs.modules.common
import qs.modules.common.widgets
import qs.services
import Quickshell
import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects

RowLayout {
    id: root
    spacing: 4

    Timer {
        interval: Config.options.bar.crypto.refreshRate * 60 * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: Crypto.getData()
    }

    // Fallback text if model is empty
    StyledText {
        visible: (Crypto.coinModel.count ?? Crypto.coinModel.length ?? 0) === 0
        text: "No coins"
        color: Appearance.colors.colOnLayer1
        font.pixelSize: Appearance.font.pixelSize.small
        Layout.alignment: Qt.AlignVCenter
    }

    Repeater {
        model: Crypto.coinModel
        delegate: MouseArea {
            Layout.fillHeight: true
            implicitWidth: rowLayout.implicitWidth + 10 * 2
            implicitHeight: Appearance.sizes.barHeight

            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton || mouse.button === Qt.LeftButton) {
                    Crypto.getData();
                    Quickshell.execDetached(["notify-send", 
                        "Crypto", 
                        "Refreshing price..."
                        , "-a", "Shell"
                    ])
                }
            }

            RowLayout {
                id: rowLayout
                anchors.centerIn: parent
                spacing: 5

                // Show fetched image if available
                Item {
                    Layout.alignment: Qt.AlignVCenter
                    width: Appearance.font.pixelSize.large
                    height: Appearance.font.pixelSize.large
                    visible: (imageUrl || "") !== ""

                    Image {
                        id: coinImg
                        anchors.fill: parent
                        source: imageUrl || ""
                        sourceSize.width: Appearance.font.pixelSize.large
                        sourceSize.height: Appearance.font.pixelSize.large
                        visible: !Config.options.bar.crypto.monochromeIcon
                    }
                    
                    Desaturate {
                        anchors.fill: parent
                        source: coinImg
                        desaturation: 1.0
                        visible: Config.options.bar.crypto.monochromeIcon
                    }
                }

                // Fallback to symbol if image is missing
                StyledText {
                    visible: (imageUrl || "") === ""
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.bold: true
                    color: Appearance.colors.colOnLayer1
                    text: symbol || ""
                    Layout.alignment: Qt.AlignVCenter
                }

                StyledText {
                    visible: true
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: Appearance.colors.colOnLayer1
                    text: price || ""
                    Layout.alignment: Qt.AlignVCenter
                }
            }
        }
    }
}