import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui
import "I18n.js" as I18n

// Widget de barra para la cola de impresion de CUPS.
//   click -> abre el panel con los trabajos pendientes
// Oculto mientras la cola este vacia; aparece en cuanto se envia a imprimir.
Panel {
  id: root
  moduleName: "frank3e.print-queue"
  ipcTarget: "frank3e.print-queue"
  manageIpc: false

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  visible: service.count > 0 || opened

  readonly property string heroMeta: service.count === 0
    ? I18n.t("queue.empty", service.localeName)
    : I18n.tn("queue.pendingOne", "queue.pendingMany", service.count, service.localeName)

  readonly property string barTooltip: I18n.t("queue.title", service.localeName) + " \u2014 " + heroMeta

  function fmtSize(bytes) {
    var b = Number(bytes || 0)
    if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB"
    if (b >= 1024) return Math.round(b / 1024) + " KB"
    return b + " B"
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  onOpenedChanged: if (opened) service.refresh()

  Service {
    id: service
    settings: root.settings
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    function refresh(): void { service.refresh() }
    function debug(): string {
      return "locale=" + service.localeName + " lang=" + I18n.langOf(service.localeName)
        + " title=" + I18n.t("queue.title", service.localeName)
        + " count=" + service.count + " visible=" + root.visible
    }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: service.count > 0 ? "\uf02f " + service.count : ""
    fontSize: Style.font.caption
    horizontalMargin: 6
    tooltipText: root.barTooltip
    onPressed: function() { root.toggle() }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(360))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(520))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === "r" || t === "R") service.refresh()
      }

      Column {
        id: column
        anchors.fill: parent
        spacing: Style.space(12)

        PanelHero {
          width: parent.width
          title: I18n.t("queue.title", service.localeName)
          meta: root.heroMeta
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconComponent: Component {
            Text {
              textFormat: Text.PlainText
              text: ""
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        Text {
          textFormat: Text.PlainText
          visible: service.actionStatus !== "" || service.lastError !== ""
          width: parent.width
          text: service.lastError !== "" ? service.lastError : service.actionStatus
          color: service.lastError !== "" ? root.urgent : root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }

        Text {
          textFormat: Text.PlainText
          visible: service.count === 0
          width: parent.width
          text: I18n.t("queue.noJobs", service.localeName)
          color: root.dim
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
        }

        Flickable {
          id: listFlick
          visible: service.count > 0
          width: parent.width
          height: Math.min(contentHeight, Style.space(300))
          contentHeight: rows.implicitHeight
          clip: true
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: rows
            width: listFlick.width
            spacing: Style.space(10)

            Repeater {
              model: service.jobs

              delegate: Item {
                required property var modelData
                width: rows.width
                height: jobLabels.implicitHeight

                Column {
                  id: jobLabels
                  width: parent.width - cancelJob.implicitWidth - Style.space(10)
                  spacing: 2

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: modelData.printer + (modelData.job ? "  \u00b7  #" + modelData.job : "")
                    color: root.foreground
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.bodySmall
                    font.bold: true
                    elide: Text.ElideRight
                  }

                  Text {
                    textFormat: Text.PlainText
                    width: parent.width
                    text: modelData.stamp + (Number(modelData.size) > 0 ? "  \u00b7  " + root.fmtSize(modelData.size) : "")
                    color: root.dim
                    font.family: root.fontFamily
                    font.pixelSize: Style.font.caption
                    elide: Text.ElideRight
                  }
                }

                Button {
                  id: cancelJob
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  text: I18n.t("job.cancel", service.localeName)
                  fontSize: Style.font.caption
                  bordered: true
                  foreground: root.foreground
                  fontFamily: root.fontFamily
                  enabled: !service.busy
                  tooltipText: I18n.t("job.cancelTip", service.localeName)
                  onClicked: service.cancelJob(modelData.id)
                }
              }
            }
          }
        }

        PanelSeparator {
          foreground: root.foreground
        }

        Row {
          width: parent.width
          spacing: Style.space(8)

          Button {
            width: (parent.width - parent.spacing) / 2
            text: I18n.t("job.cancelAll", service.localeName)
            iconText: "󰅖"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: service.count > 0 && !service.busy
            onClicked: service.cancelAll()
            tooltipText: I18n.t("job.cancelAllTip", service.localeName)
          }

          Button {
            width: (parent.width - parent.spacing) / 2
            text: I18n.t("job.refresh", service.localeName)
            iconText: "󰑓"
            iconSpinning: service.busy
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            enabled: !service.busy
            onClicked: service.refresh()
          }
        }
      }
    }
  }
}
