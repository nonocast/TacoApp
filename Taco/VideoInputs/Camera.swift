//
//  Camera.swift
//  Taco
//
//  Created by nonocast on 2022/5/10.
//

import Foundation
import AVFoundation

class Camera : VideoInput {
  static let shared = Camera()
  
  private let session = AVCaptureSession()
  private let queue = DispatchQueue(label: "cn.nonocast.camera")
  
  override init() {
    super.init()
  }
  
  func open() throws {
    guard let device = chooseCaptureDevice() else {
      throw AppError.CameraNotFound
    }
    
    guard let videoInput = try? AVCaptureDeviceInput(device: device), session.canAddInput(videoInput) else {
      throw AppError.CameraOpenError
    }
    
    session.addInput(videoInput)
    
    let videoOutput = AVCaptureVideoDataOutput()
    videoOutput.setSampleBufferDelegate(self, queue: queue)
    guard session.canAddOutput(videoOutput) else {
      throw AppError.CameraOpenError
    }
    
    session.addOutput(videoOutput)
    session.startRunning()
  }
  
  func close() {
    session.stopRunning()
  }
}

extension Camera : AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    guard sampleBuffer.isValid else { return }
    
    if let buffer = sampleBuffer.imageBuffer {
      DispatchQueue.main.async {
        self.frame = buffer
      }
    }
  }
}

extension Camera {
  private func chooseCaptureDevice() -> AVCaptureDevice? {
    /*
    under 10.15
    let devices = AVCaptureDevice.devices(for: AVMediaType.video)
    return devices[1]
    */
    let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.externalUnknown], mediaType: .video, position: .unspecified)
    print("found \(discoverySession.devices.count) device(s)")

    let devices = discoverySession.devices
    guard !devices.isEmpty else { fatalError("found device FAILED") }

    // log all devices
    for each in discoverySession.devices {
      print("- \(each.localizedName)")
    }

    // choose the best
    /*
     obs-virtual-camera 报错时，需要去掉codesign
     https://obsproject.com/wiki/MacOS-Virtual-Camera-Compatibility-Guide
     sudo codesign --remove-signature CameraApp.app
     sudo codesign --sign - Camera.app
     */
    let device = devices.first(where: { device in device.position == AVCaptureDevice.Position(rawValue: 0) })
    
    if let p  = device {
      print(p.localizedName)
    }
    return device
  }
}
