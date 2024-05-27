import ARKit

class NetworkTablesHandler {
    let fieldCenterX: Double = 8.25
    let fieldCenterY: Double = 4

    var client: NT4Client!
    var robotNode: SCNNode!
    var statusLabel: UILabel!
    var robotSubID: Int = -1

    var ip: String?
    var port: String?
    var robotKey: String?

    var lastPosition: SCNVector3 = SCNVector3(0, 0, 0)
    var lastRotation: Float = 0

    init(robotNode: SCNNode, statusLabel: UILabel) {
        self.robotNode = robotNode
        self.statusLabel = statusLabel
        client = NT4Client(appName: "GearGlimpse", onTopicAnnounce: { topic in
            NSLog("Announced topic: \(topic.name)")
        }, onTopicUnannounce: { topic in
            NSLog("Unannounced topic: \(topic.name)")
        }, onNewTopicData: { topic, timestamp, data in
            NSLog("New data for topic \(topic.name): \(data)")
            if topic.name == (self.robotKey ?? "") {
                // [x, y, rot (degrees)]
                let newPos = topic.getDoubleArray();
                self.robotNode.position = SCNVector3(-newPos![0] + self.fieldCenterX, 0, newPos![1] - self.fieldCenterY)
                self.lastPosition = self.robotNode.position
                self.robotNode.eulerAngles.y = Float(newPos![2] * .pi / 180)
                self.lastRotation = self.robotNode.eulerAngles.y
            }
        }, onConnect: {
            NSLog("Connected to NetworkTables")
            self.statusLabel.text = "NT: Connected to \(self.ip ?? "")"
            self.statusLabel.backgroundColor = UIColor.green.withAlphaComponent(0.4)
        }, onDisconnect: ((String, UInt16) -> Void)? { reason, code in
            NSLog("Disconnected from NetworkTables, reason: \(reason), code: \(code)")
            self.statusLabel.text = "NT: Disconnected"
            self.statusLabel.backgroundColor = UIColor.red.withAlphaComponent(0.4)
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
    }

    func connect() {
        if ip == nil || robotKey == nil {
            return
        }
        if client.serverConnectionActive {
            self.statusLabel.text = "NT: Disconnected"
            self.statusLabel.backgroundColor = UIColor.red.withAlphaComponent(0.4)
            client.disconnect()
        }
        client.connect(serverBaseAddr: ip!, port: port ?? "5810");
        robotSubID = client.subscribe(key: robotKey!, periodic: 0.001)
    }
}