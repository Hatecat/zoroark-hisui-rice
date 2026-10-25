/*
    Reloj de la pantalla de bloqueo Zoroark de Hisui: hora grande en blanco,
    fecha en dorado y una barra carmesí a la izquierda.
    Basado en Clock.qml de org.kde.breeze.components.

    SPDX-License-Identifier: LGPL-2.0-or-later
*/

import QtQuick
import QtQuick.Layouts

import org.kde.plasma.clock as PlasmaClock
import org.kde.plasma.components as PlasmaComponents3
import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    readonly property bool softwareRendering: GraphicsInfo.api === GraphicsInfo.Software
    readonly property color crimson: "#D82F45"
    readonly property color gold: "#F3C94E"
    readonly property color white: "#F2F0F0"

    spacing: Kirigami.Units.gridUnit

    Rectangle {
        Layout.fillHeight: true
        Layout.topMargin: Kirigami.Units.largeSpacing
        Layout.bottomMargin: Kirigami.Units.smallSpacing
        implicitWidth: Kirigami.Units.smallSpacing * 1.5
        radius: width / 2
        color: root.crimson
    }

    ColumnLayout {
        spacing: 0

        PlasmaComponents3.Label {
            text: Qt.formatTime(timeSource.dateTime, Qt.locale(), Locale.ShortFormat)
            textFormat: Text.PlainText
            color: root.white
            style: root.softwareRendering ? Text.Outline : Text.Normal
            styleColor: root.softwareRendering ? "#1E1C22" : "transparent"
            font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 8)
            font.weight: Font.Normal
            font.letterSpacing: -2.0
            renderType: Text.NativeRendering
        }
        PlasmaComponents3.Label {
            text: Qt.formatDate(timeSource.dateTime, Qt.locale(), Locale.LongFormat)
            textFormat: Text.PlainText
            color: root.gold
            style: root.softwareRendering ? Text.Outline : Text.Normal
            styleColor: root.softwareRendering ? "#1E1C22" : "transparent"
            font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 2.2)
            font.weight: Font.Medium
            renderType: Text.NativeRendering
            Layout.leftMargin: Kirigami.Units.smallSpacing
        }
    }

    PlasmaClock.Clock {
        id: timeSource
        trackSeconds: Qt.locale().timeFormat(Locale.ShortFormat).includes("s")
    }
}
