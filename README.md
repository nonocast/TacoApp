# TocaApp

- MacOS 12.3, swift 5.6
- 此代码用于公开学习
- 视频(摄像头/屏幕)采集，编码，推流(rtmp)

## Version

- v1.1: 仅跑通，支持虚拟图片背景
- v1.2: 重构代码，增加桌面采集和场景切换
- current: VideoToolBox编码/RTSP推流

## BUG
- 多窗口无法跟踪当前激活窗口

## Feature

- 支持多种画面场景
  - EmptyComposer
  - ImageOnlyComposer
  - CameraOnlyComposer
  - ScreenOnlyComposer
  _ ScreenWithPersonCameraComposer
  - CameraWithBlurBackgroundComposer
  - ComicCameraComposer
  - CameraWithFaceLandmarksComposer
  
  注: 如没有摄像头仅保留模式4
  
- 通过左右按键切换，或数字键切换场景

## Technology 

- AVFoundation
- CoreGraphics
- CoreImage

## Design

### VideoInput
- Camera(id)
- Screen(id)

### VideoComposer
- EmptyComposer
- ImageOnlyComposer
- CameraOnlyComposer
- ScreenOnlyComposer
- ScreenWithPersonCameraComposer
- CameraWithBlurBackgroundComposer
- ComicCameraComposer
- CameraWithFaceLandmarksComposer

### VideoFrameView
+ composer
