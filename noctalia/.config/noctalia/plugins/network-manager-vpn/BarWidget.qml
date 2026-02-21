import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI

Item {
    id: root

    property var pluginApi: null
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    readonly property string screenName: screen?.name ?? ""
    readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
    readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
    readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
    readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

    readonly property var main: pluginApi?.mainInstance ?? null
    readonly property var vpnList: main?.vpnList ?? []
    readonly property bool anyConnected: main?.anyConnected ?? false
    readonly property bool isLoading: main?.isLoading ?? false

    readonly property real contentWidth: row.implicitWidth + Style.marginM * 2
    readonly property real contentHeight: capsuleHeight

    implicitWidth: contentWidth
    implicitHeight: contentHeight

    Rectangle {
        id: visualCapsule
        x: Style.pixelAlignCenter(parent.width, width)
        y: Style.pixelAlignCenter(parent.height, height)
        width: root.contentWidth
        height: root.contentHeight
        color: mouseArea.containsMouse ? Color.mHover : Style.capsuleColor
        radius: Style.radiusL
        border.color: Style.capsuleBorderColor
        border.width: Style.capsuleBorderWidth

        RowLayout {
            id: row
            anchors.centerIn: parent
            spacing: Style.marginS

            NIcon {
                id: statusIcon
                icon: root.isLoading ? "reload"
                    : root.anyConnected ? "lock" : "lock-open"
                color: mouseArea.containsMouse ? Color.mOutline : Color.mOnSurface

                RotationAnimation on rotation {
                    running: root.isLoading
                    loops: Animation.Infinite
                    from: 0; to: 360
                    duration: 900
                    onStopped: statusIcon.rotation = 0
                }
            }

            NText {
                text: pluginApi?.tr("common.vpn") || "VPN"
                color: mouseArea.containsMouse ? Color.mOutline : Color.mOnSurface
                pointSize: root.barFontSize
            }

            Rectangle {
                visible: root.anyConnected && !root.isLoading
                implicitWidth: badgeText.implicitWidth + 6
                implicitHeight: 14
                radius: 7
                color: Color.mPrimary

                NText {
                    id: badgeText
                    anchors.centerIn: parent
                    text: root.vpnList.filter(v => v.connected).length.toString()
                    color: Color.mOnPrimary
                    pointSize: Style.fontSizeXS
                    font.weight: Font.Bold
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (pluginApi) pluginApi.openPanel(root.screen, root)
        }
    }

    Component.onCompleted: {
        Logger.i("NetworkManagerVPN", "Bar widget loaded")
    }
}
