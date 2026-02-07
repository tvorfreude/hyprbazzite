import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#000000"

    property color accentColor: "#7aa2f7"
    property color textColor: "#cbd5e1"
    property color faintTextColor: "#94a3b8"

    Text {
        id: minutes
        text: Qt.formatDateTime(new Date(), "mm")
        color: accentColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 180
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -80
    }

    Text {
        id: hours
        text: Qt.formatDateTime(new Date(), "HH")
        color: textColor
        font.family: "JetBrainsMono Nerd Font"
        font.pixelSize: 180
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 140
    }

    Text {
        id: layout
        text: keyboard.layout
        color: accentColor
        font.family: "Victor Mono"
        font.pixelSize: 16
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 40
    }

    Text {
        id: uptime
        text: "Uptime: " + sddm.uptime
        color: accentColor
        font.family: "Victor Mono"
        font.pixelSize: 18
        anchors.right: parent.right
        anchors.rightMargin: 40
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 40
    }

    Rectangle {
        id: inputBox
        width: 360
        height: 60
        radius: 6
        color: "#0b0f14"
        border.color: accentColor
        border.width: 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 120

        TextField {
            id: passwordField
            anchors.fill: parent
            anchors.margins: 12
            echoMode: TextInput.Password
            placeholderText: "Type Password"
            color: textColor
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 18
            background: Rectangle { color: "transparent" }
            focus: true
            onAccepted: sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            minutes.text = Qt.formatDateTime(new Date(), "mm")
            hours.text = Qt.formatDateTime(new Date(), "HH")
        }
    }
}
