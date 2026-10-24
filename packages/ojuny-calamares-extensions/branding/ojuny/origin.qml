import io.calamares.core

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Page {
    width: parent.width
    height: parent.height

    ColumnLayout {
        width: parent.width
        spacing: Kirigami.Units.largeSpacing

        Text {
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            text: qsTr("If you want the generated configuration to live in your own git repository, enter its URL. Leave it empty to keep the configuration local. This is ignored when a prepared repository is used.")
        }

        Label {
            text: qsTr("Origin URL")
        }

        TextField {
            Layout.fillWidth: true
            placeholderText: "https://github.com/you/ojuny-template"
            onTextChanged: Global.insert("ojuny_origin_url", text)
        }

        Label {
            text: qsTr("Git token")
        }

        TextField {
            Layout.fillWidth: true
            echoMode: TextInput.Password
            placeholderText: qsTr("Optional, HTTPS only")
            onTextChanged: Global.insert("ojuny_origin_token", text)
        }
    }

    Component.onCompleted: {
        Global.insert("ojuny_origin_url", "");
        Global.insert("ojuny_origin_token", "");
    }
}
