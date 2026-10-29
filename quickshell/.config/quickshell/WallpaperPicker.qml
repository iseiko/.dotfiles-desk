import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import Qt.labs.folderlistmodel

Scope {
  id: root
  property bool open: false
  
  // Path to the wallpapers directorie
  readonly property string wallDir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

  // Used by both the mouse and the Enter key
  function select(path) {
    if (!path) return
    setWall.path = path
    setWall.running = true
    root.open = false
  }

  onOpenChanged: if (open) {
    list.currentIndex = 0
    list.forceActiveFocus()
  }

  IpcHandler {
    target: "picker"
    function toggle(): void { root.open = !root.open }
  }

  // Handle focus grab
  HyprlandFocusGrab {
    windows: [ wall]
    active: root.open
    onCleared: root.open = false
  }

  // The command that will run when you select the wallpaper
  Process {
    id: setWall
    property string path: ""
    command: [
      "sh", "-c",
      'echo "$0" > ~/.cache/current_wall; matugen image "$0" -m dark --source-color-index 0; hyprctl reload; awww img "$0" --transition-type grow',
      path
    ]

    stderr: StdioCollector {
      onStreamFinished: if (text) console.log("setWall stderr:", text)
    }

    onExited: (exitCode, exitStatus) => {
      console.log("setWall exited with code", exitCode)
      Theme.refresh()
    }
  }

  PanelWindow {
    id: wall
    // Stay visible until the closing animation has finished
    visible: root.open || card.progress > 0
    anchors { bottom: true; left: true; right: true }
    // Tall enough for the card plus the gap under it
    implicitHeight: card.height + card.gap
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    // Exclusive while open, so the arrow keys work without clicking first
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive
                                           : WlrKeyboardFocus.None

    MouseArea {
      anchors.fill: parent
      onClicked: root.open = false
    }

    Rectangle {
      id: card
      height: 180
      anchors {
        left: parent.left
        right: parent.right
        bottom: parent.bottom
        leftMargin: 12
        rightMargin: 12
        bottomMargin: gap
      }
      radius: 16
      color: Theme.base

      // Space between the card and the bottom edge of the screen
      // (48 leaves your bar visible; set to 0 to sit flush against the edge)
      property real gap: 48

      // 0 = hidden below the screen, 1 = fully shown
      property real progress: root.open ? 1 : 0
      Behavior on progress {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
      }

      // when hidden, the card is pushed down by its own height plus the gap,
      // which puts it just past the bottom edge of the screen
      transform: Translate {
        y: (1 - card.progress) * (card.height + card.gap)
      }

      ListView {
        id: list
        anchors.fill: parent
        anchors.margins: 12
        orientation: ListView.Horizontal
        spacing: 12
        clip: true
        focus: true
        currentIndex: 0

        // Keep the selected wallpaper on screen while moving with the keys
        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        Keys.onLeftPressed: decrementCurrentIndex()
        Keys.onRightPressed: incrementCurrentIndex()
        Keys.onReturnPressed: root.select(currentItem ? currentItem.filePath : "")
        Keys.onEnterPressed: root.select(currentItem ? currentItem.filePath : "")
        Keys.onEscapePressed: root.open = false

        model: FolderListModel {
          folder: "file://" + root.wallDir
          nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp"]
          showDirs: false
        }

        delegate: Rectangle {
          required property string filePath
          readonly property bool selected: ListView.isCurrentItem

          width: 240
          height: ListView.view.height
          radius: 10
          clip: true
          color: Theme.surface

          Image {
            anchors.fill: parent
            source: "file://" + parent.filePath
            sourceSize.width: 480
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
          }

          // Selection highlight, drawn ABOVE the image (a border on the delegate
          // itself would be hidden underneath the image)
          Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 4
            border.color: Theme.accent
            visible: parent.selected || mouse.containsMouse
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.select(parent.filePath)
          }
        }
      }
    }
  }
}
