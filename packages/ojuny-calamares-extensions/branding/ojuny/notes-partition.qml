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
            text: qsTr("Selecting a disk and continuing wipes everything on it. Back up anything you need before you start.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("The installer creates an EFI system partition mounted at /boot for the bootloader. On BIOS systems the bootloader is written to the disk instead. The default root filesystem is ext4; btrfs, xfs and f2fs are available.")
        }

        Text {
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            text: qsTr("LUKS2 encryption is optional. It encrypts the root partition and costs a passphrase every time the machine boots. Swap is optional; choose none unless you need hibernation or more memory.")
        }
    }
}
