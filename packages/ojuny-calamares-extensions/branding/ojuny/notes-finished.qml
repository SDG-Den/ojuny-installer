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
            text: qsTr("Remove the installation media before restarting so the machine boots from the installed disk.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("On first boot, log in with the account you created, connect to the network, and open the settings GUI. Review the display layout first, then update, pick a theme and check the keybind cheatsheet.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("Your configuration lives in ~/repos/nix-flake and is a normal git repository. Commit after every successful rebuild so changes stay reviewable and reversible.")
        }
    }
}
