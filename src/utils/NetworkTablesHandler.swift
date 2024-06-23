import ARKit

// Helper class to manage NetworkTables connection and robot position updates
class NetworkTablesHandler {
  static let fieldCenterX: Double = 8.2705
  static let fieldCenterY: Double = 4.1055

  var client: NT4Client!
  var sceneView: ARSceneView!
  var robotNode: SCNNode!
  var statusLabel: UILabel!
  var robotSubID: Int?
  var trajectorySubID: Int?

  var ip: String?
  var port: String?
  var robotKey: String?
  var trajectoryKey: String?

  var lastPosition: SCNVector3 = SCNVector3(0, 0, 0)
  var lastRotation: Float = 0

  init(robotNode: SCNNode, statusLabel: UILabel, sceneView: ARSceneView) {
    self.robotNode = robotNode
    self.statusLabel = statusLabel
    self.sceneView = sceneView
    client = NT4Client(
      appName: "GearGlimpse",
      onTopicAnnounce: { topic in
        NSLog("Announced topic: \(topic.name)")
      },
      onTopicUnannounce: { topic in
        NSLog("Unannounced topic: \(topic.name)")
      },
      onNewTopicData: { topic, timestamp, data in },
      onConnect: {
        NSLog("Connected to NetworkTables")
        self.updateStateLabel(active: true)
      },
      onDisconnect: ((String, UInt16) -> Void)? { reason, code in
        NSLog("Disconnected from NetworkTables, reason: \(reason), code: \(code)")
        self.updateStateLabel(active: false)
      })

    let manualAddress = UserDefaults.standard.bool(forKey: "manualAddress")
    if manualAddress {
      ip = UserDefaults.standard.string(forKey: "ip")
    } else {
      let teamNumber = UserDefaults.standard.string(forKey: "teamNumber")
      if teamNumber != nil {
        ip = "roborio-\(teamNumber!)-frc.local"
      }
    }
    port = UserDefaults.standard.string(forKey: "port")
    if port == nil {
      port = "5810"
      UserDefaults.standard.set(port, forKey: "port")
    }
    robotKey = UserDefaults.standard.string(forKey: "robotKey")
    if robotKey == nil {
      robotKey = "/SmartDashboard/Field/Robot"
      UserDefaults.standard.set(robotKey, forKey: "robotKey")
    }
    trajectoryKey = UserDefaults.standard.string(forKey: "trajectoryKey")
    if trajectoryKey == nil {
      trajectoryKey = ""
      UserDefaults.standard.set(trajectoryKey, forKey: "trajectoryKey")
    }
  }

  func setNewRobot(robot: SCNNode) {
    robotNode = robot
    robotNode.position = lastPosition
    robotNode.eulerAngles.y = lastRotation
    sceneView.updateRobotNodeTransform()
  }

  func connect() {
    if ip == nil || robotKey == nil {
      return
    }
    if client.serverConnectionActive {
      self.updateStateLabel(active: false)
      client.disconnect()
    }
    client.connect(serverBaseAddr: ip!, port: port ?? "5810")

    if robotSubID != nil {
      client.unsubscribe(subID: robotSubID!)
    }

    if trajectorySubID != nil {
      client.unsubscribe(subID: trajectorySubID!)
      sceneView.trajectoryNode?.removeFromParentNode()
    }

    // Subscribe to robot position updates
    robotSubID = client.subscribe(
      key: robotKey!,
      callback: { topic, timestamp, data in
        // [x, y, rot (degrees)]
        let newPos = data as? [Double]
        self.robotNode.position = NetworkTablesHandler.fieldToARCoords(x: newPos![0], y: newPos![1])
        self.lastPosition = self.robotNode.position
        self.robotNode.eulerAngles.y = Float(newPos![2] * .pi / 180)
        self.lastRotation = self.robotNode.eulerAngles.y
        self.sceneView?.updateRobotNodeTransform()
      }, periodic: 0.001)

    // Subscribe to trajectory updates
    if trajectoryKey != nil && trajectoryKey != "" {
      trajectorySubID = client.subscribe(
        key: trajectoryKey!,
        callback: { topic, timestamp, data in
          // [x, y, ignore, x, y, ignore, ...]
          let points = data as? [Double]
          var positions: [SCNVector3] = []
          for i in stride(from: 0, to: points!.count, by: 3) {
            positions.append(NetworkTablesHandler.fieldToARCoords(x: points![i], y: points![i + 1]))
          }
          // Draw a line between each point in the sceneView
          self.sceneView?.drawTrajectory(points: positions)
        }, periodic: 0.1, all: true)
    }
  }

  private func updateStateLabel(active: Bool) {
    if active {
      statusLabel.text = "NT: Connected to \(ip ?? "")"
      statusLabel.backgroundColor = UIColor.green.withAlphaComponent(0.4)
    } else {
      statusLabel.text = "NT: Disconnected"
      statusLabel.backgroundColor = UIColor.red.withAlphaComponent(0.4)
    }
  }

  // static function to convert coords
  static func fieldToARCoords(x: Double, y: Double) -> SCNVector3 {
    return SCNVector3(
      -x + NetworkTablesHandler.fieldCenterX, 0, y - NetworkTablesHandler.fieldCenterY)
  }
}
