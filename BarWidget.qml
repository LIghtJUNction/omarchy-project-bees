import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.lightjunction.project-bees"

  readonly property string amount: Stats.snapshot ? Stats.format(Stats.snapshot.totalBytes) : ""

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  Ui.WidgetButton {
    id: button
    objectName: "barButton"
    anchors.fill: parent
    bar: root.bar
    text: root.amount
    labelVisible: false
    hasVisualContent: true
    fixedWidth: root.vertical ? -1 : mark.implicitWidth + scaledHorizontalMargin * 2
    fixedHeight: root.vertical ? mark.implicitHeight + scaledVerticalPadding * 2 : -1

    Row {
      id: mark
      anchors.centerIn: parent
      spacing: 6
      scale: button.pressScale

      Image {
        width: Math.max(22, Commons.Style.bar.iconSize * 1.5)
        height: Math.max(14, Commons.Style.bar.iconSize)
        anchors.verticalCenter: parent.verticalCenter
        source: Qt.resolvedUrl("assets/logo.svg")
        sourceSize.width: 64
        sourceSize.height: 40
        fillMode: Image.PreserveAspectFit
        Accessible.ignored: true
      }
      Text {
        visible: !root.vertical && root.amount !== ""
        anchors.verticalCenter: parent.verticalCenter
        text: "\u2066" + root.amount + "\u2069"
        textFormat: Text.PlainText
        color: button.foreground
        font.family: button.fontFamily
        font.pixelSize: button.fontSize
        renderType: Text.NativeRendering
      }
    }
    tooltipText: root.amount ? strings.t("total") + " · \u2066" + root.amount + "\u2069"
      : strings.t(Stats.error || "noData")
    onPressed: function(button) {
      if (button === Qt.LeftButton && root.bar && root.bar.shell)
        root.bar.shell.toggle(root.moduleName, "")
    }
  }
}
