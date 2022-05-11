//
//  ScreenWithCameraComposers.swift
//  Taco
//
//  Created by nonocast on 2022/5/11.
//

import CoreGraphics
import CoreImage
import Cocoa
import VideoToolbox
import OSLog
import Vision
import CoreImage.CIFilterBuiltins

class ScreenWithCameraComposer : VideoComposer {
  @Published var cameraPixelBuffer: CVPixelBuffer?

  private let logger = Logger()
  private let context = CIContext()
  
  override init() {
    super.init()
    logger.info("ScreenWithCameraComposer init")
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Camera.shared.$frame
      .receive(on: RunLoop.main)
      .assign(to: &$cameraPixelBuffer)
    
    Screen.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        guard let x = buffer, let y = self.cameraPixelBuffer else {return nil }
        let ciScreen = CIImage(cvImageBuffer: x)
        var ciCamera = CIImage(cvImageBuffer: y)
        ciCamera = self.scaleFilter(ciCamera, aspectRatio: 1.0, scale: 1)
        
        let compositor = CIFilter(name: "CISourceOverCompositing")!
        compositor.setValue(ciCamera, forKey: kCIInputImageKey)
        compositor.setValue(ciScreen, forKey: kCIInputBackgroundImageKey)
        let ciImage = compositor.outputImage!
        return self.context.createCGImage(ciImage, from: ciImage.extent)
      }
      .assign(to: &$frame)
  }
  
  func perspectiveFilter(_ input: CIImage, pixelsWide: Int, pixelsHigh: Int) -> CIImage {
    let filter = CIFilter(name: "CIPerspectiveTransform")!
    let w = Float(input.extent.size.width)
    let h = Float(input.extent.size.height)
    let centerX = Float(pixelsWide) / 2
    let centerY = Float(pixelsHigh) / 2

    print("\(w)x\(h)")
    print("center: \(centerX), \(centerY)")

    filter.setValue(CIVector(x: CGFloat(centerX - w / 2), y: CGFloat(centerY + h / 2)), forKey: "inputTopLeft")
    filter.setValue(CIVector(x: CGFloat(centerX + w / 2), y: CGFloat(centerY + h / 2)), forKey: "inputTopRight")
    filter.setValue(CIVector(x: CGFloat(centerX - w / 2), y: CGFloat(centerY - h / 2)), forKey: "inputBottomLeft")
    filter.setValue(CIVector(x: CGFloat(centerX + w / 2), y: CGFloat(centerY - h / 2)), forKey: "inputBottomRight")
    filter.setValue(input, forKey: kCIInputImageKey)
    return filter.outputImage!
  }

  func scaleFilter(_ input: CIImage, aspectRatio: Double, scale: Double) -> CIImage {
    let scaleFilter = CIFilter(name: "CILanczosScaleTransform")!
    scaleFilter.setValue(input, forKey: kCIInputImageKey)
    scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
    scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
    return scaleFilter.outputImage!
  }
}

class ScreenWithPersonCameraComposer : VideoComposer {
  @Published var cameraPixelBuffer: CVPixelBuffer?
  let requestHandler = VNSequenceRequestHandler()
  let segmentationRequest = VNGeneratePersonSegmentationRequest()

  private let logger = Logger()
  private let context = CIContext()
  
  override init() {
    super.init()
    logger.info("ScreenWithPersonCameraComposer init")
    
    segmentationRequest.qualityLevel = .balanced
    segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Camera.shared.$frame
      .receive(on: RunLoop.main)
      .assign(to: &$cameraPixelBuffer)
    
    Screen.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        guard let x = buffer, let y = self.cameraPixelBuffer else { return nil }
        try? self.requestHandler.perform([self.segmentationRequest], on: y)
        guard let mask = self.segmentationRequest.results?.first?.pixelBuffer else { return nil }
        let result = self.blend(y, mask: mask, background: x)
        return self.context.createCGImage(result, from: result.extent)
      }
      .assign(to: &$frame)
  }
  
  func blend(_ original: CVPixelBuffer, mask: CVPixelBuffer, background: CVPixelBuffer) -> CIImage {
    var originalCI = CIImage(cvImageBuffer: original)
    var maskCI = CIImage(cvImageBuffer: mask)
    let backgroundCI = CIImage(cvImageBuffer: background)
    
    originalCI = self.scaleFilter(originalCI, aspectRatio: 1.0, scale: 0.7)

    let scaleX = originalCI.extent.width / maskCI.extent.width
    let scaleY = originalCI.extent.height / maskCI.extent.height
    maskCI = maskCI.transformed(by: .init(scaleX: scaleX, y: scaleY))
    
    let filter = CIFilter.blendWithRedMask()
    filter.inputImage = originalCI
    filter.backgroundImage = backgroundCI
    filter.maskImage = maskCI
    
    return filter.outputImage!
  }
  
  func perspectiveFilter(_ input: CIImage, pixelsWide: Int, pixelsHigh: Int) -> CIImage {
    let filter = CIFilter(name: "CIPerspectiveTransform")!
    let w = Float(input.extent.size.width)
    let h = Float(input.extent.size.height)
    let centerX = Float(pixelsWide) / 2
    let centerY = Float(pixelsHigh) / 2

    print("\(w)x\(h)")
    print("center: \(centerX), \(centerY)")

    filter.setValue(CIVector(x: CGFloat(centerX - w / 2), y: CGFloat(centerY + h / 2)), forKey: "inputTopLeft")
    filter.setValue(CIVector(x: CGFloat(centerX + w / 2), y: CGFloat(centerY + h / 2)), forKey: "inputTopRight")
    filter.setValue(CIVector(x: CGFloat(centerX - w / 2), y: CGFloat(centerY - h / 2)), forKey: "inputBottomLeft")
    filter.setValue(CIVector(x: CGFloat(centerX + w / 2), y: CGFloat(centerY - h / 2)), forKey: "inputBottomRight")
    filter.setValue(input, forKey: kCIInputImageKey)
    return filter.outputImage!
  }

  func scaleFilter(_ input: CIImage, aspectRatio: Double, scale: Double) -> CIImage {
    let scaleFilter = CIFilter(name: "CILanczosScaleTransform")!
    scaleFilter.setValue(input, forKey: kCIInputImageKey)
    scaleFilter.setValue(scale, forKey: kCIInputScaleKey)
    scaleFilter.setValue(aspectRatio, forKey: kCIInputAspectRatioKey)
    return scaleFilter.outputImage!
  }
}
