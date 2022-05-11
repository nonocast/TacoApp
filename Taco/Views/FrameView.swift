//
//  VideoCaptureView.swift
//  camapp
//
//  Created by nonocast on 2022/5/1.
//
import Cocoa
import Foundation
import SwiftUI
import AVFoundation

struct FrameView : View {
  @ObservedObject var composer: VideoComposer
  
  var body: some View {
    if let image = composer.frame {
      GeometryReader { geometry in
        Image(image, scale: 1.0, orientation: .up, label: Text("frame"))
          .resizable()
          .scaledToFill()
          .frame(
            width: geometry.size.width,
            height: geometry.size.height,
            alignment: .center)
          .clipped()
      }
    } else {
      EmptyView()
    }
  }
}

struct FrameView_Previews: PreviewProvider {
  static var previews: some View {
    FrameView(composer: EmptyComposer())
  }
}


