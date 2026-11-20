import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.Commons as Commons

FocusScope {
  id: root

  property var snapshot: null
  property string error: ""
  property int tab: 0
  readonly property bool rightToLeft: Commons.I18n.rightToLeft
  readonly property var locale: Qt.locale(Commons.I18n.formatLocale)
  readonly property color accent: Commons.Color.accent
  readonly property color ink: Commons.Color.menu.text
  readonly property color dim: Qt.rgba(ink.r, ink.g, ink.b, 0.76)
  readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.12)
  readonly property color hoverFill: Qt.rgba(ink.r, ink.g, ink.b, 0.05)
  readonly property int radius: Commons.Style.cornerRadius
  readonly property int controlRadius: Math.min(6, radius)
  readonly property string mono: Commons.Style.font.menuFamily
  readonly property int bodySize: Math.max(14, Commons.Style.font.body)
  readonly property int smallSize: Math.max(12, Commons.Style.font.bodySmall)
  readonly property var projects: snapshot ? snapshot.projects : []
  readonly property var pairs: snapshot ? snapshot.pairs : []
  readonly property var total: Stats.size(snapshot ? snapshot.totalBytes : 0)
  readonly property var rows: filteredRows()
  readonly property var activity: Stats.activity(snapshot)
  property double nowSeconds: Date.now() / 1000
  readonly property bool activityStale: activity !== null && activity.phase !== "stopped"
    && nowSeconds > Math.max(snapshot.updatedAt + 180,
      activity.phase === "idle" ? activity.nextScanAt + 120 : 0)
  signal closeRequested()

  LayoutMirroring.enabled: rightToLeft
  LayoutMirroring.childrenInherit: true

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  Timer {
    interval: 15000
    repeat: true
    running: root.visible && root.snapshot !== null
    onTriggered: root.nowSeconds = Date.now() / 1000
  }

  onSnapshotChanged: nowSeconds = Date.now() / 1000
  onVisibleChanged: if (visible) nowSeconds = Date.now() / 1000

  function focusSearch() { search.forceActiveFocus() }

  function activityText() {
    if (!activity) return strings.t("activityUnavailable")
    if (activityStale) return strings.t("activityStale").arg(Commons.I18n.formatNumber(
      Math.max(1, Math.floor((nowSeconds - snapshot.updatedAt) / 60)), 0))
    switch (activity.phase) {
    case "scanning":
      return strings.t("activityScanning")
        .arg(Commons.I18n.formatNumber(activity.hashedFiles, 0))
        .arg(Commons.I18n.formatNumber(activity.indexedChunks, 0))
    case "deduplicating":
      return strings.t("activityDeduplicating")
        .arg(Commons.I18n.formatNumber(activity.processedFiles, 0))
        .arg(Commons.I18n.formatNumber(activity.matchedRanges, 0))
    case "idle":
      return strings.t("activityIdle").arg(new Date(activity.nextScanAt * 1000)
        .toLocaleTimeString(locale, "HH:mm"))
    case "stopped":
      return strings.t("activityStopped")
    }
    return strings.t("activityUnavailable")
  }

  function filteredRows() {
    const source = tab === 0 ? projects : pairs
    const query = search ? search.text.trim().toLowerCase() : ""
    if (!query) return source
    return source.filter(row => (tab === 0 ? row.path : row.a + " " + row.b).toLowerCase().includes(query))
  }

  function caption(path) {
    return Stats.home && path.startsWith(Stats.home + "/") ? "~" + path.slice(Stats.home.length) : path
  }

  function leaf(path) {
    const name = path.slice(path.lastIndexOf("/") + 1)
    return name || path
  }

  function ltr(text) { return "\u2066" + text + "\u2069" }

  Keys.onEscapePressed: root.closeRequested()
  onRowsChanged: if (list) list.positionViewAtBeginning()

  Rectangle {
    anchors.fill: parent
    radius: root.radius
    color: Commons.Color.menu.background
    border.color: root.line

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }
  }

  component Label: Text {
    color: root.ink
    font.family: root.mono
    font.pixelSize: root.bodySize
    textFormat: Text.PlainText
  }

  component Tab: Controls.AbstractButton {
    id: tabButton
    required property int index
    readonly property bool selected: root.tab === index
    leftPadding: 12
    rightPadding: 12
    topPadding: 9
    bottomPadding: 11
    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: Math.max(38, contentItem.implicitHeight + topPadding + bottomPadding)
    hoverEnabled: true
    onClicked: root.tab = index
    background: Rectangle {
      radius: root.controlRadius
      color: tabButton.hovered ? root.hoverFill : "transparent"
      border.color: tabButton.activeFocus ? root.accent : "transparent"
      Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: 2
        visible: tabButton.selected
        color: root.accent
      }
    }
    contentItem: Label {
      text: tabButton.text
      color: tabButton.selected ? root.ink : root.dim
      font.weight: tabButton.selected ? Font.DemiBold : Font.Normal
      wrapMode: Text.WordWrap
      verticalAlignment: Text.AlignVCenter
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: root.width < 620 ? 22 : 32
    spacing: 18

    RowLayout {
      spacing: 10
      Layout.fillWidth: true

      Label {
        text: "⑂"
        color: root.accent
        font.pixelSize: Math.max(20, Commons.Style.font.heading)
      }
      Label {
        text: "Project Bees"
        font.weight: Font.DemiBold
        font.pixelSize: Math.max(17, Commons.Style.font.heading)
      }
      Item { Layout.fillWidth: true }
      Controls.AbstractButton {
        objectName: "closeButton"
        implicitWidth: 32
        implicitHeight: 32
        hoverEnabled: true
        Accessible.name: strings.t("close")
        onClicked: root.closeRequested()
        background: Rectangle {
          radius: root.controlRadius
          color: parent.hovered || parent.activeFocus ? root.hoverFill : "transparent"
          border.color: parent.activeFocus ? root.accent : "transparent"
        }
        contentItem: Label {
          text: "×"
          horizontalAlignment: Text.AlignHCenter
          verticalAlignment: Text.AlignVCenter
          color: root.dim
          font.pixelSize: Math.max(22, Commons.Style.font.display)
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      Layout.topMargin: 8
      Layout.bottomMargin: 8
      spacing: 32

      ColumnLayout {
        Layout.fillWidth: true
        Layout.minimumWidth: 180
        spacing: 5
        Label {
          Layout.fillWidth: true
          text: strings.t("total")
          color: root.dim
          wrapMode: Text.WordWrap
        }
        RowLayout {
          LayoutMirroring.enabled: false
          LayoutMirroring.childrenInherit: true
          spacing: 8
          Label {
            objectName: "totalAmount"
            text: root.snapshot ? root.total.number : "—"
            color: root.accent
            font.pixelSize: Math.max(root.width < 620 ? 40 : 52,
              Math.round(Commons.Style.font.displayLarge * (root.width < 620 ? 1.4 : 1.9)))
            font.weight: Font.DemiBold
          }
          Label {
            visible: root.snapshot !== null
            text: root.total.unit
            color: root.accent
            Layout.alignment: Qt.AlignBottom
            Layout.bottomMargin: 8
            font.pixelSize: Math.max(18, Commons.Style.font.heading)
          }
        }
        Label {
          Layout.fillWidth: true
          visible: root.snapshot !== null
          text: root.snapshot ? strings.t("since").arg(new Date(root.snapshot.startedAt * 1000)
            .toLocaleDateString(root.locale, "yyyy-MM-dd")) : ""
          color: root.dim
          font.pixelSize: root.smallSize
          wrapMode: Text.WordWrap
        }
      }

      RowLayout {
        visible: root.snapshot !== null && root.width > 620
        Layout.preferredWidth: 260
        Layout.maximumWidth: 260
        Layout.alignment: Qt.AlignVCenter
        spacing: 28
        Repeater {
          model: [
            { name: strings.t("repos"), count: root.projects.length },
            { name: strings.t("pairs"), count: root.pairs.length },
          ]
          delegate: ColumnLayout {
            required property var modelData
            Layout.fillWidth: true
            Layout.preferredWidth: 116
            Layout.alignment: Qt.AlignTop
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            spacing: 6
            Label {
              Layout.fillWidth: true
              horizontalAlignment: root.rightToLeft ? Text.AlignRight : Text.AlignLeft
              text: Commons.I18n.formatNumber(modelData.count, 0)
              font.pixelSize: Math.max(30, Commons.Style.font.displayLarge)
              font.weight: Font.DemiBold
            }
            Label {
              Layout.fillWidth: true
              horizontalAlignment: root.rightToLeft ? Text.AlignRight : Text.AlignLeft
              text: modelData.name
              color: root.dim
              font.pixelSize: root.smallSize
              wrapMode: Text.WordWrap
            }
          }
        }
      }
    }

    ColumnLayout {
      id: filters
      Layout.fillWidth: true
      spacing: 8
      Label {
        objectName: "activityStatus"
        Layout.fillWidth: true
        visible: root.snapshot !== null
        text: root.activityText()
        color: root.dim
        font.pixelSize: root.smallSize
        wrapMode: Text.WordWrap
      }
      RowLayout {
        Layout.fillWidth: true
        spacing: 8
        Tab {
          objectName: "projectsTab"
          Layout.maximumWidth: (filters.width - 8) / 2
          index: 0
          text: strings.t("repos")
        }
        Tab {
          objectName: "pairsTab"
          Layout.maximumWidth: (filters.width - 8) / 2
          index: 1
          text: strings.t("pairs")
        }
        Item { Layout.fillWidth: true }
      }
      Controls.TextField {
        id: search
        objectName: "search"
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(42, root.bodySize + 26)
        LayoutMirroring.enabled: false
        LayoutMirroring.childrenInherit: true
        horizontalAlignment: text.length > 0 || !root.rightToLeft ? Text.AlignLeft : Text.AlignRight
        selectByMouse: true
        placeholderText: strings.t("search")
        placeholderTextColor: root.dim
        color: root.ink
        selectionColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
        selectedTextColor: root.ink
        font.family: root.mono
        font.pixelSize: root.bodySize
        leftPadding: 12
        rightPadding: 12
        background: Rectangle {
          color: root.hoverFill
          radius: root.controlRadius
          Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: search.activeFocus ? 2 : 1
            color: search.activeFocus ? root.accent : root.line
          }
        }
      }
    }

    ListView {
      id: list
      objectName: "results"
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 2
      model: root.rows
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

      delegate: Rectangle {
        id: entry
        required property var modelData
        readonly property bool isPair: row.a !== undefined
        readonly property var row: modelData
        width: list.width - 8
        height: Math.max(64, root.bodySize + root.smallSize + 30)
        radius: root.controlRadius
        color: hover.hovered ? root.hoverFill : "transparent"

        HoverHandler { id: hover }
        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: 4
          anchors.rightMargin: 4
          anchors.topMargin: 10
          anchors.bottomMargin: 10
          spacing: 24

          ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 100
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            spacing: 6
            Label {
              Layout.fillWidth: true
              horizontalAlignment: root.rightToLeft ? Text.AlignRight : Text.AlignLeft
              elide: Text.ElideMiddle
              font.weight: Font.DemiBold
              font.pixelSize: Math.max(15, Commons.Style.font.subtitle)
              text: entry.isPair ? root.ltr(root.ltr(root.leaf(entry.row.a)) + "  ↔  " + root.ltr(root.leaf(entry.row.b)))
                : root.ltr(root.leaf(entry.row.path))
            }
            Label {
              Layout.fillWidth: true
              horizontalAlignment: root.rightToLeft ? Text.AlignRight : Text.AlignLeft
              elide: Text.ElideMiddle
              color: root.dim
              font.pixelSize: root.smallSize
              text: entry.isPair ? root.ltr(root.ltr(root.caption(entry.row.a)) + "  ↔  " + root.ltr(root.caption(entry.row.b)))
                : root.ltr(root.caption(entry.row.path))
            }
          }

          ColumnLayout {
            Layout.maximumWidth: list.width * 0.42
            LayoutMirroring.enabled: false
            LayoutMirroring.childrenInherit: true
            spacing: 6
            Label {
              Layout.fillWidth: true
              horizontalAlignment: root.rightToLeft ? Text.AlignLeft : Text.AlignRight
              color: entry.row.bytes > 0 ? root.ink : root.dim
              font.pixelSize: Math.max(17, Commons.Style.font.heading)
              font.weight: entry.row.bytes > 0 ? Font.DemiBold : Font.Normal
              text: root.ltr(Stats.format(entry.row.bytes))
            }
            Label {
              Layout.fillWidth: true
              horizontalAlignment: root.rightToLeft ? Text.AlignLeft : Text.AlignRight
              visible: entry.isPair || entry.row.sourceBytes > 0
              color: root.dim
              font.pixelSize: root.smallSize
              elide: Text.ElideRight
              text: entry.isPair ?
                root.ltr("← " + Stats.format(entry.row.toA) + "  ·  " +
                  Stats.format(entry.row.bytes - entry.row.toA) + " →") :
                strings.t("supplied").arg(root.ltr(Stats.format(entry.row.sourceBytes)))
            }
          }
        }
      }

      Label {
        objectName: "emptyState"
        anchors.centerIn: parent
        visible: root.rows.length === 0
        width: Math.max(0, parent.width - 14)
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: root.dim
        text: !root.snapshot ? strings.t(root.error || "noData")
          : search.text.trim() ? strings.t("noMatch")
          : root.tab === 0 ? strings.t("noRepos") : strings.t("noPairs")
      }
    }

    RowLayout {
      Layout.fillWidth: true
      visible: root.height > 485
      spacing: 16
      Label {
        Layout.fillWidth: true
        text: root.snapshot ? strings.t("clock").arg(new Date(root.snapshot.updatedAt * 1000)
          .toLocaleTimeString(root.locale, "HH:mm")) : ""
        color: root.dim
        font.pixelSize: root.smallSize
        elide: Text.ElideRight
      }
      Label {
        color: root.dim
        font.pixelSize: root.smallSize
        text: strings.t("dismiss")
      }
    }
  }
}
