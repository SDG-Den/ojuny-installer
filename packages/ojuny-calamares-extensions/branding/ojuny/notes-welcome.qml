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
            text: qsTr("This installer can be closed at any time. Close this window to try the Ojuny desktop, then reopen the installer from the \"Install Ojuny\" entry in the application menu. Nothing is written to disk until you start the installation.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("The installer keeps your choices while it stays open. Closing it does not change the live session and does not partition anything.")
        }
    }
}
