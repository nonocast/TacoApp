//
//  ContentView.swift
//  Taco
//
//  Created by nonocast on 2022/5/10.
//

import SwiftUI

struct ContentView: View {
  @StateObject var viewModel = ViewModel()
  @ObservedObject var appStore: AppStore
  
  var body: some View {
    VStack{
      if let composer = viewModel.composer {
        FrameView(composer: composer)
      }else {
        EmptyView()
      }
    }.onAppear{
      appStore.current = viewModel
    }
  }
}

struct ContentView_Previews: PreviewProvider {
  static let appStore = AppStore()
  
  static var previews: some View {
    ContentView(appStore: appStore).frame(width: 500, height: 500)
  }
}

class ViewModel : ObservableObject {
  @Published var composer: VideoComposer = CameraOnlyComposer()
}
