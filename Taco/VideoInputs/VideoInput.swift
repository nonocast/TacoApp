//
//  VideoInput.swift
//  Taco
//
//  Created by nonocast on 2022/5/10.
//

import AVFoundation

class VideoInput : NSObject, ObservableObject {
  @Published var frame: CVPixelBuffer?
}
