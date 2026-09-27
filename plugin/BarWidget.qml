import QtQuick
import qs.Commons
import qs.Ui

// Bar button for Spacefast. Left click opens the panel, right click publishes
// a folder, middle click refreshes. The panel (Panel.qml) owns all state.
BarWidget {
  id: root
  moduleName: "spacefast.spaces"

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  function refresh() {
    if (panelLoader.item && panelLoader.item.refresh) panelLoader.item.refresh()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  // Shape contract for shell.summon/hide/toggle routing: the bar looks for
  // open/close/opened on the bar-widget root.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item && panelLoader.item.openFromHotkey) panelLoader.item.openFromHotkey()
  }

  function close() {
    if (panelLoader.item && panelLoader.item.close) panelLoader.item.close()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Component {
    id: markComponent
    Item {
      SpacefastIcon {
        anchors.centerIn: parent
        iconSize: Style.bar.iconCanvas
        color: button.foreground
        accent: root.setting("brandAccent", true) !== false
      }
    }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    // The SF mark normally; an hourglass glyph while a publish is running.
    readonly property bool publishing: panelLoader.item ? panelLoader.item.publishing === true : false
    text: publishing ? "󰔟" : ""
    iconComponent: publishing ? null : markComponent
    slotSize: Style.bar.statusSlot
    tooltipText: panelLoader.item ? panelLoader.item.tooltip : "Spacefast"

    onPressed: function(b) {
      if (!root.bar) return
      if (b === Qt.RightButton) {
        if (panelLoader.item) panelLoader.item.publish("folder")
      } else if (b === Qt.MiddleButton) {
        root.refresh()
      } else {
        root.togglePanel()
      }
    }
  }
}
