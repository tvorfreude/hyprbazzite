import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Window
import SddmComponents

Rectangle {
    id: root
    color: "#0f1119"
    width: Screen.width
    height: Screen.height

    // Lava lamp background
    Item {
        anchors.fill: parent
        clip: true

        // Background base
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: "#1a1d2e"
                }
                GradientStop {
                    position: 1.0
                    color: "#0f1119"
                }
            }
        }

        // Animated blob 1 - Purple
        Rectangle {
            id: blob1
            width: 600
            height: 600
            radius: 300
            x: Math.random() * (parent.width - width)
            y: Math.random() * (parent.height - height)

            property real targetX1: Math.random() * (parent.width - width)
            property real targetX2: Math.random() * (parent.width - width)
            property real targetY1: Math.random() * (parent.height - height)
            property real targetY2: Math.random() * (parent.height - height)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.6)
                } // Purple
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.45)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.3)
                }
                GradientStop {
                    position: 0.65
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.12)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.741, 0.576, 0.976, 0)
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.5
                blurMax: 80
            }

            SequentialAnimation on x {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob1.targetX1
                    duration: 35000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob1.targetX2
                    duration: 35000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob1.targetY1
                    duration: 28000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob1.targetY2
                    duration: 28000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Animated blob 2 - Purple
        Rectangle {
            id: blob2
            width: 500
            height: 500
            radius: 250
            x: Math.random() * (parent.width - width)
            y: Math.random() * (parent.height - height)

            property real targetX1: Math.random() * (parent.width - width)
            property real targetX2: Math.random() * (parent.width - width)
            property real targetY1: Math.random() * (parent.height - height)
            property real targetY2: Math.random() * (parent.height - height)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.58)
                } // Purple
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.42)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.28)
                }
                GradientStop {
                    position: 0.65
                    color: Qt.rgba(0.741, 0.576, 0.976, 0.1)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.741, 0.576, 0.976, 0)
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.5
                blurMax: 80
            }

            SequentialAnimation on x {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob2.targetX1
                    duration: 38000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob2.targetX2
                    duration: 38000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob2.targetY1
                    duration: 32000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob2.targetY2
                    duration: 32000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Animated blob 3 - Cyan
        Rectangle {
            id: blob3
            width: 550
            height: 550
            radius: 275
            x: Math.random() * (parent.width - width)
            y: Math.random() * (parent.height - height)

            property real targetX1: Math.random() * (parent.width - width)
            property real targetX2: Math.random() * (parent.width - width)
            property real targetY1: Math.random() * (parent.height - height)
            property real targetY2: Math.random() * (parent.height - height)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.62)
                } // Cyan
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.46)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.32)
                }
                GradientStop {
                    position: 0.65
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.14)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.545, 0.914, 0.992, 0)
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.5
                blurMax: 80
            }

            SequentialAnimation on x {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob3.targetX1
                    duration: 40000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob3.targetX2
                    duration: 40000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob3.targetY1
                    duration: 30000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob3.targetY2
                    duration: 30000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Animated blob 4 - Cyan
        Rectangle {
            id: blob4
            width: 450
            height: 450
            radius: 225
            x: Math.random() * (parent.width - width)
            y: Math.random() * (parent.height - height)

            property real targetX1: Math.random() * (parent.width - width)
            property real targetX2: Math.random() * (parent.width - width)
            property real targetY1: Math.random() * (parent.height - height)
            property real targetY2: Math.random() * (parent.height - height)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.58)
                } // Cyan
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.42)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.28)
                }
                GradientStop {
                    position: 0.65
                    color: Qt.rgba(0.545, 0.914, 0.992, 0.1)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.545, 0.914, 0.992, 0)
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.5
                blurMax: 80
            }

            SequentialAnimation on x {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob4.targetX1
                    duration: 36000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob4.targetX2
                    duration: 36000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob4.targetY1
                    duration: 26000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob4.targetY2
                    duration: 26000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Animated blob 5 - Purple/Cyan Mix
        Rectangle {
            id: blob5
            width: 400
            height: 400
            radius: 200
            x: Math.random() * (parent.width - width)
            y: Math.random() * (parent.height - height)

            property real targetX1: Math.random() * (parent.width - width)
            property real targetX2: Math.random() * (parent.width - width)
            property real targetY1: Math.random() * (parent.height - height)
            property real targetY2: Math.random() * (parent.height - height)

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(0.643, 0.745, 0.933, 0.55)
                } // Purple-Cyan blend
                GradientStop {
                    position: 0.2
                    color: Qt.rgba(0.643, 0.745, 0.933, 0.4)
                }
                GradientStop {
                    position: 0.4
                    color: Qt.rgba(0.643, 0.745, 0.933, 0.26)
                }
                GradientStop {
                    position: 0.65
                    color: Qt.rgba(0.643, 0.745, 0.933, 0.09)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(0.643, 0.745, 0.933, 0)
                }
            }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.5
                blurMax: 80
            }

            SequentialAnimation on x {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob5.targetX1
                    duration: 42000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob5.targetX2
                    duration: 42000
                    easing.type: Easing.InOutQuad
                }
            }

            SequentialAnimation on y {
                running: true
                loops: Animation.Infinite
                NumberAnimation {
                    to: blob5.targetY1
                    duration: 34000
                    easing.type: Easing.InOutQuad
                }
                NumberAnimation {
                    to: blob5.targetY2
                    duration: 34000
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // Dark overlay to tone down brightness
        Rectangle {
            anchors.fill: parent
            color: "#0f1119"
            opacity: 0.3
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

            // Greeting widget - top right
            Rectangle {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 40
                width: 200
                height: 90
                color: "#1a1b2880"
                border.color: "#3d3f52"
                border.width: 1
                radius: 12
                opacity: 0.9

                Column {
                    anchors.centerIn: parent
                    spacing: 8
                    width: parent.width * 0.85

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            var hour = new Date().getHours();
                            if (hour < 12)
                                return "Good Morning";
                            if (hour < 18)
                                return "Good Afternoon";
                            return "Good Evening";
                        }
                        color: "#bd93f9"
                        font.family: "Inter, Liberation Mono"
                        font.pixelSize: 16
                        font.weight: Font.Medium
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width * 0.7
                        height: 1
                        color: "#3d3f52"
                        opacity: 0.5
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 4

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                var start = new Date(new Date().getFullYear(), 0, 0);
                                var diff = new Date() - start;
                                var oneDay = 1000 * 60 * 60 * 24;
                                var day = Math.floor(diff / oneDay);
                                return "Day " + day + " of " + new Date().getFullYear();
                            }
                            color: "#8be9fd"
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 10
                            opacity: 0.7
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                var date = new Date();
                                var onejan = new Date(date.getFullYear(), 0, 1);
                                var week = Math.ceil((((date - onejan) / 86400000) + onejan.getDay() + 1) / 7);
                                return "Week " + week;
                            }
                            color: "#6272a4"
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 9
                            opacity: 0.6
                        }
                    }
                }
            }

            // System info widget - top left
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 40
                width: 180
                height: 90
                color: "#1a1b2880"
                border.color: "#3d3f52"
                border.width: 1
                radius: 12
                opacity: 0.9

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    spacing: 8

                    Row {
                        width: parent.width
                        spacing: 6

                        Text {
                            text: sddm.hostName
                            color: "#50fa7b"
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 1
                        color: "#3d3f52"
                        opacity: 0.5
                    }

                    Column {
                        width: parent.width
                        spacing: 4

                        Text {
                            text: {
                                var session = sessionModel.data(sessionModel.index(sessionModel.lastIndex, 0), 257);
                                var sessionName = session.split('/').pop().split('.')[0];
                                return "Session: " + sessionName;
                            }
                            color: "#8be9fd"
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }

                        Text {
                            text: "Uptime: Ready"
                            color: "#6272a4"
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 9
                            opacity: 0.7
                        }
                    }
                }
            }

            // Center clock and date
            Column {
                anchors.centerIn: parent
                spacing: 16

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(new Date(), "HH:mm")
                    color: "#f8f8f2"
                    font.family: "Inter, Liberation Mono"
                    font.weight: Font.Thin
                    font.pixelSize: Math.max(140, root.height * 0.22)
                    lineHeight: 0.95

                    SequentialAnimation on opacity {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation {
                            to: 0.6
                            duration: 2500
                            easing.type: Easing.InOutQuad
                        }
                        NumberAnimation {
                            to: 1.0
                            duration: 2500
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        text: Qt.formatDateTime(new Date(), "MMMM d, dddd")
                        color: "#8be9fd"
                        font.family: "Inter, Liberation Mono"
                        font.pixelSize: Math.max(13, root.height * 0.017)
                        font.weight: Font.Light
                        opacity: 0.8
                        font.letterSpacing: 0.5
                    }

                    Text {
                        text: "•"
                        color: "#6272a4"
                        font.pixelSize: Math.max(12, root.height * 0.015)
                        opacity: 0.4
                    }

                    Text {
                        text: new Date().getFullYear().toString()
                        color: "#f8f8f2"
                        font.family: "Inter, Liberation Mono"
                        font.pixelSize: Math.max(12, root.height * 0.015)
                        font.weight: Font.Light
                        opacity: 0.9

                        style: Text.Outline
                        styleColor: "#0f1119"
                    }
                }
            }
        }

        // Bottom 35% - Login panel
        Item {
            width: parent.width
            height: parent.height * 0.35

            // Subtle backdrop blur
            Rectangle {
                id: loginPanel
                anchors.centerIn: parent
                width: Math.min(root.width * 0.32, 520)
                height: Math.min(root.height * 0.26, 380)
                color: "#1a1b28"
                radius: 20

                layer.enabled: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blur: 0.6
                    blurMax: 48
                    blurMultiplier: 1.0
                    shadowEnabled: true
                    shadowColor: "#00000040"
                    shadowBlur: 1.0
                    shadowVerticalOffset: 4
                }
            }

            // Content container
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(root.width * 0.32, 520)
                height: Math.min(root.height * 0.26, 380)
                color: "transparent"
                radius: 20
                border.color: "#3d3f52"
                border.width: 1

                Column {
                    anchors.centerIn: parent
                    width: parent.width * 0.85
                    height: parent.height * 0.9
                    spacing: 0

                    // User display section
                    Item {
                        width: parent.width
                        height: parent.height * 0.25

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            width: parent.width * 0.7

                            Text {
                                text: "Account"
                                color: "#6272a4"
                                font.family: "Inter, Liberation Mono"
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                opacity: 0.6
                                font.letterSpacing: 0.5
                            }

                            Text {
                                id: usernameDisplay
                                text: userModel.data(userModel.index(userModel.lastIndex, 0), 257) || "Select"
                                color: "#f8f8f2"
                                font.family: "Inter, Liberation Mono"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                        }

                        // User navigation buttons - minimal design
                        Row {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6

                            Rectangle {
                                id: prevUserBtn
                                width: 32
                                height: 32
                                color: "transparent"
                                border.color: prevUserMouse.containsMouse ? "#bd93f9" : "#3d3f52"
                                border.width: 1
                                radius: 8
                                opacity: prevUserMouse.containsMouse ? 1 : 0.5

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "‹"
                                    color: "#bd93f9"
                                    font.pixelSize: 18
                                    font.weight: Font.Light
                                }

                                MouseArea {
                                    id: prevUserMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let currentIndex = userModel.lastIndex;
                                        let newIndex = currentIndex > 0 ? currentIndex - 1 : userModel.rowCount() - 1;
                                        userModel.lastIndex = newIndex;
                                        usernameDisplay.text = userModel.data(userModel.index(newIndex, 0), 257);
                                    }
                                }
                            }

                            Rectangle {
                                id: nextUserBtn
                                width: 32
                                height: 32
                                color: "transparent"
                                border.color: nextUserMouse.containsMouse ? "#bd93f9" : "#3d3f52"
                                border.width: 1
                                radius: 8
                                opacity: nextUserMouse.containsMouse ? 1 : 0.5

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "›"
                                    color: "#bd93f9"
                                    font.pixelSize: 18
                                    font.weight: Font.Light
                                }

                                MouseArea {
                                    id: nextUserMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        let currentIndex = userModel.lastIndex;
                                        let newIndex = (currentIndex + 1) % userModel.rowCount();
                                        userModel.lastIndex = newIndex;
                                        usernameDisplay.text = userModel.data(userModel.index(newIndex, 0), 257);
                                    }
                                }
                            }
                        }
                    }

                    // Spacing
                    Item {
                        width: 1
                        height: parent.height * 0.08
                    }

                    // Password field
                    Rectangle {
                        id: passwordBox
                        width: parent.width
                        height: parent.height * 0.28
                        color: "#0f1119"
                        border.color: passwordInput.activeFocus ? "#bd93f9" : "#2a2d3a"
                        border.width: 1
                        radius: 10
                        opacity: 1

                        property bool showPassword: false

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        layer.enabled: passwordInput.activeFocus
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: "#bd93f940"
                            shadowBlur: 0.8
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 0
                        }

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            leftPadding: 14
                            rightPadding: 70
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 14
                            color: "#f8f8f2"
                            echoMode: passwordBox.showPassword ? TextInput.Normal : TextInput.Password
                            passwordCharacter: "●"
                            focus: true
                            verticalAlignment: TextInput.AlignVCenter

                            onAccepted: {
                                sddm.login(userModel.data(userModel.index(userModel.lastIndex, 0), 257), passwordInput.text, 0);
                            }
                        }

                        // Show/hide password toggle
                        Rectangle {
                            id: showPasswordBtn
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: 50
                            height: 28
                            color: "transparent"
                            border.color: showPasswordMouse.containsMouse ? "#bd93f9" : "#3d3f52"
                            border.width: 1
                            radius: 6
                            opacity: showPasswordMouse.containsMouse ? 1 : 0.6

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: passwordBox.showPassword ? "Hide" : "Show"
                                color: "#bd93f9"
                                font.family: "Inter, Liberation Mono"
                                font.pixelSize: 10
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: showPasswordMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    passwordBox.showPassword = !passwordBox.showPassword;
                                }
                            }
                        }
                    }

                    // Spacing
                    Item {
                        width: 1
                        height: parent.height * 0.08
                    }

                    // Login button
                    Rectangle {
                        id: loginButton
                        width: parent.width
                        height: parent.height * 0.28
                        color: loginButtonMouse.containsMouse ? "#50fa7b" : "#bd93f9"
                        radius: 10
                        opacity: 1

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                                easing.type: Easing.OutQuad
                            }
                        }

                        scale: loginButtonMouse.pressed ? 0.98 : 1.0
                        Behavior on scale {
                            NumberAnimation {
                                duration: 120
                                easing.type: Easing.OutQuad
                            }
                        }

                        layer.enabled: loginButtonMouse.containsMouse
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowColor: loginButtonMouse.containsMouse ? "#50fa7b60" : "#bd93f960"
                            shadowBlur: 0.8
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 2
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "Login"
                            color: "#0f1119"
                            font.family: "Inter, Liberation Mono"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.3
                        }

                        MouseArea {
                            id: loginButtonMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                sddm.login(userModel.data(userModel.index(userModel.lastIndex, 0), 257), passwordInput.text, 0);
                            }
                        }
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
        }
    }

    Component.onCompleted: {
        passwordInput.forceActiveFocus();
    }
}
