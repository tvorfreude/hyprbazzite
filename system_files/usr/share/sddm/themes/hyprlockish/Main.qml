import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Window
import SddmComponents

Rectangle {
    id: root
    color: "#282a36"
    width: Screen.width
    height: Screen.height

    // Background with subtle gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#282a36" }
            GradientStop { position: 1.0; color: "#1a1d2e" }
        }
    }

    Column {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // Top 65% - Clock and date
        Item {
            width: parent.width
            height: parent.height * 0.65

            Column {
                anchors.centerIn: parent
                spacing: 10

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Welcome to " + sddm.hostName
                    color: "#bd93f9"
                    font.family: "Liberation Mono"
                    font.pixelSize: Math.max(16, root.height * 0.025)
                    opacity: 0.9
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    color: "#8be9fd"
                    font.family: "Liberation Mono"
                    font.bold: true
                    font.pixelSize: Math.max(180, root.height * 0.25)
                    style: Text.Outline
                    styleColor: "#282a36"
                    
                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.85; duration: 2000; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 1.0; duration: 2000; easing.type: Easing.InOutQuad }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(new Date(), "dddd, MMMM d")
                    color: "#f8f8f2"
                    font.family: "Liberation Mono"
                    font.pixelSize: Math.max(14, root.height * 0.02)
                    opacity: 0.7
                }
            }
        }

        // Bottom 35% - Login panel
        Item {
            width: parent.width
            height: parent.height * 0.35

            // Glassmorphic login panel
            Rectangle {
                id: loginPanel
                anchors.centerIn: parent
                width: Math.min(root.width * 0.35, 550)
                height: Math.min(root.height * 0.28, 320)
                color: "#44475a"
                radius: 16
                opacity: 0.3
                
                // Blur effect for glassmorphism
                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.8
                    blurMax: 64
                    blurMultiplier: 1.0
                }
            }

            // Content overlay on glass panel
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(root.width * 0.35, 550)
                height: Math.min(root.height * 0.28, 320)
                color: "transparent"
                radius: 16
                border.color: "#6272a4"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.88
                    spacing: parent.height * 0.08

                    // Password field with focus glow
                    Rectangle {
                        id: passwordBox
                        width: parent.width
                        height: Math.max(48, parent.parent.height * 0.22)
                        color: "#282a36"
                        border.color: passwordInput.activeFocus ? "#bd93f9" : "#44475a"
                        border.width: passwordInput.activeFocus ? 3 : 2
                        radius: 10
                        opacity: 0.9

                        Behavior on border.color {
                            ColorAnimation { duration: 200 }
                        }

                        Behavior on border.width {
                            NumberAnimation { duration: 200 }
                        }

                        // Glow effect when focused
                        layer.enabled: passwordInput.activeFocus
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#bd93f9"
                            shadowBlur: 0.8
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            leftPadding: parent.height * 0.3
                            rightPadding: parent.height * 0.8
                            font.family: "Liberation Mono"
                            font.pixelSize: Math.max(12, parent.height * 0.3)
                            color: "#f8f8f2"
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            focus: true
                            verticalAlignment: TextInput.AlignVCenter
                            onAccepted: {
                                sddm.login(userModel.data(userModel.index(userModel.lastIndex, 0), 257), passwordInput.text, 0)
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: parent.height * 0.3
                            anchors.verticalCenter: parent.verticalCenter
                            text: "⏎"
                            color: "#bd93f9"
                            font.family: "Liberation Mono"
                            font.pixelSize: Math.max(14, parent.height * 0.35)
                            opacity: 0.7
                        }
                    }

                    // Glassmorphic login button with hover glow
                    Rectangle {
                        id: loginButton
                        width: parent.width
                        height: Math.max(48, parent.parent.height * 0.22)
                        color: loginButtonMouse.containsMouse ? "#ffb86c" : "#bd93f9"
                        radius: 10
                        opacity: 0.95

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }

                        scale: loginButtonMouse.pressed ? 0.97 : 1.0
                        Behavior on scale {
                            NumberAnimation { duration: 150; easing.type: Easing.OutBack }
                        }

                        // Glow effect on hover
                        layer.enabled: loginButtonMouse.containsMouse
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: loginButtonMouse.containsMouse ? "#ffb86c" : "#bd93f9"
                            shadowBlur: 1.0
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Login →"
                            color: "#282a36"
                            font.family: "Liberation Mono"
                            font.pixelSize: Math.max(14, parent.height * 0.35)
                            font.bold: true
                        }

                        MouseArea {
                            id: loginButtonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sddm.login(userModel.data(userModel.index(userModel.lastIndex, 0), 257), passwordInput.text, 0)
                            }
                        }
                    }

                    // Session selector text
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Session: " + sessionModel.data(sessionModel.index(sessionModel.lastIndex, 0), 257)
                        color: "#6272a4"
                        font.family: "Liberation Mono"
                        font.pixelSize: Math.max(10, parent.parent.height * 0.08)
                        opacity: 0.7
                    }
                }
            }
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            parent.update()
        }
    }

    Component.onCompleted: {
        passwordInput.forceActiveFocus()
    }
}
