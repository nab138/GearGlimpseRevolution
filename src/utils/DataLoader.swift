import ARKit

extension RootViewController {
  func loadPrefs() {
    if UserDefaults.standard.object(forKey: "fieldVisible") == nil {
      UserDefaults.standard.set(true, forKey: "fieldVisible")
    }
    if UserDefaults.standard.object(forKey: "schedulerVisible") == nil {
      UserDefaults.standard.set(true, forKey: "schedulerVisible")
    }
    if UserDefaults.standard.object(forKey: "fmsVisible") == nil {
      UserDefaults.standard.set(true, forKey: "fmsVisible")
    }
    if UserDefaults.standard.object(forKey: "schedulerHeight") == nil {
      UserDefaults.standard.set(3, forKey: "schedulerHeight")
    }
    sceneView.floatingUI.height = UserDefaults.standard.float(forKey: "schedulerHeight")
    if UserDefaults.standard.object(forKey: "schedulerSize") == nil {
      UserDefaults.standard.set(0.25, forKey: "schedulerSize")
    }
    sceneView.floatingUI.size = UserDefaults.standard.float(forKey: "schedulerSize")

    sceneView.fieldNode.isHidden = !(UserDefaults.standard.bool(forKey: "fieldVisible"))
    sceneView.fieldNode.opacity = UserDefaults.standard.bool(forKey: "fieldTransparent") ? 0.5 : 1.0

    shouldDetectAprilTags = UserDefaults.standard.bool(forKey: "detectAprilTags")
    if UserDefaults.standard.object(forKey: "apriltagID") != nil {
      sceneView.apriltagID = Int32(UserDefaults.standard.integer(forKey: "apriltagID"))
    }

    // Load the robot, it should be relative to the field. 0,0 should be the center of the field
    if !UserDefaults.standard.bool(forKey: "customRobotSelected") {
      let robotName = UserDefaults.standard.string(forKey: "selectedRobotName") ?? "2024 KitBot"
      loadRobot(name: robotName)
    } else {
      let robotName = UserDefaults.standard.string(forKey: "customRobotName") ?? "Custom Robot"
      if let bookmarkData = UserDefaults.standard.data(forKey: "customRobotBookmarkData") {
        var isStale = false
        do {
          let bookmarkURL = try URL(
            resolvingBookmarkData: bookmarkData, options: [], relativeTo: nil,
            bookmarkDataIsStale: &isStale)
          if isStale {
            // The bookmark data is stale, so you need to create a new bookmark
            let newBookmarkData = try bookmarkURL.bookmarkData(
              options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(newBookmarkData, forKey: "customRobotBookmarkData")
          }

          let robotOffset = SCNVector3(
            UserDefaults.standard.float(forKey: "xOffset"),
            UserDefaults.standard.float(forKey: "yOffset"),
            UserDefaults.standard.float(forKey: "zOffset")
          )
          let rotationOffset = SCNVector3(
            UserDefaults.standard.float(forKey: "xRot"),
            UserDefaults.standard.float(forKey: "yRot"),
            UserDefaults.standard.float(forKey: "zRot")
          )
          let robot = Robot(
            url: bookmarkURL, name: robotName, positionOffset: robotOffset,
            rotations: rotationOffset)
          loadRobot(robot: robot)
        } catch {
          NSLog("Failed to resolve bookmark: \(error)")
          loadRobot(name: "2024 KitBot")
        }
      } else {
        loadRobot(name: "2024 KitBot")
      }
    }
  }

  func loadRobot(name: String) {
    let robot = Robot.getByName(name)
    loadRobot(robot: robot)
  }

  func loadRobot(robot: Robot) {
    guard let robot = sceneView.loadRobot(robot) else {
      NSLog("Failed to load robot model")
      return
    }
    NSLog("Robot loaded successfully")
    robotNode = robot
    if NTHandler != nil {
      NTHandler.setNewRobot(robot: robot)
    }
  }
}
