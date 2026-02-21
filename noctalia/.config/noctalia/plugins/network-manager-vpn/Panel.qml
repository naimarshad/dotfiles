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

    readonly property var main: pluginApi?.mainInstance ?? null
    readonly property var vpnList: main?.vpnList ?? []
    readonly property bool isLoading: main?.isLoading ?? false
    readonly property var activeList: vpnList.filter(v => v.connected || v.isLoading)
    readonly property var inactiveList: vpnList.filter(v => !v.connected && !v.isLoading)

    property real contentPreferredWidth: Math.round(500 * Style.uiScaleRatio)
    property real contentPreferredHeight: Math.min(500, mainColumn.implicitHeight + Style.marginL * 2)

    Component.onCompleted: {
        if (main) main.refresh()
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        // HEADER
        NBox {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(header.implicitHeight + Style.marginM * 2 + 1)

            ColumnLayout {
                id: header
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                RowLayout {
                    NIcon {
                        icon: "key"
                        pointSize: Style.fontSizeXXL
                        color: Color.mPrimary
                    }

                    NLabel {
                        label: pluginApi?.tr("common.vpn") || "VPN"
                    }

                    NBox {
                        Layout.fillWidth: true
                    }

                    NIconButton {
                        icon: "refresh"
                        tooltipText: pluginApi?.tr("common.refresh") || "Refresh"
                        baseSize: Style.baseWidgetSize * 0.8
                        enabled: true
                        onClicked: {
                            onClicked: { if (main) main.refresh() }
                        }
                    }


                    NIconButton {
                        icon: "close"
                        tooltipText: pluginApi?.tr("common.close") || "close"
                        baseSize: Style.baseWidgetSize * 0.8
                        onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
                    }
                }
            }
        }

        // CONNECTED
        NBox {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(networksListActive.implicitHeight + Style.marginXL)
            visible: activeList.length > 0

            ColumnLayout {
                id: networksListActive
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.marginS
                    spacing: Style.marginS

                    NLabel {
                        label: 'Connected'
                        Layout.fillWidth: true
                    }
                }

                Repeater {
                    model: activeList

                    NBox {
                        id: networkItem

                        Layout.fillWidth: true
                        Layout.leftMargin: Style.marginXS
                        Layout.rightMargin: Style.marginXS
                        implicitHeight: Math.round(netColumn.implicitHeight + (Style.marginXL))

                        color: Qt.alpha(Color.mPrimary, 0.15)

                        ColumnLayout {
                            id: netColumn
                            width: parent.width - (Style.marginXL)
                            x: Style.marginM
                            y: Style.marginM
                            spacing: Style.marginS

                            // Main row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginS

                                NIcon {
                                    icon: "router"
                                    pointSize: Style.fontSizeXXL
                                    color: Color.mPrimary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    NText {
                                        text: modelData.name
                                        pointSize: Style.fontSizeM
                                        font.weight: Style.fontWeightBold
                                        color: Color.mOnSurface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Style.marginXS

                                        NText {
                                            text: modelData.type
                                            pointSize: Style.fontSizeXXS
                                            color: Color.mOnSurfaceVariant
                                        }

                                        Item {
                                            Layout.preferredWidth: Style.marginXXS
                                        }

                                        Rectangle {
                                            color: Color.mPrimary
                                            radius: height * 0.5
                                            width: Math.round(connectedText.implicitWidth + (Style.marginS * 2))
                                            height: Math.round(connectedText.implicitHeight + (Style.marginXS))

                                            NText {
                                                id: connectedText
                                                anchors.centerIn: parent
                                                text: pluginApi?.tr("common.connected") ||"Connected"
                                                pointSize: Style.fontSizeXXS
                                                color: Color.mOnPrimary
                                            }
                                        }
                                    }
                                }

                                // Action area
                                RowLayout {
                                    spacing: Style.marginS

                                    NBusyIndicator {
                                        visible: modelData.isLoading
                                        running: visible
                                        color: Color.mPrimary
                                        size: Style.baseWidgetSize * 0.5
                                    }

                                    NButton {
                                        text: pluginApi?.tr("common.disconnect") ||"Disconnect"
                                        outlined: !hovered
                                        fontSize: Style.fontSizeS
                                        backgroundColor: Color.mError
                                        enabled: !root.isLoading
                                        onClicked: {
                                            if (!main) return
                                            main.disconnectFrom(modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // DISCONNECTED
        NBox {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(networksListInactive.implicitHeight + Style.marginXL)
            visible: inactiveList.length > 0

            ColumnLayout {
                id: networksListInactive
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: Style.marginS
                    spacing: Style.marginS

                    NLabel {
                        label: 'Disconnected'
                        Layout.fillWidth: true
                    }
                }

                Repeater {
                    model: inactiveList

                    NBox {
                        id: networkItem

                        Layout.fillWidth: true
                        Layout.leftMargin: Style.marginXS
                        Layout.rightMargin: Style.marginXS
                        implicitHeight: Math.round(netColumn.implicitHeight + (Style.marginXL))

                        color: Color.mSurface

                        ColumnLayout {
                            id: netColumn
                            width: parent.width - (Style.marginXL)
                            x: Style.marginM
                            y: Style.marginM
                            spacing: Style.marginS

                            // Main row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Style.marginS

                                NIcon {
                                    icon: "router"
                                    pointSize: Style.fontSizeXXL
                                    color: Color.mOnSurface
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    NText {
                                        text: modelData.name
                                        pointSize: Style.fontSizeM
                                        font.weight: Style.fontWeightMedium
                                        color: Color.mOnSurface
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    RowLayout {
                                        spacing: Style.marginXS

                                        NText {
                                            text: modelData.type
                                            pointSize: Style.fontSizeXXS
                                            color: Color.mOnSurfaceVariant
                                        }

                                        Item {
                                            Layout.preferredWidth: Style.marginXXS
                                        }
                                    }
                                }

                                // Action area
                                RowLayout {
                                    spacing: Style.marginS

                                    NBusyIndicator {
                                        visible: modelData.isLoading
                                        running: visible
                                        color: Color.mPrimary
                                        size: Style.baseWidgetSize * 0.5
                                    }

                                    NButton {
                                        text: pluginApi?.tr("common.connect") ||"Connect"
                                        outlined: !hovered
                                        fontSize: Style.fontSizeS
                                        enabled: !root.isLoading
                                        onClicked: {
                                            if (!main) return
                                            main.connectTo(modelData.name)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // EMPTY
        NBox {
            id: emptyBox
            visible: vpnList.length < 1
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(emptyColumn.implicitHeight + Style.marginM * 2 + 1)

            ColumnLayout {
                id: emptyColumn
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginL

                Item {
                    Layout.fillHeight: true
                }

                NIcon {
                    icon: "search"
                    pointSize: 48
                    color: Color.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

                NText {
                    text: pluginApi?.tr("panel.emptyTitle") || "No VPN found"
                    pointSize: Style.fontSizeL
                    color: Color.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

                NText {
                    text: pluginApi?.tr("panel.emptyDescription") || "Use Network Manager to add a VPN"
                    pointSize: Style.fontSizeS
                    color: Color.mOnSurfaceVariant
                    Layout.alignment: Qt.AlignHCenter
                }

                NButton {
                    text: pluginApi?.tr("common.refresh") ||"Refresh"
                    icon: "refresh"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: { if (main) main.refresh() }
                }

                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
