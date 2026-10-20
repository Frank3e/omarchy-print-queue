import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import "I18n.js" as I18n

// Backend del widget de cola de impresion: lee los trabajos pendientes de
// CUPS con lpstat y los cancela con cancel.
Item {
  id: root

  property var settings: ({})

  property var jobs: []
  property int count: 0
  property bool refreshing: false
  property string actionStatus: ""
  property string lastError: ""

  readonly property string localeName: Qt.locale().name
  readonly property int refreshIntervalSec: intSetting("refreshIntervalSec", 3, 2, 300)
  readonly property bool busy: statusProcess.running || cancelProcess.running
  readonly property string statusScript: Qt.resolvedUrl("print-queue.sh").toString().replace(/^file:\/\//, "")

  function setting(name, fallback) {
    var value = settings ? settings[name] : undefined
    return value === undefined || value === null ? fallback : value
  }

  function intSetting(name, fallback, min, max) {
    var n = parseInt(String(setting(name, fallback)), 10)
    if (!isFinite(n)) n = fallback
    if (n < min) n = min
    if (n > max) n = max
    return n
  }

  function refresh() {
    if (statusProcess.running) return
    refreshing = true
    statusProcess.running = true
  }

  function applyStatus(raw) {
    var parsed = null
    try { parsed = JSON.parse(String(raw || "")) } catch (e) { parsed = null }
    if (!parsed || parsed.ok !== true) {
      lastError = String((parsed && parsed.error) || I18n.t("err.readQueue", localeName))
      return
    }
    jobs = Array.isArray(parsed.jobs) ? parsed.jobs : []
    count = Number(parsed.count || jobs.length)
    lastError = ""
  }

  function cancelJob(id) {
    if (cancelProcess.running || !id) return
    actionStatus = I18n.t("status.cancellingJob", localeName)
    cancelProcess.command = ["cancel", String(id)]
    cancelProcess.running = true
  }

  function cancelAll() {
    if (cancelProcess.running || count === 0) return
    actionStatus = I18n.t("status.cancellingAll", localeName)
    cancelProcess.command = ["cancel", "-a"]
    cancelProcess.running = true
  }

  Timer {
    id: refreshTimer
    interval: root.refreshIntervalSec * 1000
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  Timer {
    id: actionStatusTimer
    interval: 2500
    repeat: false
    onTriggered: root.actionStatus = ""
  }

  Timer {
    // Tras un cancel la cola tarda un momento en reflejarse, asi que
    // reconsultamos unas cuantas veces en vez de esperar al refresco periodico.
    id: settleTimer
    property int ticks: 0
    interval: 800
    repeat: true
    running: false
    onTriggered: {
      settleTimer.ticks += 1
      root.refresh()
      if (settleTimer.ticks >= 5) {
        settleTimer.ticks = 0
        settleTimer.running = false
      }
    }
  }

  Process {
    id: statusProcess
    running: false
    command: ["bash", root.statusScript]
    stdout: StdioCollector {
      id: statusStdout
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: statusStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      root.refreshing = false
      var stdout = String(statusStdout.text || "")
      var stderr = String(statusStderr.text || "")
      if (exitCode === 0) root.applyStatus(stdout)
      else root.lastError = String(stderr || I18n.t("err.readQueue", root.localeName)).trim()
    }
  }

  Process {
    id: cancelProcess
    running: false
    command: []
    stdout: StdioCollector {
      waitForEnd: true
    }
    stderr: StdioCollector {
      id: cancelStderr
      waitForEnd: true
    }
    onExited: function(exitCode) {
      if (exitCode !== 0) {
        var stderr = String(cancelStderr.text || "").trim()
        root.lastError = stderr !== "" ? stderr : I18n.t("err.cancelFailed", root.localeName)
        root.actionStatus = ""
      } else {
        root.lastError = ""
        actionStatusTimer.restart()
      }
      settleTimer.ticks = 0
      settleTimer.running = true
      root.refresh()
    }
  }
}
