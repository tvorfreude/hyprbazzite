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

                TextInput {
                    width: parent.width
                    height: 50
                    leftPadding: 15
                    rightPadding: 15
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                    color: "#8be9fd"
                    background: Rectangle {
                        color: "#44475a"
                        border.color: "#bd93f9"
                        border.width: 2
                        radius: 4
                    }
                    echoMode: TextInput.Password
                    focus: true
                    onAccepted: sddm.login(userModel.lastUser, text, sessionModel.lastIndex)
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
                        textRole: "name"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        onCurrentIndexChanged: sessionModel.lastIndex = currentIndex
                    }

                    ComboBox {
                        id: users
                        width: parent.width / 2 - 5
                        height: parent.height
                        model: userModel
                        currentIndex: userModel.lastIndex
                        textRole: "name"
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        onCurrentIndexChanged: userModel.lastIndex = currentIndex
                    }
                }

                Button {
                    width: parent.width
                    height: 45
                    text: "Login"
                    font.family: "JetBrainsMono Nerd Font"
                    font.bold: true
                    font.pixelSize: 14
                    background: Rectangle {
                        color: "#bd93f9"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "#282a36"
                        font: parent.font
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: sddm.login(users.currentIndex >= 0 ? userModel.data(userModel.index(users.currentIndex, 0), userModel.roles.name) : userModel.lastUser, "", sessionModel.lastIndex)
                }
            }
        }
    }
}
