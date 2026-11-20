pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME") || home + "/.local/state"
  property var snapshot: null
  property string error: ""

  FileView {
    id: view
    path: root.stateHome + "/project-bees/stats.json"
    printErrors: false
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      try {
        const report = JSON.parse(text())
        if (root.validReport(report)) {
          root.snapshot = report
          root.error = ""
        } else {
          root.snapshot = null
          root.error = "invalidData"
        }
      } catch (_) {
        root.snapshot = null
        root.error = "invalidData"
      }
    }
    onLoadFailed: function(error) {
      root.snapshot = null
      root.error = error === FileViewError.FileNotFound ? "" : "readError"
    }
  }

  Timer {
    interval: 30000
    repeat: true
    running: true
    onTriggered: root.reload()
  }

  function reload() { view.reload() }

  function validNumber(value) {
    return typeof value === "number" && isFinite(value) && value >= 0
  }

  function validReport(report) {
    return report !== null && typeof report === "object" && report.version === 1
      && validNumber(report.totalBytes) && validNumber(report.startedAt) && validNumber(report.updatedAt)
      && Array.isArray(report.projects) && report.projects.every(row => row !== null
        && typeof row.path === "string" && validNumber(row.bytes) && validNumber(row.sourceBytes))
      && Array.isArray(report.pairs) && report.pairs.every(row => row !== null
        && typeof row.a === "string" && typeof row.b === "string"
        && validNumber(row.bytes) && validNumber(row.toA) && row.toA <= row.bytes)
  }

  function size(bytes) {
    const units = ["B", "KiB", "MiB", "GiB", "TiB", "PiB"]
    let value = Math.max(0, Number(bytes) || 0)
    let unit = 0
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024
      unit++
    }
    const decimals = unit === 0 ? 0 : (value < 10 ? 2 : 1)
    return { number: Commons.I18n.formatNumber(value, decimals), unit: units[unit] }
  }

  function format(bytes) {
    const value = size(bytes)
    return value.number + " " + value.unit
  }
}
