import QtQuick
import qs.Commons as Commons
import qs.Ui as Ui

Ui.BarWidget {
  id: root
  moduleName: "io.github.lightjunction.project-bees"

  readonly property var locale: Qt.locale(Commons.I18n.formatLocale)
  readonly property string amount: Stats.snapshot ? Stats.format(Stats.snapshot.totalBytes, locale) : ""

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
    text: root.vertical || !root.amount ? "󰘬" : "⑂  " + root.amount
    tooltipText: root.amount ? strings.t("total") + " · " + root.amount
      : strings.t(Stats.error || "noData")
    onPressed: function(button) {
      if (button === Qt.LeftButton && root.bar && root.bar.shell)
        root.bar.shell.toggle(root.moduleName, "")
    }
  }
}
