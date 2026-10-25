/*
    Pantalla de carga Zoroark de Hisui: Zoroark flotando sobre un resplandor carmesí
    y una barra que avanza con cada fase del inicio de sesión.
    Basada en Splash.qml de org.kde.breeze.desktop.

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    color: "#1E1C22"

    property int stage
    // ksplash avisa de las fases 1 a 6; la última es "escritorio listo"
    readonly property real progress: Math.min(Math.max(stage, 0) / 6, 1)

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        }
    }

    // Resplandor carmesí detrás de Zoroark (degradado radial en images/glow.png)
    Image {
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height) * 1.3
        height: width
        source: "images/glow.png"
        smooth: true
    }

    Item {
        id: content
        anchors.fill: parent
        opacity: 0

        Image {
            id: zoroark
            readonly property real size: Kirigami.Units.gridUnit * 24

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height / 2 - height / 2 - Kirigami.Units.gridUnit * 2 + float.offset

            asynchronous: true
            source: "images/zoroark.png"
            fillMode: Image.PreserveAspectFit
            sourceSize.height: size
            height: size
            width: size

            QtObject {
                id: float
                property real offset: 0
            }
            SequentialAnimation {
                running: Kirigami.Units.longDuration > 1
                loops: Animation.Infinite
                NumberAnimation { target: float; property: "offset"; from: 0; to: -Kirigami.Units.gridUnit * 0.6; duration: 1800; easing.type: Easing.InOutSine }
                NumberAnimation { target: float; property: "offset"; from: -Kirigami.Units.gridUnit * 0.6; to: 0; duration: 1800; easing.type: Easing.InOutSine }
            }
        }

        // Barra de progreso
        Rectangle {
            id: track
            width: Kirigami.Units.gridUnit * 16
            height: Kirigami.Units.smallSpacing * 1.5
            radius: height / 2
            color: Qt.rgba(242 / 255, 240 / 255, 240 / 255, 0.12)
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: zoroark.bottom
            anchors.topMargin: Kirigami.Units.gridUnit * 2.5 - float.offset

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: Math.max(height, parent.width * root.progress)
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#D82F45" }
                    GradientStop { position: 1.0; color: "#E6A1AB" }
                }
                Behavior on width {
                    NumberAnimation { duration: Kirigami.Units.veryLongDuration * 2; easing.type: Easing.OutCubic }
                }
            }
        }

        Text {
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: Kirigami.Units.gridUnit * 1.5
            }
            text: "Zoroark de Hisui"
            color: "#E6A1AB"
            font.pointSize: Kirigami.Theme.defaultFont.pointSize * 1.1
            font.letterSpacing: 2
            textFormat: Text.PlainText
        }
    }

    OpacityAnimator {
        id: introAnimation
        running: false
        target: content
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
