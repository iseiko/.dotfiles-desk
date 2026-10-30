import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import QtQuick

Scope {
  id: root
  required property var launcher
  required property var powerMenu

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var battery: UPower.displayDevice

  readonly property bool charging: battery.state === UPowerDeviceState.Charging
                                || battery.state === UPowerDeviceState.FullyCharged
  readonly property int batteryPercent: Math.round(battery.percentage * 100)
  readonly property int volumePercent: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
  readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

  // Audio properties only update while the node is tracked
  PwObjectTracker { objects: [ root.sink ] }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  // The base for the whole bar, its where all the modules are located
  PanelWindow {
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 40
    color: Theme.base

    // LEFT: launcher button + workspaces
    Row {
      anchors { left: parent.left; verticalCenter: parent.verticalCenter; leftMargin: 8 }
      spacing: 8

      Rectangle {
        width: 32; height: 28; radius: 8
        color: appMouse.containsMouse || root.launcher.open ? Theme.overlay : Theme.surface

        Text {
          anchors.centerIn: parent
          text: "󰀻"   // Nerd Font icon; use "Apps" if it shows a box
          color: Theme.accent
          font.pixelSize: 16
        }

        MouseArea {
          id: appMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.launcher.open = !root.launcher.open
        }
      }

      // Workspace row (NEED TO ADD CLICKABLE WORKSPACE BUTTON)
      Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
          model: 5   // workspaces 1-5

          delegate: Rectangle {
            required property int index
            readonly property int wsId: index + 1
            readonly property bool active: Hyprland.focusedWorkspace
                                        && Hyprland.focusedWorkspace.id === wsId

            width: 28; height: 28; radius: 8
            color: active ? Theme.accent : wsMouse.containsMouse ? Theme.overlay : Theme.surface

            Text {
              anchors.centerIn: parent
              text: parent.wsId
              color: parent.active ? Theme.base : Theme.text
              font.pixelSize: 14
              font.bold: parent.active
            }

            MouseArea {
              id: wsMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: Hyprland.dispatch("workspace " + parent.wsId)
            }
          }
        }
      }
    }

    // CENTER: time and date
    Row {
      anchors.centerIn: parent
      spacing: 12

      Text {
        text: Qt.formatDateTime(clock.date, "HH:mm")
        color: Theme.text
        font.pixelSize: 15
        font.bold: true
      }
      Text {
        text: Qt.formatDateTime(clock.date, "ddd, dd MMM")
        color: Theme.subtext
        font.pixelSize: 15
      }
    }

    // RIGHT: volume and battery
    Row {
      anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: 12 }
      spacing: 16

      // Volume: click = mute, scroll = change (NEED TO ADD ICON)
      Text {
        text: root.muted ? "Vol muted" : "Vol " + root.volumePercent + "%"
        color: root.muted ? Theme.muted : Theme.text
        font.pixelSize: 14

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: if (root.sink && root.sink.audio)
                       root.sink.audio.muted = !root.sink.audio.muted
          onWheel: wheel => {
            if (!root.sink || !root.sink.audio) return
            const step = wheel.angleDelta.y > 0 ? 0.05 : -0.05
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + step))
          }
        }
      }

      // Battery (NEED TO ADD ICON)
      Text {
        visible: root.battery.isPresent
        text: (root.charging ? "Bat+ " : "Bat ") + root.batteryPercent + "%"
        color: !root.charging && root.batteryPercent <= 20 ? Theme.danger
             : root.charging ? Theme.success : Theme.text
        font.pixelSize: 14
      }

      // Logout menu button
      Rectangle {
        width: 28; height: 28; radius: 8
        color: pwrMouse.containsMouse ? Theme.overlay : Theme.surface

        Text {
          anchors.centerIn: parent
          text: "󰐥"              // use "⏻" or "Off" if it shows a box
          color: Theme.danger
          font.pixelSize: 16
        }

        MouseArea {
          id: pwrMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.powerMenu.open = !root.powerMenu.open
        }
      }
    }
  }
}
