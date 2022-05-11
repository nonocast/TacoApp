//
//  TacoApp.swift
//  Taco
//
//  Created by nonocast on 2022/5/10.
//

import SwiftUI

enum AppError : Error {
  case CameraNotFound
  case CameraOpenError
  case ScreenNotFound
  case ScreenOpenError
}

class AppStore : ObservableObject {
  var current: ViewModel?
}

@main
struct TacoApp: App {
  @NSApplicationDelegateAdaptor(TacoAppDelegate.self) var appDelegate
  @StateObject var appStore = AppStore()
  
  var body: some Scene {
    WindowGroup {
      ContentView(appStore: appStore).frame(minWidth:1280, minHeight:720, alignment: .center)
    }.commands {
      CommandMenu("Composer") {
        Button(action: {
          appStore.current?.composer = EmptyComposer()
        }, label: {Text("Empty")}).keyboardShortcut("0", modifiers: .command)
        Button(action: {
          appStore.current?.composer = ImageOnlyComposer()
        }, label: {Text("Image Only")}).keyboardShortcut("1", modifiers: .command)
        Button(action: {
          appStore.current?.composer = CameraOnlyComposer()
        }, label: {Text("Camera Only")}).keyboardShortcut("2", modifiers: .command)
        Button(action: {
          appStore.current?.composer = ScreenOnlyComposer()
        }, label: {Text("Screen Only")}).keyboardShortcut("3", modifiers: .command)
        Button(action: {
          appStore.current?.composer = ScreenWithPersonCameraComposer()
        }, label: {Text("Screen with Camera")}).keyboardShortcut("4", modifiers: .command)
        Button(action: {
          appStore.current?.composer = CameraWithBlurBackgroundComposer()
        }, label: {Text("Camera with Blur Background")}).keyboardShortcut("5", modifiers: .command)
        Button(action: {
          appStore.current?.composer = ComicCameraComposer()
        }, label: {Text("Comic Camera")}).keyboardShortcut("6", modifiers: .command)
        Button(action: {
          appStore.current?.composer = CameraWithFaceLandmarksComposer()
        }, label: {Text("Camera with Face Landmarks")}).keyboardShortcut("7", modifiers: .command)
      }
    }
  }
  
  init() {
    print("TacoApp init")
  }
}

class TacoAppDelegate :NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    print("applicationDidFinishLaunching")
    do {
      try Camera.shared.open()
    } catch {
      print(error)
    }
    
    Task.init {
      // sleep 0.3 sec
      do {
        try await Task.sleep(nanoseconds: 300_000_000)
        try await Screen.shared.open()
      } catch {
        print(error)
      }
    }
  }
  
  func applicationWillTerminate(_ notification: Notification) {
    print("applicationWillTerminate")
    Camera.shared.close()
    Task.init {
      await Screen.shared.close()
    }
  }
  
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    print("applicationShouldTerminateAfterLastWindowClosed")
    return true
  }
  
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
    print("applicationShouldHandleReopen")
    return true
  }
}
