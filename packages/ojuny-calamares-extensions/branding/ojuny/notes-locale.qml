import io.calamares.core

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    width: parent.width
    height: parent.height
    color: "#2d353b"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: Kirigami.Units.largeSpacing

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            text: qsTr("Choose the language and regional formats for the installed system. This sets the default locale for the system and the desktop.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("The time zone and number, date and currency formats come from this page. Individual applications can still use their own language setting, and you can change the default later in the settings GUI.")
        }
    }
}
