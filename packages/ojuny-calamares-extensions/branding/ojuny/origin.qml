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
            text: qsTr("If you want the generated configuration to live in your own git repository, enter its URL. Leave it empty to keep the configuration local. This is ignored when a prepared repository is used.")
        }

        Label {
            text: qsTr("Origin URL")
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
            onTextChanged: Global.insert("ojuny_origin_url", text)
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
            onTextChanged: Global.insert("ojuny_origin_token", text)
        }
    }

    Component.onCompleted: {
        Global.insert("ojuny_origin_url", "");
        Global.insert("ojuny_origin_token", "");
    }
}
