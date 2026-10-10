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

    // -- Clock: Minutes -- (hyprlock.conf: position 0,-80, font_size 180, $orange)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -root.height * 0.074
        horizontalAlignment: Text.AlignHCenter
        text: { void (root.tick); return Qt.formatDateTime(new Date(), "mm"); }
        color: "#ffb86c"
        font.family: "JetBrains Mono"
        font.pixelSize: Math.round(root.height * 0.167)
    }

    // -- Clock: Hours -- (hyprlock.conf: position 0,140, font_size 180, $purple)
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root.height * 0.13
        horizontalAlignment: Text.AlignHCenter
        text: { void (root.tick); return Qt.formatDateTime(new Date(), "HH"); }
        color: "#bd93f9"
        font.family: "JetBrains Mono"
        font.pixelSize: Math.round(root.height * 0.167)
    }

    // -- Keyboard layout indicator (top) -- matches hyprlock.conf's $LAYOUT label
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20
        text: (keyboard.layouts.length > 0 && keyboard.currentLayout < keyboard.layouts.length)
              ? keyboard.layouts[keyboard.currentLayout].shortName : ""
        color: "#8be9fd"
        font.family: "JetBrains Mono"
        font.pixelSize: 16
    }

    // -- Password field -- a floating pill, not a boxed login card: matches
    // hyprlock's minimal input-field (size 350x60, outer $purple, inner
    // $current_line, font $cyan) instead of a separate panel/button. Enter
    // submits, same as hyprlock - there's no login button here either.
    Rectangle {
        id: passwordBox
        width: Math.min(350, root.width * 0.3)
        height: 60
        radius: height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 120
        color: "#44475a"
        opacity: 0.9
        border.width: 2
        border.color: failed ? "#ff5555" : "#bd93f9"

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
            color: "#8be9fd"
            echoMode: TextInput.Password
            passwordCharacter: "*"
            focus: true
            clip: true

            Text {
                visible: passwordInput.text.length === 0
                text: "🔒 Type Password"
                color: "#8be9fd"
                opacity: 0.6
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
