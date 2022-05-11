//
//  CameraComposers.swift
//  Taco
//
//  Created by nonocast on 2022/5/11.
//

import Foundation
import CoreImage
import Vision
import AVFoundation
import Cocoa

class CameraWithBlurBackgroundComposer : VideoComposer {
  let requestHandler = VNSequenceRequestHandler()
  let segmentationRequest = VNGeneratePersonSegmentationRequest()
  let context = CIContext()
  
  override init() {
    super.init()
    print("CameraWithBlurBackgroundComposer init")
    
    segmentationRequest.qualityLevel = .balanced
    segmentationRequest.outputPixelFormat = kCVPixelFormatType_OneComponent8
    
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Camera.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
//        print("CameraWithBlurBackgroundComposer#receive buffer")
        
        guard let p = buffer else { return nil }
        
        try? self.requestHandler.perform([self.segmentationRequest], on: p)
        guard let mask = self.segmentationRequest.results?.first?.pixelBuffer else { return nil }
        
        let result = self.blend(p, mask: mask, background: p).oriented(.upMirrored)
        return self.context.createCGImage(result, from: result.extent)
      }
      .assign(to: &$frame)
  }
  
  func blend(_ original: CVPixelBuffer, mask: CVPixelBuffer, background: CVPixelBuffer) -> CIImage {
    let originalCI = CIImage(cvImageBuffer: original)
    var maskCI = CIImage(cvImageBuffer: mask)
    var backgroundCI = CIImage(cvImageBuffer: background)
    
    backgroundCI = blur(backgroundCI)
    
    let scaleX = originalCI.extent.width / maskCI.extent.width
    let scaleY = originalCI.extent.height / maskCI.extent.height
    maskCI = maskCI.transformed(by: .init(scaleX: scaleX, y: scaleY))
    
    let filter = CIFilter.blendWithRedMask()
    filter.inputImage = originalCI
    filter.backgroundImage = backgroundCI
    filter.maskImage = maskCI
    
    return filter.outputImage!
  }
  
  func blur(_ image: CIImage) -> CIImage {
    let filter = CIFilter.gaussianBlur()
    //    let filter = CIFilter.discBlur()
    //    let filter = CIFilter.bokehBlur()
    //    let filter = CIFilter.boxBlur()
    filter.inputImage = image
    filter.setValue(10, forKey: "inputRadius")
    return filter.outputImage!
  }
}

class ComicCameraComposer : VideoComposer {
  private let context = CIContext()
  
  override init() {
    super.init()
    print("ComicCameraComposer init")
    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Camera.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        guard let b = buffer else { return nil }
        
        var image = CIImage(cvPixelBuffer: b).oriented(.upMirrored)
        image = image.applyingFilter("CIComicEffect")
        return self.context.createCGImage(image, from: image.extent)
      }
      .assign(to: &$frame)
  }
}

class CameraWithFaceLandmarksComposer : VideoComposer {
  private let requestHandler = VNSequenceRequestHandler()
  private var faceRequest: VNDetectFaceRectanglesRequest!
  private let context = CIContext()
  private var observations: [VNObservation]?
  
  override init() {
    super.init()
    print("CameraWithFaceLandmarksComposer init")
    
    faceRequest = VNDetectFaceRectanglesRequest { request, _ in
//      guard let results = request.results else { return }
//      print("face count: \(results.count)")
      //      drawBoundingBox(input, observations: results)
      self.observations = request.results
    }
    
    faceRequest.revision = VNDetectFaceRectanglesRequestRevision3

    setupSubscriptions()
  }
  
  private func setupSubscriptions() {
    Camera.shared.$frame
      .receive(on: RunLoop.main)
      .compactMap { buffer in
        guard let b = buffer else { return nil }
        try? self.requestHandler.perform([self.faceRequest], on: b)
        
        let image = CGImage.create(from: b)
        let boxImage = self.drawBoundingBox(image, observations: self.observations)
        let ci = CIImage(cgImage: boxImage!).oriented(.upMirrored)
        return self.context.createCGImage(ci, from: ci.extent)
      }
      .assign(to: &$frame)
  }
  
  func drawBoundingBox(_ input: CGImage?, observations: [VNObservation]?) -> CGImage! {
    guard let obs = observations else { return nil }
//    print("### drawBoundingBox \(obs.count)")

    guard let source = input else { return nil }

    let size = CGSize(width: source.width, height: source.height)
    let image = NSImage(size: size, flipped: false, drawingHandler: { _ -> Bool in
//      print("### drawingHandler")
      guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
      ctx.draw(source, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

      for observation in obs {
        if let face = observation as? VNFaceObservation {
          let bb = face.boundingBox
          let r = CGRect(x: bb.minX * size.width, y: bb.minY * size.height, width: bb.width * size.width, height: bb.height * size.height)
          ctx.setLineWidth(2)
          ctx.setStrokeColor(NSColor(calibratedRed: 1, green: 1, blue: 0, alpha: 0.9).cgColor)
          ctx.setFillColor(NSColor(calibratedRed: 1, green: 1, blue: 0, alpha: 0.1).cgColor)
          ctx.fill(r)
          ctx.stroke(r)
        }
      }
      return true
    })
    
    let p = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
    return p
  }
}
