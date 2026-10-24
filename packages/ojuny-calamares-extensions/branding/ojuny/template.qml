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
            text: qsTr("Choose how Ojuny should be installed. The bundled template is prepared for this machine. A prepared ojuny-template repository already contains your configuration; only its hardware module is regenerated.")
        }

        ButtonGroup {
            id: modeGroup
        }

        RadioButton {
            id: bundledButton
            text: qsTr("Use the bundled Ojuny template")
            checked: true
            ButtonGroup.group: modeGroup
            onCheckedChanged: if (checked) Global.insert("ojuny_template_mode", "bundled")
        }

        RadioButton {
            id: preparedButton
            text: qsTr("Use a prepared ojuny-template repository")
            ButtonGroup.group: modeGroup
            onCheckedChanged: if (checked) Global.insert("ojuny_template_mode", "prepared")
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 2
            visible: preparedButton.checked

            Label {
                text: qsTr("Repository URL")
            }

            TextField {
                Layout.fillWidth: true
                placeholderText: "https://github.com/you/ojuny-template"
                onTextChanged: Global.insert("ojuny_template_url", text)
            }

            Label {
                text: qsTr("Git token")
            }

            TextField {
                Layout.fillWidth: true
                echoMode: TextInput.Password
                placeholderText: qsTr("Optional, HTTPS only")
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
