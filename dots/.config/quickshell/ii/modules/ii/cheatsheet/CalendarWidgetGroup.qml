import qs.modules.ii.cheatsheet.calendar
import QtQuick

Rectangle {
    id: root
    color: "transparent"
    clip: true

    CalendarTimeTable {
        anchors.fill: parent
    }
}