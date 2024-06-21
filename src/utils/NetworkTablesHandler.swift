import ARKit

// Helper class to manage NetworkTables connection and robot position updates
class NetworkTablesHandler {
  let fieldCenterX: Double = 8.25
  let fieldCenterY: Double = 4

  var client: NT4Client!
  var sceneView: ARSceneView!
  var robotNode: SCNNode!
  var statusLabel: UILabel!
  var robotSubID: Int?

  var ip: String?
  var port: String?
  var robotKey: String?

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
      onNewTopicData: { topic, timestamp, data in
        NSLog("New data for topic \(topic.name): \(data)")
      },
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
      self.updateStateLabel(active: true)
      client.disconnect()
    }
    client.connect(serverBaseAddr: ip!, port: port ?? "5810")

    if robotSubID != nil {
      client.unsubscribe(subID: robotSubID!)
    }

    // Subscribe to robot position updates
    robotSubID = client.subscribe(
      key: robotKey!,
      callback: { topic, timestamp, data in
        // [x, y, rot (degrees)]
        let newPos = topic.getDoubleArray()
        self.robotNode.position = SCNVector3(
          -newPos![0] + self.fieldCenterX, 0, newPos![1] - self.fieldCenterY)
        self.lastPosition = self.robotNode.position
        self.robotNode.eulerAngles.y = Float(newPos![2] * .pi / 180)
        self.lastRotation = self.robotNode.eulerAngles.y
        self.sceneView?.updateRobotNodeTransform()
      }, periodic: 0.001)
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
}
