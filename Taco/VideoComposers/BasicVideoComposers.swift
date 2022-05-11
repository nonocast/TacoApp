//
//  VideoComposer.swift
//  Taco
//
//  Created by nonocast on 2022/5/10.
//

import CoreGraphics
import CoreImage
import Cocoa
import VideoToolbox
import OSLog

class VideoComposer : ObservableObject {
  @Published var frame: CGImage?
}

class EmptyComposer : VideoComposer {
  override init() {
    super.init()
    print("EmptyComposer init")
    let image = NSImage(size: NSSize(width: 1920, height: 1080), flipped: false, drawingHandler: { rect  -> Bool in
      guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
      ctx.setFillColor(CGColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1))
      ctx.fill(rect)
      return true
    })
    frame = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
  }
}

class ImageOnlyComposer : VideoComposer {
  override init() {
    super.init()
    print("ImageOnlyComposer init")
    if let image = NSImage(named: "Background 5") {
      frame = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    }
  }
}

class CameraOnlyComposer : VideoComposer {
  private let context = CIContext()
  
  override init() {
    super.init()
    print("CameraOnlyComposer init")
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Camera.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
//        print("CameraOnlyComposer#receive buffer")
        guard let b = buffer else {return nil }
        let image = CIImage(cvPixelBuffer: b).oriented(.upMirrored)
        return self.context.createCGImage(image, from: image.extent)
      }
      .assign(to: &$frame)
  }
}

class ScreenOnlyComposer : VideoComposer {
  private let logger = Logger()
  override init() {
    super.init()
    logger.info("ScreenOnlyComposer init")
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Screen.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
//        print("ScreenOnlyComposer#receive buffer")
        guard let image = CGImage.create(from: buffer) else {
          return nil
        }
        return image
      }
      .assign(to: &$frame)
  }
}

