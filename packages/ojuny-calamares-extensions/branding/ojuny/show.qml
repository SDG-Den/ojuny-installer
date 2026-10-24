import QtQuick 2.15

Item {
    id: root

    width: parent.width
    height: parent.height

    property var slides: [
        "Your entire system is declared in one flake, so it can be rebuilt, reviewed, and reproduced.",
        "Your configuration is installed at ~/repos/nix-flake and is a normal git repository.",
        "Every generation is listed in the boot menu, so you can roll back after a bad update.",
        "The settings GUI edits the same Nix files the system is built from.",
        "The flake lock pins every input, so builds are reproducible."
    ]
    property int slideIndex: 0

    Rectangle {
        anchors.fill: parent
        color: "#2d353b"
    }

    Column {
        width: parent.width * 0.72
        anchors.centerIn: parent
        spacing: 30

        Image {
            source: "ojuny-logo.png"
            width: 120
            height: 120
            fillMode: Image.PreserveAspectFit
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            width: parent.width
            text: root.slides[root.slideIndex]
            color: "#d3c6aa"
            font.family: "CaskaydiaCove Nerd Font Mono"
            font.pixelSize: 20
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
        }
    }

    Timer {
        interval: 6000
        running: true
        repeat: true
        onTriggered: root.slideIndex = (root.slideIndex + 1) % root.slides.length
    }
}
