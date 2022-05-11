//
//  Screen.swift
//  Taco
//
//  Created by nonocast on 2022/5/10.
//

import Foundation
import OSLog
import ScreenCaptureKit

enum CaptureType {
  case independentWindow
  case display
}

struct CaptureConfiguration {
  var captureType: CaptureType = .display
  var display: SCDisplay?
  var window: SCWindow?
  var filterOutOwningApplication = true
}

class Screen : VideoInput {
  static let shared = Screen()
  
  private let logger = Logger()
  private var stream: SCStream?
  private let queue = DispatchQueue(label: "cn.nonocast.screen")
  
  func open() async throws {
    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
    print("display count: \(content.displays.count)")
    print("CGMainDisplayID: \(CGMainDisplayID())")
    
    for display in content.displays {
      print("displayID: \(display.displayID): \(display.width)x\(display.height)")
    }
    
    guard let display = content.displays.first else {
      throw AppError.ScreenNotFound
    }
    
    let excludedApps = content.applications.filter { app in
      Bundle.main.bundleIdentifier == app.bundleIdentifier
    }
    
    if(excludedApps.count == 0) {
      throw AppError.ScreenOpenError
    }
    
    let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
    
    let streamConfig = SCStreamConfiguration()
    streamConfig.width = display.width * 2
    streamConfig.height = display.height * 2
    streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: CMTimeScale(30))
    streamConfig.queueDepth = 5
    
    
    stream = SCStream(filter: filter, configuration: streamConfig, delegate: self)
    try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: queue)
    
    try await stream?.startCapture()
  }
  
  func close() async {
    do {
      try await stream?.stopCapture()
    } catch {
      print(error)
    }
  }
}

extension Screen : SCStreamOutput {
  func stream(_: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of _: SCStreamOutputType) {
//    print("SCStreamOutput: screen frame")
    guard sampleBuffer.isValid else { return }
   
    if let buffer = sampleBuffer.imageBuffer {
      DispatchQueue.main.async {
        self.frame = buffer
      }
    }
  }
}

extension Screen: SCStreamDelegate {
  func stream(_: SCStream, didStopWithError error: Error) {
    print("Screen stream stopped with error: \(error.localizedDescription)")
  }
}
