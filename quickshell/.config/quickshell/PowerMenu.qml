import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
  id: root
  property bool open: false
  property int currentIndex: 0

  // Display the options you can choose when pressing the power button
  readonly property var actions: [
    { label: "Lock",      icon: "󰌾", cmd: ["qs", "ipc", "call", "lock", "lock"] },
    { label: "Suspend",   icon: "󰤄", cmd: ["systemctl", "suspend"] },
    { label: "Hibernate", icon: "󰋊", cmd: ["systemctl", "hibernate"] },
    { label: "Reboot",    icon: "󰜉", cmd: ["systemctl", "soft-reboot"] },
    { label: "Shutdown",  icon: "󰐥", cmd: ["systemctl", "poweroff"] }
  ]

  function run(action) {
    root.open = false
    Quickshell.execDetached(action.cmd)
  }

  onOpenChanged: if (open) currentIndex = 0

  IpcHandler {
    target: "power"
    function toggle(): void { root.open = !root.open }
  }

  PanelWindow {
    visible: root.open
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.alpha("black", 0.6)                       // dims the screen
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive
                                           : WlrKeyboardFocus.None

    // click anywhere outside the buttons to close
    MouseArea {
      anchors.fill: parent
      onClicked: root.open = false
    }

    Item {
      anchors.fill: parent
      focus: true

      Keys.onEscapePressed: root.open = false
      Keys.onLeftPressed:  root.currentIndex = Math.max(0, root.currentIndex - 1)
      Keys.onRightPressed: root.currentIndex = Math.min(root.actions.length - 1, root.currentIndex + 1)
      Keys.onReturnPressed: root.run(root.actions[root.currentIndex])
      Keys.onEnterPressed:  root.run(root.actions[root.currentIndex])

      Row {
        anchors.centerIn: parent
        spacing: 16

        Repeater {
          model: root.actions

          delegate: Rectangle {
            required property var modelData
            required property int index

            width: 120; height: 120; radius: 16
            color: root.currentIndex === index ? Theme.overlay : Theme.surface
            border.width: root.currentIndex === index ? 2 : 0
            border.color: modelData.label === "Shutdown" ? Theme.danger : Theme.accent

            Column {
              anchors.centerIn: parent
              spacing: 8

              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.icon
                color: Theme.text
                font.pixelSize: 36
              }
              Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: modelData.label
                color: Theme.text
                font.pixelSize: 14
              }
            }

            MouseArea {
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onEntered: root.currentIndex = index
              onClicked: root.run(modelData)
            }
          }
        }
      }
    }
  }
}
