import QtQuick
import QtQuick.Controls
import SddmComponents

Rectangle {
    id: root
    color: "#282a36"
    width: 1920
    height: 1080

    Column {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        Item {
            width: parent.width
            height: parent.height - 200

            Column {
                anchors.centerIn: parent
                spacing: 30

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Dracula"
                    color: "#bd93f9"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 48
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    color: "#8be9fd"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 120
                }
            }
        }

        Item {
            width: parent.width
            height: 200

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                width: 400
                spacing: 15

                Rectangle {
                    width: parent.width
                    height: 50
                    color: "#44475a"
                    border.color: "#bd93f9"
                    border.width: 2
                    radius: 4

                    TextInput {
                        width: parent.width
                        height: parent.height
                        leftPadding: 15
                        rightPadding: 15
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        color: "#8be9fd"
                        echoMode: TextInput.Password
                        focus: true
                        verticalAlignment: TextInput.AlignVCenter
                        onAccepted: sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
                    }
                }

                Text {
                    text: "Password"
                    color: "#6272a4"
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.children[0].verticalCenter
                    anchors.left: parent.children[0].left
                    anchors.leftMargin: 15
                    visible: parent.children[0].text.length === 0
                }

                Row {
                    width: parent.width
                    spacing: 10
                    height: 40

                    ComboBox {
                        id: sessions
                        width: parent.width / 2 - 5
                        height: parent.height
                        model: sessionModel
                        currentIndex: sessionModel.lastIndex
                    }

                    ComboBox {
                        id: users
                        width: parent.width / 2 - 5
                        height: parent.height
                        model: userModel
                        currentIndex: userModel.lastIndex
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 45
                    color: "#bd93f9"
                    radius: 4

                    Text {
                        anchors.centerIn: parent
                        text: "Login"
                        color: "#282a36"
                        font.family: "JetBrainsMono Nerd Font"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sddm.login(users.currentIndex >= 0 ? userModel.data(userModel.index(users.currentIndex, 0), userModel.roles.name) : userModel.lastUser, "", sessionModel.lastIndex)
                    }
                }
            }
        }
    }
}
