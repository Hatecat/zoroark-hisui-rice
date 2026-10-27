/*
 Carrusel Zoroark: Cover Switch de KWin con el tema Zoroark de Hisui.
 Basado en coverswitch de KWin (SPDX-FileCopyrightText: 2021 Ismael Asensio <isma.af@gmail.com>)

 SPDX-License-Identifier: GPL-2.0-or-later
 */

import QtQuick
import Qt5Compat.GraphicalEffects
import QtQuick.Layouts
import QtQuick.Window

import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PC3

import org.kde.kwin as KWin
import org.kde.kwin.private.effects


KWin.TabBoxSwitcher {
    id: tabBox
    currentIndex: thumbnailView ? thumbnailView.currentIndex : -1

    // Paleta Zoroark de Hisui
    readonly property color crimson: "#D82F45"
    readonly property color gold: "#F3C94E"
    readonly property color pink: "#E6A1AB"
    readonly property color muted: "#6E6873"
    readonly property color night: "#1E1C22"
    readonly property int cornerRadius: 14

    // Runa al azar del futhark en cada apertura, como en el prompt
    readonly property var runes: ["ᚠ", "ᚢ", "ᚦ", "ᚨ", "ᚱ", "ᚲ", "ᚷ", "ᚹ", "ᚺ", "ᚾ", "ᛁ", "ᛃ", "ᛇ", "ᛈ", "ᛉ", "ᛊ", "ᛏ", "ᛒ", "ᛖ", "ᛗ", "ᛚ", "ᛜ", "ᛞ", "ᛟ"]
    property string rune: runes[0]

    Window {
        id: window

        x: tabBox.screenGeometry.x
        y: tabBox.screenGeometry.y
        width: tabBox.screenGeometry.width
        height: tabBox.screenGeometry.height
        flags: Qt.Popup | Qt.BypassWindowManagerHint | Qt.FramelessWindowHint
        visibility: Window.FullScreen
        // Workaround QTBUG-35244. Do not directly assign here to avoid warning
        visible: true

        color: "transparent"

        Accessible.name: currentItem?.caption

        KWin.DesktopBackground {
            activity: KWin.Workspace.currentActivity
            desktop: KWin.Workspace.currentVirtualDesktop
            outputName: window.screen.name

            layer.enabled: true
            layer.effect: FastBlur {
                radius: 64
            }
        }

        // Mismo degradado que los menús del estilo de Plasma
        Rectangle {
            anchors.fill: parent
            opacity: 0.7
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#6B2034" }
                GradientStop { position: 0.5; color: "#43202D" }
                GradientStop { position: 1.0; color: tabBox.night }
            }
        }

        Kirigami.PlaceholderMessage {
            anchors.centerIn: parent
            width: parent.width - Kirigami.Units.largeSpacing * 2
            icon.source: "edit-none"
            text: i18ndc("kwin", "@info:placeholder no entries in the task switcher", "No open windows")
            visible: thumbnailView.count === 0
        }


        PathView {
            id: thumbnailView

            readonly property int visibleCount: Math.min(count, pathItemCount)
            readonly property real boxScaleFactor: 0.5
            readonly property int boxWidth: tabBox.screenGeometry.width * boxScaleFactor
            readonly property int boxHeight: tabBox.screenGeometry.height * boxScaleFactor

            focus: true

            anchors.fill: parent

            preferredHighlightBegin: 0.49
            preferredHighlightEnd: preferredHighlightBegin
            highlightRangeMode: PathView.StrictlyEnforceRange

            // This property sets the animation duration between the current position to the next one,
            // without taking into account how much distance the thumbnails travel in that time.
            // To compensate the speed, we slowly reduce the duration with the number of thumbnails,
            // starting from `veryLongDuration` when there are 2 of them
            highlightMoveDuration: Kirigami.Units.veryLongDuration * (2 / Math.sqrt(visibleCount + 1))

            pathItemCount: 13

            // Algo más arriba que el original para dejar sitio al reflejo
            path: Path {
                // Left stack
                startX: thumbnailView.width * 0.1; startY: thumbnailView.height * 0.43
                PathAttribute { name: "progress"; value: 0 }
                PathAttribute { name: "scale"; value: 0.7 }
                PathAttribute { name: "rotation"; value: 70 }
                PathPercent { value: 0 }

                PathLine { x: thumbnailView.width * 0.25 ; y: thumbnailView.height * 0.43 }
                PathAttribute { name: "progress"; value: 0.8 }
                PathAttribute { name: "scale"; value: 0.7 }
                PathAttribute { name: "rotation"; value: 70 }
                PathPercent { value: 0.4 }

                // Center Item
                PathQuad {
                    x: thumbnailView.width * 0.5 ; y: thumbnailView.height * 0.5
                    controlX: thumbnailView.width * 0.45; controlY: thumbnailView.height * 0.47
                }
                PathAttribute { name: "progress"; value: 1 }
                PathAttribute { name: "scale"; value: 1 }
                PathAttribute { name: "rotation"; value: 0 }
                PathPercent { value: 0.49 } // A bit less than 50% so items preferably stack on the right side

                // Right stack
                PathQuad {
                    x: thumbnailView.width * 0.75 ; y: thumbnailView.height * 0.43
                    controlX: thumbnailView.width * 0.55; controlY: thumbnailView.height * 0.47
                }
                PathAttribute { name: "progress"; value: 0.8 }
                PathAttribute { name: "scale"; value: 0.7 }
                PathAttribute { name: "rotation"; value: -70 }
                PathPercent { value: 0.6 }

                PathLine { x: thumbnailView.width * 0.9 ; y: thumbnailView.height * 0.43 }
                PathAttribute { name: "progress"; value: 0 }
                PathAttribute { name: "scale"; value: 0.7 }
                PathAttribute { name: "rotation"; value: -70 }
                PathPercent { value: 1 }
            }

            model: tabBox.model

            delegate: Item {
                id: delegateItem

                readonly property string caption: model.caption
                readonly property var icon: model.icon

                readonly property real scaleFactor: {
                    if (thumbnail.implicitWidth < thumbnailView.boxWidth && thumbnail.implicitHeight < thumbnailView.boxHeight) {
                        // Do not scale up thumbnails smaller than the box frame
                        return 1;
                    } else if (thumbnail.ratio > thumbnailView.boxWidth / thumbnailView.boxHeight) {
                        // Thumbnail is wider than the box
                        return thumbnailView.boxWidth / thumbnail.implicitWidth;
                    } else {
                        // Thumbnail is taller than the box
                        return thumbnailView.boxHeight / thumbnail.implicitHeight;
                    }
                }

                width: Math.round(thumbnail.implicitWidth * scaleFactor)
                height: Math.round(thumbnail.implicitHeight * scaleFactor)
                scale: PathView.onPath ? PathView.scale : 0
                z: PathView.onPath ? Math.floor(PathView.progress * thumbnailView.visibleCount) : -1
                Accessible.name: caption

                KWin.WindowThumbnail {
                    id: thumbnail
                    readonly property double ratio: implicitWidth / implicitHeight

                    wId: windowId
                    anchors.fill: parent

                    // Esquinas redondeadas como las ventanas
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: thumbnail.width
                            height: thumbnail.height
                            radius: tabBox.cornerRadius
                        }
                    }
                }

                // Reflejo sobre el "suelo", que se desvanece hacia abajo
                ShaderEffectSource {
                    id: reflection
                    sourceItem: thumbnail
                    width: parent.width
                    height: parent.height
                    anchors.top: parent.bottom
                    anchors.topMargin: Kirigami.Units.smallSpacing
                    opacity: 0.3
                    transform: Scale { yScale: -1; origin.y: reflection.height / 2 }

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        // Antes de voltear: opaco abajo (pegado a la ventana), transparente a media altura
                        maskSource: LinearGradient {
                            width: reflection.width
                            height: reflection.height
                            start: Qt.point(0, reflection.height * 0.55)
                            end: Qt.point(0, reflection.height)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: "black" }
                            }
                        }
                    }
                }

                Kirigami.ShadowedRectangle {
                    anchors.fill: parent
                    z: -1

                    color: "transparent"
                    radius: tabBox.cornerRadius
                    shadow.size: Kirigami.Units.gridUnit
                    shadow.color: "black"
                    opacity: 0.5
                }

                transform: Rotation {
                    origin { x: delegateItem.width/2; y: delegateItem.height/2 }
                    axis { x: 0; y: 1; z: 0 }
                    angle: delegateItem.PathView.rotation
                }

                TapHandler {
                    grabPermissions: PointerHandler.TakeOverForbidden
                    gesturePolicy: TapHandler.WithinBounds
                    onSingleTapped: {
                        if (index === thumbnailView.currentIndex) {
                            thumbnailView.model.activate(index);
                            return;
                        }
                        thumbnailView.movementDirection = (delegateItem.PathView.rotation < 0) ? PathView.Positive : PathView.Negative
                        thumbnailView.currentIndex = index
                    }
                }
            }

            // Marco carmesí con brillo y filo dorado en lugar del resaltado de Breeze
            highlight: Item {
                id: highlightItem

                readonly property Item target: thumbnailView.currentItem
                readonly property int margin: 2 * Kirigami.Units.smallSpacing

                visible: target !== null
                // Make sure the highlight is pixel perfect aligned on both sides even if the target is not
                anchors.centerIn: target
                anchors.horizontalCenterOffset: target ? Math.round(target.x) - target.x : 0
                anchors.verticalCenterOffset: target ? Math.round(target.y) - target.y : 0
                width: target ? Math.round(target.width/2 + margin) * 2 : 0
                height: target ? Math.round(target.height/2 + margin) * 2 : 0
                scale: target ? target.scale : 1
                z: target ? target.z - 0.5 : -0.5
                // The transform cannot be directly assigned as the transform origin is different
                transform: Rotation {
                    origin { x: highlightItem.width/2; y: highlightItem.height/2 }
                    axis { x: 0; y: 1; z: 0 }
                    angle: target ? target.PathView.rotation : 0
                }

                RectangularGlow {
                    anchors.fill: parent
                    glowRadius: Kirigami.Units.gridUnit
                    spread: 0.15
                    color: tabBox.crimson
                    cornerRadius: tabBox.cornerRadius + highlightItem.margin + glowRadius
                    opacity: 0.8
                }

                Rectangle {
                    anchors.fill: parent
                    radius: tabBox.cornerRadius + highlightItem.margin
                    color: tabBox.night
                    border.color: tabBox.crimson
                    border.width: 3
                }

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 3
                    radius: tabBox.cornerRadius + highlightItem.margin - 3
                    color: "transparent"
                    border.color: tabBox.gold
                    border.width: 1
                    opacity: 0.6
                }
            }

            layer.enabled: true
            layer.smooth: true

            onMovementStarted: movementDirection = PathView.Shortest

            Keys.onUpPressed: decrementCurrentIndex()
            Keys.onLeftPressed: decrementCurrentIndex()
            Keys.onDownPressed: incrementCurrentIndex()
            Keys.onRightPressed: incrementCurrentIndex()
        }

        // Píldora con icono, runa, título y posición en la lista
        Rectangle {
            id: infoBar

            visible: thumbnailView.count > 0
            width: infoRow.implicitWidth + 2 * Kirigami.Units.gridUnit
            height: infoRow.implicitHeight + Kirigami.Units.largeSpacing * 2
            radius: height / 2
            color: Qt.alpha(tabBox.night, 0.85)
            border.color: tabBox.crimson
            border.width: 1.5

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                margins: Kirigami.Units.gridUnit * 2
            }

            RowLayout {
                id: infoRow
                anchors.centerIn: parent
                spacing: Kirigami.Units.largeSpacing

                Kirigami.Icon {
                    source: thumbnailView.currentItem?.icon ?? ""
                    implicitWidth: Kirigami.Units.iconSizes.medium
                    implicitHeight: Kirigami.Units.iconSizes.medium
                    Layout.alignment: Qt.AlignCenter
                }

                Text {
                    text: tabBox.rune
                    color: tabBox.pink
                    font.family: "Noto Sans Runic"
                    font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.6)
                    Layout.alignment: Qt.AlignCenter
                }

                PC3.Label {
                    font.bold: true
                    font.pointSize: Math.round(Kirigami.Theme.defaultFont.pointSize * 1.4)
                    color: "#F2ECEE"
                    text: thumbnailView.currentItem?.caption ?? ""
                    textFormat: Text.PlainText
                    maximumLineCount: 1
                    elide: Text.ElideMiddle
                    Layout.maximumWidth: tabBox.screenGeometry.width * 0.6
                    Layout.alignment: Qt.AlignCenter
                }

                PC3.Label {
                    color: tabBox.gold
                    text: "%1 / %2".arg(thumbnailView.currentIndex + 1).arg(thumbnailView.count)
                    textFormat: Text.PlainText
                    Layout.alignment: Qt.AlignCenter
                }
            }
        }

        onSceneGraphError: () => {
            // This slot is intentionally left blank, otherwise QtQuick may post a qFatal() message on a graphics reset.
        }
    }

    onCurrentIndexChanged: {
        if (currentIndex === thumbnailView.currentIndex) {
            return
        }

        // WindowSwitcher always changes currentIndex in increments of 1.
        // Detect the change direction and set the PathView movement accordingly, so fast changes
        // in the same direction don't result into a combination of forward and backward movements.
        if (thumbnailView.count === 2 || (currentIndex === 0 && thumbnailView.currentIndex === thumbnailView.count - 1)) {
            thumbnailView.movementDirection = PathView.Positive
        } else if (currentIndex === thumbnailView.count - 1 && thumbnailView.currentIndex === 0) {
            thumbnailView.movementDirection = PathView.Negative
        } else {
            thumbnailView.movementDirection = (currentIndex > thumbnailView.currentIndex) ? PathView.Positive : PathView.Negative
        }

        thumbnailView.currentIndex = tabBox.currentIndex
    }

    onVisibleChanged: {
        // Reset the PathView index when hiding to avoid unwanted animations on relaunch
        if (!visible) {
            thumbnailView.currentIndex = 0;
        } else {
            rune = runes[Math.floor(Math.random() * runes.length)];
        }
        window.visible = visible;
    }
}
