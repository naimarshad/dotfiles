import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Widgets

Item {
  id: root

  // injected by Noctalia
  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""

  readonly property string screenName: screen?.name ?? ""
  readonly property string barPosition: Settings.getBarPositionForScreen(screenName)
  readonly property bool isBarVertical: barPosition === "left" || barPosition === "right"
  readonly property real capsuleHeight: Style.getCapsuleHeightForScreen(screenName)
  readonly property real barFontSize: Style.getBarFontSizeForScreen(screenName)

  // read from Noctalia cache dir (same style Noctalia uses internally)
  FileView {
    id: ipFile
    path: Settings.cacheDir + "public_ip.txt"
    watchChanges: true
    printErrors: false
  }

  readonly property string ipText: (ipFile.loaded ? ipFile.text().trim() : "")
  readonly property string displayText: ipText.length ? ipText : "—"

  RowLayout { id: content; visible: false } // just to satisfy contentWidth pattern

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
        icon: "globe"
        color: Color.mPrimary
      }

      NText {
        text: root.displayText
        color: Color.mOnSurface
        pointSize: root.barFontSize
      }
    }
  }

  MouseArea {
    id: mouseArea
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.ArrowCursor   // informational widget, not a button
    onClicked: {}                 // no-op
  }
}
