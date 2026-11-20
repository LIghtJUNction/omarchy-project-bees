import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

Item {
  id: root

  property var shell: null
  property var manifest: null
  property bool opened: false

  function open() {
    Stats.reload()
    opened = true
  }

  function close() { opened = false }

  function dismiss() {
    if (shell) shell.hide("io.github.lightjunction.project-bees")
    else close()
  }

  Ui.OverlayWindow {
    id: overlay
    objectName: "overlay"
    shown: root.opened

    Rectangle {
      anchors.fill: parent
      color: Commons.Color.menu.scrim
      MouseArea {
        objectName: "scrim"
        anchors.fill: parent
        onClicked: root.dismiss()
      }
    }

    Dashboard {
      id: dashboard
      objectName: "dashboard"
      anchors.centerIn: parent
      width: Math.min(880, overlay.width - 32)
      height: Math.min(650, overlay.height - 32)
      snapshot: Stats.snapshot
      error: Stats.error
      onCloseRequested: root.dismiss()
    }

    onContentRevealedChanged: if (contentRevealed) dashboard.focusSearch()
  }
}
