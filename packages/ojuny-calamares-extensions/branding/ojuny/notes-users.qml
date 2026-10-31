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
            text: qsTr("Create the account you will use on the installed system. The password is stored as a hash in the Nix configuration, not as plain text.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("The hostname becomes the name of the system configuration. Mutable users are disabled, so password changes go through the settings GUI and a rebuild instead of the passwd command.")
        }
    }
}
