import QtQuick
import QtQuick.Effects
import QtQuick.Window

// Deliberately mirrors hyprlock.conf (system_files/usr/lib/hyprbazzite/hypr/
// hyprlock.conf) rather than being its own design: same wallpaper, same
// stacked MM/HH clock, same minimal floating pill input instead of a boxed
// login card, same Dracula-derived color set hyprlock currently renders
// (see /etc/hypr/wallust/wallust-hyprland.conf - static today, not
// per-wallpaper dynamic, so these literal hex values do in fact match what
// hyprlock is showing right now). The blur/contrast/brightness/saturation
// numbers below are an approximation, not a port - this runs through Qt's
// MultiEffect, a completely different renderer from hyprlock's own OpenGL
// shader, so pixel-identical output isn't achievable; the goal is "the same
// at a glance," not a checksum match.
Rectangle {
    id: root
    color: "#000000"
    width: Screen.width
    height: Screen.height

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.ArrowCursor
        acceptedButtons: Qt.NoButton
    }

    // The sddm system user can't traverse into /home/<user> (mode 0700) to
    // read the live wallpaper straight from the desktop session, so
    // wallpaper_pick()/wallpaper-cycle mirror it to this world-readable path
    // instead (see tmpfiles.d). cache: false so a changed wallpaper shows up
    // on the very next greeter launch rather than a stale cached copy.
    Image {
        id: wallpaper
        anchors.fill: parent
        source: "file:///var/lib/hyprbazzite/theme/current_wallpaper.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        visible: status === Image.Ready

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            brightness: -0.15
            contrast: 0.2
            saturation: 0.15
        }
    }

    // Shown until a wallpaper has been synced at least once (fresh install,
    // before the first login or cycle tick).
    Rectangle {
        anchors.fill: parent
        visible: wallpaper.status !== Image.Ready
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#282a36" }
            GradientStop { position: 1.0; color: "#15161f" }
        }
    }

    property int tick: 0
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.tick++
    }

    // -- Date -- (hyprlock.conf: date label, foreground @ 75%)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.139
        horizontalAlignment: Text.AlignHCenter
        text: { void (root.tick); return Qt.formatDateTime(new Date(), "dddd, MMMM dd"); }
        color: "#f8f8f2"
        opacity: 0.75
        font.family: "JetBrains Mono"
        font.pixelSize: Math.round(root.height * 0.022)
    }

    // -- Time -- (hyprlock.conf: HH:MM, font_size 140, foreground)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.037
        horizontalAlignment: Text.AlignHCenter
        text: { void (root.tick); return Qt.formatDateTime(new Date(), "HH:mm"); }
        color: "#f8f8f2"
        font.family: "JetBrains Mono"
        font.pixelSize: Math.round(root.height * 0.13)
    }

    // -- Keyboard layout indicator (top) -- matches hyprlock.conf's $LAYOUT label
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: (keyboard.layouts.length > 0 && keyboard.currentLayout < keyboard.layouts.length)
              ? keyboard.layouts[keyboard.currentLayout].shortName : ""
        color: "#f8f8f2"
        opacity: 0.6
        font.family: "JetBrains Mono"
        font.pixelSize: 14
    }

    // -- Password field -- a floating pill, not a boxed login card: matches
    // hyprlock's minimal input-field (size 350x60, outer $purple, inner
    // $current_line, font $cyan) instead of a separate panel/button. Enter
    // submits, same as hyprlock - there's no login button here either.
    Rectangle {
        id: passwordBox
        width: Math.min(320, root.width * 0.3)
        height: 48
        radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 120
        color: "#8c282a36"   // Dracula bg @ ~55%, same glass as hyprlock's input
        border.width: 1
        border.color: failed ? "#ff5555" : "#26f8f8f2"

        property bool failed: false

        Behavior on border.color {
            ColorAnimation { duration: 150 }
        }

        TextInput {
            id: passwordInput
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            verticalAlignment: TextInput.AlignVCenter
            font.family: "JetBrains Mono"
            font.pixelSize: 16
            color: "#f8f8f2"
            echoMode: TextInput.Password
            passwordCharacter: "*"
            focus: true
            clip: true

            Text {
                visible: passwordInput.text.length === 0
                text: "Type password"
                color: "#f8f8f2"
                opacity: 0.5
                font: passwordInput.font
                anchors.verticalCenter: parent.verticalCenter
            }

            onAccepted: {
                sddm.login(userModel.data(userModel.index(userModel.lastIndex, 0), 257),
                           passwordInput.text, sessionModel.lastIndex);
            }
        }
    }

    Text {
        id: errorText
        visible: false
        text: "Authentication failed"
        color: "#ff5555"
        font.family: "JetBrains Mono"
        font.pixelSize: 14
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: passwordBox.bottom
        anchors.topMargin: 16
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            passwordInput.text = "";
            passwordBox.failed = true;
            errorText.visible = true;
            errorTimer.start();
        }
    }

    Timer {
        id: errorTimer
        interval: 3000
        onTriggered: {
            passwordBox.failed = false;
            errorText.visible = false;
        }
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
