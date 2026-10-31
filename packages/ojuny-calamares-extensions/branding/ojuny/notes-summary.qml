import io.calamares.core

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    width: parent.width
    height: parent.height
    color: "#2d353b"

    function repoName(url) {
        if (!url)
            return ""
        var trimmed = String(url).replace(/\/+$/, "")
        var name = trimmed.substring(trimmed.lastIndexOf("/") + 1)
        var colon = name.lastIndexOf(":")
        if (colon >= 0)
            name = name.substring(colon + 1)
        if (name.slice(-4) === ".git")
            name = name.slice(0, -4)
        return name
    }

    function templateMode() {
        return Global.value("ojuny_template_mode") || "bundled"
    }

    function templateLine() {
        if (templateMode() === "prepared") {
            var preparedName = repoName(Global.value("ojuny_template_url"))
            return preparedName || qsTr("prepared repository")
        }
        return qsTr("Bundled Ojuny template")
    }

    function repositoryLine() {
        if (templateMode() === "prepared") {
            var preparedName = repoName(Global.value("ojuny_template_url"))
            return preparedName || qsTr("prepared repository")
        }
        var originName = repoName(Global.value("ojuny_origin_url"))
        return originName || qsTr("No origin, configuration stays local")
    }

    function hostLine() {
        if (templateMode() === "prepared")
            return qsTr("Detected from the prepared repository")
        return Global.value("hostname") || qsTr("not set")
    }

    function bootLine() {
        if (Global.value("firmwareType") === "efi")
            return qsTr("systemd-boot on the EFI system partition")
        return qsTr("GRUB on the selected disk")
    }

    function diskLine() {
        var partitions = Global.value("partitions") || []
        for (var index = 0; index < partitions.length; index++) {
            if (partitions[index].mountPoint === "/" && partitions[index].device)
                return partitions[index].device
        }
        var loader = Global.value("bootLoader")
        if (loader && loader.installPath)
            return loader.installPath
        return qsTr("the disk selected on the partition page")
    }

    function buildSummary() {
        var account = Global.value("username") || Global.value("fullname") || qsTr("not set")
        return qsTr("Review the choices below before installing. This page is read-only; use Back to change anything.") + "\n\n"
            + qsTr("Account: ") + account + "\n"
            + qsTr("Hostname: ") + hostLine() + "\n"
            + qsTr("Bootloader: ") + bootLine() + "\n"
            + qsTr("Disk: ") + diskLine() + "\n"
            + qsTr("Template: ") + templateLine() + "\n"
            + qsTr("Repository: ") + repositoryLine()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 24
        spacing: Kirigami.Units.largeSpacing

        Text {
            id: summaryText
            Layout.fillWidth: true
            color: "#d3c6aa"
            wrapMode: Text.WordWrap
            font.pixelSize: 16
            text: buildSummary()
        }
    }

    Timer {
        interval: 500
        running: true
        repeat: true
        onTriggered: summaryText.text = buildSummary()
    }

    Component.onCompleted: summaryText.text = buildSummary()
}
