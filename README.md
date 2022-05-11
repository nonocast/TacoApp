# CameraApp

## Version

- v1.1: 仅跑通，支持虚拟图片背景
- v1.2: 重构代码，增加桌面采集和场景切换
- > v1.3: VideoToolBox编码/RTSP推流

## BUG
- 多窗口无法跟踪当前激活窗口

## Feature

- 支持多种画面场景
  1. EmptyComposer
  2. ImageOnlyComposer
  3. CameraOnlyComposer
  4. ScreenOnlyComposer
  5. ScreenWithPersonCameraComposer
  6. CameraWithBlurBackgroundComposer
  7. ComicCameraComposer
  8. CameraWithFaceLandmarksComposer
  
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
