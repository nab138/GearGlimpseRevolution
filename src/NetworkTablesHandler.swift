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

    init(robotNode: SCNNode, statusLabel: UILabel) {
        self.robotNode = robotNode
        self.statusLabel = statusLabel
        client = NT4Client(appName: "ARKit", onTopicAnnounce: { topic in
            NSLog("Announced topic: \(topic.name)")
        }, onTopicUnannounce: { topic in
            NSLog("Unannounced topic: \(topic.name)")
        }, onNewTopicData: { topic, timestamp, data in
            NSLog("New data for topic \(topic.name): \(data)")
            if topic.name == (self.robotKey ?? "") {
                // [x, y, rot (degrees)]
                let newPos = topic.getDoubleArray();
                // The data is in meters relative to the field center (in the field model scale) so we need to scale it to the ARKit scale
                self.robotNode.position = SCNVector3(-newPos![0] + self.fieldCenterX, 0, newPos![1] - self.fieldCenterY)
                self.robotNode.eulerAngles.y = Float(newPos![2] * .pi / 180)
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
        ip = UserDefaults.standard.string(forKey: "ip")
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

    func connect() {
        if ip == nil || robotKey == nil {
            return
        }
        if client.serverConnectionActive {
            self.statusLabel.text = "NT: Disconnected"
            client.disconnect()
        }
        client.connect(serverBaseAddr: ip!, port: port ?? "5810");
        robotSubID = client.subscribe(key: robotKey!, periodic: 0.001)
    }
}