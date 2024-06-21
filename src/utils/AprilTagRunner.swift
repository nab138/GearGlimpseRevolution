import ARKit

// Handles dispatching AprilTag detection to the ARSceneView
extension RootViewController {
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    guard shouldDetectAprilTags && (lastUpdateTime == nil || time - lastUpdateTime! >= period)
    else { return }
    lastUpdateTime = time

    DispatchQueue.global(qos: .userInitiated).async { [weak self] in
      autoreleasepool {
        guard let self = self else { return }
        DispatchQueue.main.async {
          guard !self.isDetectingAprilTags else { return }
          self.isDetectingAprilTags = true
        }

        self.sceneView.detectAprilTagsInScene { [weak self] success in
          guard let self = self else { return }
          DispatchQueue.main.async {
            self.isDetectingAprilTags = false
            if success {
              self.period = self.detectionPeriod
              self.failedOnce = false
            } else if self.failedOnce {
              self.period = self.noDetectionPeriod
            } else {
              self.failedOnce = true
            }
          }
        }
      }
    }
  }
}
