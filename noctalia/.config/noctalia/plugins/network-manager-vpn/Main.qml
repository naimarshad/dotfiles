import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI

QtObject {
    id: root

    property var pluginApi: null

    property var vpnList: []
    property bool anyConnected: false
    property bool isLoading: false

    property var _pendingNames: ({})

    // Needed only to detect disconnection not initiated by the user
    property var _pollTimer: Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    property var _lines: []

    property var _listProc: Process {
        command: ["nmcli", "-t", "-f", "NAME,TYPE,STATE", "connection", "show"]
        running: true

        stdout: SplitParser {
            onRead: (line) => {
                if (line.trim() !== "")
                    root._lines.push(line)
            }
        }

        onExited: (exitCode) => {
            if (exitCode === 0) {
                const parsed = []
                const newPending = Object.assign({}, root._pendingNames)
                for (const line of root._lines) {
                    const parts = line.split(":")
                    if (parts.length >= 3) {
                        const name  = parts[0]
                        const type  = parts[1]
                        const state = parts[2]
                        if (type === "vpn" || type === "wireguard") {
                            if (newPending[name]) {
                                const wasConnecting = newPending[name] === "connect"
                                if (wasConnecting && state === "activated")
                                    delete newPending[name]
                                else if (!wasConnecting && state !== "activated")
                                    delete newPending[name]
                            }
                            parsed.push({
                                name,
                                type,
                                connected: state === "activated",
                                isLoading: !!newPending[name]
                            })
                        }
                    }
                }
                root._pendingNames = newPending
                root.vpnList = parsed
                root.anyConnected = parsed.some(v => v.connected)
            }
            root._lines = []
            root.isLoading = false
        }
    }

    property var _connectProc: Process {
        property string targetName: ""
        command: ["nmcli", "connection", "up", targetName]
        onExited: (exitCode) => {
            root.isLoading = false
            if (exitCode === 0)
                ToastService.showNotice("VPN «" + targetName + "» connected")
            else
                ToastService.showError("Failed to connect «" + targetName + "»")
            root.refresh()
        }
    }

    property var _disconnectProc: Process {
        property string targetName: ""
        command: ["nmcli", "connection", "down", targetName]
        onExited: (exitCode) => {
            root.isLoading = false
            if (exitCode === 0)
                ToastService.showNotice("VPN «" + targetName + "» disconnected")
            else
                ToastService.showError("Failed to disconnect «" + targetName + "»")
            root.refresh()
        }
    }

    function refresh() {
        _listProc.running = true
    }

    function connectTo(name) {
        isLoading = true
        const p = Object.assign({}, _pendingNames)
        p[name] = "connect"
        _pendingNames = p
        vpnList = vpnList.map(v => v.name === name ? Object.assign({}, v, { isLoading: true }) : v)
        _connectProc.targetName = name
        _connectProc.running = true
    }

    function disconnectFrom(name) {
        isLoading = true
        const p = Object.assign({}, _pendingNames)
        p[name] = "disconnect"
        _pendingNames = p
        vpnList = vpnList.map(v => v.name === name ? Object.assign({}, v, { isLoading: true }) : v)
        _disconnectProc.targetName = name
        _disconnectProc.running = true
    }

    Component.onCompleted: {
        Logger.i("NetworkManagerVPN", "Started")
    }
}
