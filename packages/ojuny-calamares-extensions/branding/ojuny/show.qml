import QtQuick 2.15
import QtQuick.Layouts 1.3

Item {
    width: parent.width
    height: parent.height

    Rectangle {
        anchors.fill: parent
        color: "#1b1b1f"
    }

    Column {
        anchors.centerIn: parent
        spacing: 24

        Image {
            source: "logo.svg"
            width: 160
            height: 160
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: qsTr("Installing Ojuny")
            color: "#ffffff"
            font.pixelSize: 26
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
