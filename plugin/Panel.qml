import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "Model.js" as Model

// Spacefast panel: your recent publishes and account spaces, with quick
// actions to open, copy a share link, claim, and publish something new.
// All Spacefast work goes through the bundled bin/omarchy-spacefast script,
// so the panel never handles credentials itself.
Panel {
  id: root
  moduleName: "spacefast.spaces"
  ipcTarget: "spacefast.spaces"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  readonly property string cli: decodeURIComponent(Qt.resolvedUrl("bin/omarchy-spacefast").toString().replace(/^file:\/\//, ""))
  readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/omarchy-spacefast/spaces.json"
  readonly property int refreshIntervalSec: Math.max(30, parseInt(setting("refreshIntervalSec", 300), 10) || 300)

  property var payload: Model.parseSpaces("")
  readonly property var spaces: payload.spaces || []
  readonly property bool signedIn: !!(payload.account && payload.account.authenticated === true)
  property bool loading: false
  property bool loadedOnce: false
  property bool publishing: false
  property string publishingWhat: ""
  property int selectedIndex: 0
  property date now: new Date()

  readonly property var selectedSpace: selectedIndex >= 0 && selectedIndex < spaces.length ? spaces[selectedIndex] : null
  readonly property string label: publishing ? "󰔟" : "󰖟"
  readonly property string tooltip: publishing ? "Publishing " + publishingWhat + "…" : "Spacefast"

  // ---- Lifecycle

  function open() {
    root.controller.show()
    root.refresh()
  }

  function openFromHotkey() {
    root.controller.show()
    root.refresh()
  }

  function close() {
    root.controller.hide()
  }

  function toggle() {
    if (root.opened) root.close()
    else root.openFromHotkey()
  }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.barIdentity, direction)
    return false
  }

  // ---- Actions

  function refresh() {
    root.now = new Date()
    if (listProc.running) return
    root.loading = true
    listProc.running = true
  }

  function run(args) {
    Quickshell.execDetached([root.cli].concat(args))
  }

  function publish(what) {
    if (publishProc.running) return
    root.publishingWhat = what
    root.publishing = true
    root.close()
    publishProc.command = [root.cli, "publish", what]
    publishProc.running = true
  }

  function openSelected() {
    if (!root.selectedSpace) return
    root.run(["open", root.selectedSpace.id])
    root.close()
  }

  function copySelected() {
    if (!root.selectedSpace) return
    root.run(["copy", root.selectedSpace.id])
  }

  function claimSelected() {
    if (!root.selectedSpace || !root.selectedSpace.anonymous) return
    root.run(["claim", root.selectedSpace.id])
    root.close()
  }

  function openDashboard() {
    root.run(["dashboard"])
    root.close()
  }

  function login() {
    root.run(["login"])
    root.close()
  }

  function moveCursor(dy) {
    root.selectedIndex = Model.clampIndex(root.selectedIndex + dy, root.spaces.length)
  }

  function handleKey(t) {
    if (t === "r") root.refresh()
    else if (t === "c" || t === "y") root.copySelected()
    else if (t === "o") root.openSelected()
    else if (t === "a") root.claimSelected()
    else if (t === "d") root.openDashboard()
    // Publishing and signing in are deliberately click-only. The panel takes
    // keyboard focus when it opens, so a stray keystroke meant for another
    // window must never send anything to the internet.
  }

  onSpacesChanged: root.selectedIndex = Model.clampIndex(root.selectedIndex, root.spaces.length)

  // ---- Processes

  Process {
    id: listProc
    command: [root.cli, "spaces", "--json"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var parsed = Model.parseSpaces(text)
        // Keep the last good list if a refresh comes back empty-handed.
        if (parsed.spaces.length > 0 || !root.loadedOnce || parsed.account.authenticated !== root.signedIn)
          root.payload = parsed
        root.loadedOnce = true
      }
    }
    onExited: root.loading = false
  }

  Process {
    id: publishProc
    onExited: {
      root.publishing = false
      root.publishingWhat = ""
      root.refresh()
    }
  }

  // Publishes from the share menu or an agent land in this file; pick them
  // up right away instead of waiting for the next timed refresh.
  FileView {
    path: root.stateFile
    watchChanges: true
    printErrors: false
    onFileChanged: refreshDebounce.restart()
  }

  Timer {
    id: refreshDebounce
    interval: 400
    onTriggered: root.refresh()
  }

  Timer {
    interval: root.refreshIntervalSec * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // Keeps "claim in 5h" and "3m ago" honest while the panel is open.
  Timer {
    interval: 60 * 1000
    running: root.opened
    repeat: true
    onTriggered: root.now = new Date()
  }

  IpcHandler {
    target: root.ipcTarget

    function open(): void { root.openFromHotkey() }
    function close(): void { root.close() }
    function show(): void { root.openFromHotkey() }
    function hide(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { root.refresh() }
    function publishFolder(): void { root.publish("folder") }
    function publishFile(): void { root.publish("file") }
    function publishClipboard(): void { root.publish("clipboard") }
  }

  // ---- UI

  readonly property color foreground: root.bar ? root.bar.foreground : Color.foreground
  readonly property string fontFamily: root.bar ? root.bar.fontFamily : Style.font.family
  readonly property color dim: Qt.darker(foreground, 1.5)

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(460))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onMoveRequested: function(dx, dy) { if (dy !== 0) root.moveCursor(dy) }
      onActivateRequested: root.openSelected()
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }
      onTextKey: function(t) { root.handleKey(t) }

      Flickable {
        id: scroller
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: content
          width: scroller.width
          spacing: Style.space(10)

          // ---- Header: title, account, refresh.
          Item {
            width: parent.width
            height: Math.max(titleColumn.implicitHeight, headerButtons.implicitHeight)

            Column {
              id: titleColumn
              anchors.left: parent.left
              anchors.leftMargin: Style.space(6)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                textFormat: Text.PlainText
                text: "Spacefast"
                color: root.foreground
                font.family: root.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
              }
              Text {
                textFormat: Text.PlainText
                text: root.loadedOnce ? Model.accountLabel(root.payload) : "Loading…"
                color: root.dim
                font.family: root.fontFamily
                font.pixelSize: Style.font.bodySmall
              }
            }

            Row {
              id: headerButtons
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(4)

              PanelActionButton {
                visible: root.loadedOnce && !root.signedIn
                iconText: "󰍂"
                tooltipText: "Sign in"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.login()
              }
              PanelActionButton {
                iconText: "󰕰"
                tooltipText: "Dashboard (d)"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.openDashboard()
              }
              PanelActionButton {
                iconText: root.loading ? "󰦖" : "󰑐"
                tooltipText: "Refresh (r)"
                foreground: root.foreground
                fontFamily: root.fontFamily
                onClicked: root.refresh()
              }
            }
          }

          // ---- Publish actions.
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Style.space(8)

            Repeater {
              model: [
                { what: "folder", icon: "", label: "Folder" },
                { what: "file", icon: "", label: "File" },
                { what: "clipboard", icon: "", label: "Clipboard" }
              ]

              Rectangle {
                required property var modelData
                width: Style.space(132)
                height: publishLabel.implicitHeight + Style.space(14)
                radius: Style.cornerRadius
                color: publishArea.containsMouse ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"
                border.width: Math.max(1, Style.spacing.hairline)
                border.color: Qt.rgba(root.foreground.r, root.foreground.g, root.foreground.b, 0.18)
                opacity: root.publishing ? 0.5 : 1

                Text {
                  id: publishLabel
                  anchors.centerIn: parent
                  textFormat: Text.PlainText
                  text: modelData.icon + "  " + modelData.label
                  color: publishArea.containsMouse ? Style.hoverStateColor(root.foreground, Color.accent) : root.foreground
                  font.family: root.fontFamily
                  font.pixelSize: Style.font.body
                }

                MouseArea {
                  id: publishArea
                  anchors.fill: parent
                  hoverEnabled: true
                  enabled: !root.publishing
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.publish(modelData.what)
                }
              }
            }
          }

          PanelSeparator {
            width: parent.width
            foreground: root.foreground
          }

          PanelSectionHeader {
            text: root.signedIn ? "YOUR SPACES" : "RECENT PUBLISHES"
            foreground: root.foreground
            fontFamily: root.fontFamily
            leftPadding: Style.space(6)
          }

          Text {
            visible: root.loadedOnce && root.spaces.length === 0
            width: parent.width
            leftPadding: Style.space(6)
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: root.signedIn
              ? "Nothing published yet. Publish a folder, a file, or the clipboard above."
              : "Nothing published yet. Publishing needs no account: you get a private link, and signing in keeps it and lets you share it."
            color: root.dim
            font.family: root.fontFamily
            font.pixelSize: Style.font.bodySmall
          }

          // ---- Space rows.
          Column {
            width: parent.width
            spacing: 0

            Repeater {
              model: root.spaces

              Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property bool selected: index === root.selectedIndex
                width: parent.width
                height: rowContent.implicitHeight + Style.space(12)
                radius: Style.cornerRadius
                color: selected ? Style.hoverFillFor(root.foreground, Color.accent) : "transparent"

                Row {
                  id: rowContent
                  anchors.left: parent.left
                  anchors.leftMargin: Style.space(6)
                  anchors.right: rowButtons.left
                  anchors.rightMargin: Style.space(6)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(10)

                  Text {
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: Model.glyph(row.modelData)
                    color: row.selected ? Style.hoverStateColor(root.foreground, Color.accent) : root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.body
                  }

                  Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Style.space(30)
                    spacing: Style.space(1)

                    Text {
                      width: parent.width
                      elide: Text.ElideRight
                      textFormat: Text.PlainText
                      text: row.modelData.title || row.modelData.id
                      color: row.selected ? Style.hoverStateColor(root.foreground, Color.accent) : root.foreground
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.body
                    }
                    Text {
                      width: parent.width
                      elide: Text.ElideMiddle
                      textFormat: Text.PlainText
                      text: Model.hostOf(row.modelData.liveUrl) + "  ·  " + Model.detail(row.modelData, root.now)
                      color: Model.urgent(row.modelData, root.now) ? Color.urgent : root.dim
                      font.family: root.fontFamily
                      font.pixelSize: Style.font.caption
                    }
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onPositionChanged: root.selectedIndex = row.index
                  onClicked: {
                    root.selectedIndex = row.index
                    root.openSelected()
                  }
                }

                Row {
                  id: rowButtons
                  anchors.right: parent.right
                  anchors.rightMargin: Style.space(4)
                  anchors.verticalCenter: parent.verticalCenter
                  spacing: Style.space(2)
                  visible: row.selected

                  PanelActionButton {
                    visible: row.modelData.anonymous === true
                    iconText: "󰆼"
                    tooltipText: "Claim to keep and share (a)"
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: { root.selectedIndex = row.index; root.claimSelected() }
                  }
                  PanelActionButton {
                    iconText: "󰆏"
                    tooltipText: row.modelData.anonymous ? "Copy private preview (c)" : "Copy share link (c)"
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: { root.selectedIndex = row.index; root.copySelected() }
                  }
                  PanelActionButton {
                    iconText: "󰏌"
                    tooltipText: "Open (enter)"
                    foreground: root.foreground
                    fontFamily: root.fontFamily
                    onClicked: { root.selectedIndex = row.index; root.openSelected() }
                  }
                }
              }
            }
          }

          Text {
            width: parent.width
            leftPadding: Style.space(6)
            topPadding: Style.space(4)
            wrapMode: Text.WordWrap
            textFormat: Text.PlainText
            text: "enter open · c copy link · a claim · d dashboard · r refresh"
            color: Qt.darker(root.foreground, 1.8)
            font.family: root.fontFamily
            font.pixelSize: Style.font.caption
          }
        }
      }
    }
  }
}
