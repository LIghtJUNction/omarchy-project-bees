pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons as Commons

Item {
  id: root

  readonly property string home: Quickshell.env("HOME")
  readonly property string configuredStateHome: Quickshell.env("XDG_STATE_HOME") || ""
  readonly property string stateHome: configuredStateHome.startsWith("/") ? configuredStateHome : home + "/.local/state"
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
    interval: 10000
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

  // Activity is optional and must never hide valid historical totals.
  function activity(report) {
    const value = report ? report.activity : null
    if (value === null || typeof value !== "object" || Array.isArray(value)
      || !["scanning", "deduplicating", "idle", "stopped"].includes(value.phase)) return null

    const counters = ["phaseStartedAt", "repositories", "scannedFiles", "hashedFiles", "indexedChunks",
      "processedFiles", "matchedRanges", "rejectedRanges", "nextScanAt"]
    if (!counters.every(key => validNumber(value[key]))) return null
    if (value.phase === "idle" && (value.nextScanAt === 0
      || !isFinite(new Date(value.nextScanAt * 1000).getTime()))) return null
    return value
  }

  function scanKind(report) {
    const value = activity(report)
    return value && ["priority", "full"].includes(value.scanKind) ? value.scanKind : ""
  }

  function scanRoot(report) {
    const value = activity(report)
    return value && typeof value.scanRoot === "string" ? value.scanRoot : ""
  }

  // Optional live records must not invalidate the cumulative statistics.
  function events(report) {
    if (!report || !Array.isArray(report.recentEvents)) return []
    return report.recentEvents.slice(-32).filter(row => row !== null
      && typeof row === "object" && typeof row.source === "string"
      && typeof row.destination === "string" && validNumber(row.at) && row.at > 0
      && Math.floor(row.at) === row.at && isFinite(new Date(row.at * 1000).getTime())
      && validNumber(row.bytes) && row.bytes > 0 && Math.floor(row.bytes) === row.bytes).reverse()
  }

  function duration(seconds) {
    const total = Math.max(0, Math.floor(Number(seconds) || 0))
    const hours = Math.floor(total / 3600)
    const minutes = Math.floor(total / 60) % 60
    const remaining = total % 60
    const two = value => (value < 10 ? "0" : "") + value
    return (hours ? two(hours) + ":" : "") + two(minutes) + ":" + two(remaining)
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
