import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
  id: root
  property bool open: false

  // Filtered, sorted list; re-evaluates whenever search.text changes
  readonly property var results: {
    const q = search.text.toLowerCase()
    return Array.from(DesktopEntries.applications.values)
      .filter(e => !e.noDisplay && e.name.toLowerCase().includes(q))
      .sort((a, b) => a.name.localeCompare(b.name))
  }

  // This function toggles the app launcher
  function launch(entry) {
    if (!entry) return
    entry.execute()
    root.open = false
  }

  onOpenChanged: if (open) {
    search.text = ""
    list.currentIndex = 0
    search.forceActiveFocus()
  }

  // This handles what the code will do when the keybind definde in ~/.config/hypr/modules/binds is pressed
  IpcHandler {
    target: "launcher"
    function toggle(): void { root.open = !root.open }
  }

  // This handles the focus grab on hyprland so the keyboard is focused on the searchbar inside the app launcher 
  HyprlandFocusGrab {
    windows: [ panel ]
    active: root.open
    onCleared: root.open = false
  }

  // The panel window is where everything sits, its the base of the whole app launcher
  PanelWindow {
    id: panel
    // stay visible until the closing animation has finished
    visible: root.open || card.progress > 0
    // fullscreen and transparent, so the card has room to travel from the bottom edge
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.open ? WlrKeyboardFocus.Exclusive
                                           : WlrKeyboardFocus.None

    // clicking anywhere outside the card closes the launcher
    MouseArea {
      anchors.fill: parent
      onClicked: root.open = false
    }

    // This object is the background of the app launcher card, where the icons and searchbar sit
    Rectangle {
      id: card
      width: 600
      height: 650
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      radius: 16
      color: Theme.base
      // no border so it blends with the bar thats on the back of the card 
      border.width: 0
      // border.color: Theme.overlay
      anchors.bottomMargin: gap

      // space between the card and the bottom edge of the screen similar to what microsoft does
      // (48 leaves your bar visible; set to 0 to sit flush against the edge)
      property real gap: 0

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

      // swallows clicks on empty parts of the card so they don't reach the backdrop
      MouseArea { anchors.fill: parent }

      // Search box
      Rectangle {
        id: searchBox
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 12 }
        height: 44
        radius: 10
        color: Theme.surface

        TextInput {
          id: search
          anchors.fill: parent
          anchors.leftMargin: 14
          anchors.rightMargin: 14
          verticalAlignment: TextInput.AlignVCenter
          color: Theme.text
          font.pixelSize: 16
          clip: true
          focus: true

          onTextChanged: list.currentIndex = 0

          Keys.onEscapePressed: root.open = false
          Keys.onDownPressed: list.incrementCurrentIndex()
          Keys.onUpPressed: list.decrementCurrentIndex()
          Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
          Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
        }

        Text {
          anchors.fill: search
          verticalAlignment: Text.AlignVCenter
          text: "Search apps..."
          color: Theme.muted
          font.pixelSize: 16
          visible: search.text === ""
        }
      }

      ListView {
        id: list
        anchors {
          top: searchBox.bottom; bottom: parent.bottom
          left: parent.left; right: parent.right
          margins: 12
        }
        clip: true
        spacing: 4
        currentIndex: 0
        boundsBehavior: Flickable.StopAtBounds

        model: ScriptModel { values: root.results }

        delegate: Rectangle {
          required property var modelData
          required property int index

          width: ListView.view.width
          height: 44
          radius: 8
          color: ListView.isCurrentItem ? Theme.overlay
               : mouse.containsMouse    ? Theme.surface : "transparent"

          Row {
            anchors.fill: parent
            anchors.leftMargin: 10
            spacing: 12

            Image {
              anchors.verticalCenter: parent.verticalCenter
              width: 28; height: 28
              source: Quickshell.iconPath(modelData.icon, true)
              sourceSize: Qt.size(56, 56)
              asynchronous: true
            }

            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: modelData.name
              color: Theme.text
              font.pixelSize: 15
            }
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.launch(modelData)
          }
        }
      }
    }
  }
}
