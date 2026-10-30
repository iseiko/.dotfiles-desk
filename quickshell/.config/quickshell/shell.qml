import Quickshell

// This is the main QML file, im using it only to launch the other files

ShellRoot {
  WallpaperPicker {} // This function call the wallpaper picker
  AppLauncher { id: launcher } // This function display the app launcher
  PowerMenu { id: powerMenu } // This function show the logout menu
  Bar { launcher: launcher; powerMenu: powerMenu } // This function holds the taskbar
  Lock {} // This function call the lockscreen
  // Music {}
}
