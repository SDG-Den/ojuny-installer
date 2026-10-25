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
            text: qsTr("Choose how Ojuny should be installed. The bundled template is prepared for this machine. A prepared ojuny-template repository already contains your configuration; only its hardware module is regenerated.")
        }

        ButtonGroup {
            id: modeGroup
        }

        RadioButton {
            id: bundledButton
            text: qsTr("Use the bundled Ojuny template")
            checked: true
            palette.windowText: "#d3c6aa"
            palette.highlight: "#a7c080"
            palette.highlightedText: "#2d353b"
            ButtonGroup.group: modeGroup
            onCheckedChanged: if (checked) Global.insert("ojuny_template_mode", "bundled")
        }

        RadioButton {
            id: preparedButton
            text: qsTr("Use a prepared ojuny-template repository")
            palette.windowText: "#d3c6aa"
            palette.highlight: "#a7c080"
            palette.highlightedText: "#2d353b"
            ButtonGroup.group: modeGroup
            onCheckedChanged: if (checked) Global.insert("ojuny_template_mode", "prepared")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            visible: preparedButton.checked

            Label {
                text: qsTr("Repository URL")
                color: "#d3c6aa"
            }

            TextField {
                Layout.fillWidth: true
                color: "#d3c6aa"
                placeholderTextColor: "#7a8478"
                placeholderText: "https://github.com/you/ojuny-template"
                background: Rectangle {
                    color: "#343f44"
                    border.color: "#475258"
                    radius: 3
                }
                onTextChanged: Global.insert("ojuny_template_url", text)
            }

            Label {
                text: qsTr("Git token")
                color: "#d3c6aa"
            }

            TextField {
                Layout.fillWidth: true
                color: "#d3c6aa"
                placeholderTextColor: "#7a8478"
                echoMode: TextInput.Password
                placeholderText: qsTr("Optional, HTTPS only")
                background: Rectangle {
                    color: "#343f44"
                    border.color: "#475258"
                    radius: 3
                }
                onTextChanged: Global.insert("ojuny_template_token", text)
            }
        }
    }

    Component.onCompleted: {
        Global.insert("ojuny_template_mode", "bundled");
        Global.insert("ojuny_template_url", "");
        Global.insert("ojuny_template_token", "");
    }
}
