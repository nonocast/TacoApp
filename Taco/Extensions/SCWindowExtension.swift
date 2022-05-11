//
//  SCWindow.swift
//  Taco
//
//  Created by nonocast on 2022/5/11.
//

import ScreenCaptureKit

extension SCWindow {
  var displayName: String {
    switch (owningApplication, title) {
    case let (.some(application), .some(title)):
      return "\(application.applicationName): \(title)"
    case let (.none, .some(title)):
      return title
    case let (.some(application), .none):
      return "\(application.applicationName): \(windowID)"
    default:
      return ""
    }
  }
}
