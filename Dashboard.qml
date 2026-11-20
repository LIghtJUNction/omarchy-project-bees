import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import qs.Commons as Commons

FocusScope {
  id: root

  property var snapshot: null
  property string error: ""
  property int tab: 0
  readonly property var locale: Qt.locale(Commons.I18n.formatLocale)
  readonly property color accent: Commons.Color.accent
  readonly property color dim: Commons.Color.muted
  readonly property color ink: Commons.Color.menu.text
  readonly property color line: Qt.rgba(ink.r, ink.g, ink.b, 0.16)
  readonly property color hoverFill: Qt.rgba(ink.r, ink.g, ink.b, 0.05)
  readonly property int radius: Commons.Style.cornerRadius
  readonly property int controlRadius: Math.min(6, radius)
  readonly property string mono: Commons.Style.font.menuFamily
  readonly property var projects: snapshot ? snapshot.projects : []
  readonly property var pairs: snapshot ? snapshot.pairs : []
  readonly property var total: Stats.size(snapshot ? snapshot.totalBytes : 0, locale)
  readonly property var rows: filteredRows()
  readonly property real maxBytes: rows.length ? Math.max(1, rows[0].bytes) : 1
  signal closeRequested()

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  function focusSearch() { search.forceActiveFocus() }

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
    font.pixelSize: 13
    textFormat: Text.PlainText
  }

  component Tab: Controls.AbstractButton {
    required property int index
    readonly property bool selected: root.tab === index
    leftPadding: 13
    rightPadding: 13
    implicitHeight: 34
    hoverEnabled: true
    onClicked: root.tab = index
    background: Rectangle {
      radius: root.controlRadius
      color: parent.selected ? Commons.Color.menu.selectedBackground : (parent.hovered ? root.hoverFill : "transparent")
      border.color: parent.activeFocus ? root.accent : "transparent"
    }
    contentItem: Label {
      text: parent.text
      color: parent.selected ? Commons.Color.menu.selectedText : root.dim
      verticalAlignment: Text.AlignVCenter
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 26
    spacing: 18

    RowLayout {
      spacing: 9
      Layout.fillWidth: true

      Label {
        text: "⑂"
        color: root.accent
        font.pixelSize: 19
      }
      Label {
        text: "PROJECT BEES"
        font.bold: true
        font.letterSpacing: 1.7
      }
      Item { Layout.fillWidth: true }
      Label {
        visible: root.snapshot !== null && root.width > 570
        text: root.snapshot ? strings.t("clock").arg(new Date(root.snapshot.updatedAt * 1000)
          .toLocaleTimeString(root.locale, "HH:mm")) : ""
        color: root.dim
        font.pixelSize: 11
      }
      Controls.AbstractButton {
        objectName: "closeButton"
        implicitWidth: 30
        implicitHeight: 28
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
          font.pixelSize: 21
        }
      }
    }

    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 132

      RowLayout {
        anchors.fill: parent
        spacing: 16

        ColumnLayout {
          Layout.fillWidth: true
          spacing: 3
          Label {
            text: strings.t("total")
            color: root.dim
            font.letterSpacing: 0.6
          }
          RowLayout {
            spacing: 8
            Label {
              objectName: "totalAmount"
              text: root.snapshot ? root.total.number : "—"
              color: root.accent
              font.pixelSize: root.width < 620 ? 36 : 48
              font.bold: true
            }
            Label {
              visible: root.snapshot !== null
              text: root.total.unit
              color: root.accent
              Layout.alignment: Qt.AlignBottom
              Layout.bottomMargin: 7
              font.pixelSize: 19
            }
          }
          Label {
            visible: root.snapshot !== null
            text: root.snapshot ? strings.t("since").arg(new Date(root.snapshot.startedAt * 1000)
              .toLocaleDateString(root.locale, "yyyy-MM-dd")) : ""
            color: root.dim
            font.pixelSize: 11
          }
        }

        ColumnLayout {
          visible: root.snapshot !== null && root.width > 490
          spacing: 8
          Repeater {
            model: [
              { name: strings.t("repos"), count: root.projects.length },
              { name: strings.t("pairs"), count: root.pairs.length },
            ]
            delegate: RowLayout {
              required property var modelData
              spacing: 13
              Label { text: modelData.name; color: root.dim; Layout.fillWidth: true }
              Label { text: modelData.count.toLocaleString(root.locale, "f", 0); font.bold: true }
            }
          }
        }
      }
    }

    RowLayout {
      Layout.fillWidth: true
      spacing: 5
      Tab { objectName: "projectsTab"; index: 0; text: strings.t("repos") }
      Tab { objectName: "pairsTab"; index: 1; text: strings.t("pairs") }
      Item { Layout.fillWidth: true }
      Controls.TextField {
        id: search
        objectName: "search"
        Layout.preferredWidth: Math.min(262, root.width * 0.42)
        Layout.preferredHeight: 34
        selectByMouse: true
        placeholderText: strings.t("search")
        placeholderTextColor: root.dim
        color: root.ink
        selectionColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.25)
        selectedTextColor: root.ink
        font.family: root.mono
        font.pixelSize: 12
        leftPadding: 10
        background: Rectangle {
          color: "transparent"
          border.color: parent.activeFocus ? root.accent : root.line
          radius: root.controlRadius
        }
      }
    }

    ListView {
      id: list
      objectName: "results"
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true
      spacing: 4
      model: root.rows
      boundsBehavior: Flickable.StopAtBounds
      Controls.ScrollBar.vertical: Controls.ScrollBar { policy: Controls.ScrollBar.AsNeeded }

      delegate: Rectangle {
        id: entry
        required property var modelData
        required property int index
        readonly property bool isPair: row.a !== undefined
        readonly property var row: modelData
        width: list.width - 8
        height: 53
        radius: root.controlRadius
        color: hover.hovered ? root.hoverFill : "transparent"

        HoverHandler { id: hover }
        RowLayout {
          anchors.fill: parent
          anchors.margins: 9
          spacing: 14

          ColumnLayout {
            Layout.fillWidth: true
            Layout.minimumWidth: 60
            spacing: 3
            Label {
              Layout.fillWidth: true
              elide: Text.ElideMiddle
              font.bold: true
              text: entry.isPair ? root.leaf(entry.row.a) + "  ↔  " + root.leaf(entry.row.b) : root.leaf(entry.row.path)
            }
            Label {
              Layout.fillWidth: true
              elide: Text.ElideMiddle
              color: root.dim
              font.pixelSize: 11
              text: entry.isPair ? root.caption(entry.row.a) + "  ↔  " + root.caption(entry.row.b) : root.caption(entry.row.path)
            }
          }

          Rectangle {
            visible: root.width > 620
            Layout.preferredWidth: 120
            Layout.preferredHeight: 4
            radius: Math.min(2, root.radius)
            color: root.line
            Rectangle {
              height: parent.height
              width: parent.width * (entry.row.bytes / root.maxBytes)
              radius: parent.radius
              color: root.accent
            }
          }

          ColumnLayout {
            spacing: 3
            Label {
              Layout.alignment: Qt.AlignRight
              color: entry.row.bytes > 0 ? root.accent : root.dim
              font.bold: entry.row.bytes > 0
              text: Stats.format(entry.row.bytes, root.locale)
            }
            Label {
              Layout.alignment: Qt.AlignRight
              visible: root.width > 620 && (entry.isPair || entry.row.sourceBytes > 0)
              color: root.dim
              font.pixelSize: 10
              text: entry.isPair ?
                "← " + Stats.format(entry.row.toA, root.locale) + "  |  " +
                  Stats.format(entry.row.bytes - entry.row.toA, root.locale) + " →" :
                strings.t("supplied").arg(Stats.format(entry.row.sourceBytes, root.locale))
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

    Label {
      visible: root.height > 485
      color: root.dim
      font.pixelSize: 11
      text: strings.t("dismiss")
    }
  }
}
