import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO

class RootViewController: UIViewController, UIGestureRecognizerDelegate {
    var sceneView: ARSceneView!
    var fieldNode: SCNNode!
    var robotNode: SCNNode!

    var hasPlacedField = false

    var NTClient: NT4Client!

    override func loadView() {
        super.loadView()

        sceneView = ARSceneView(frame: self.view.frame)
        sceneView.autoenablesDefaultLighting = true
        self.view.addSubview(sceneView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.session.run(configuration)

        guard let field = sceneView.loadModelFromName("Field3d_2024") else {
            NSLog("Failed to load field model")
            return
        }
        fieldNode = field
        fieldNode.scale = SCNVector3(0.05, 0.05, 0.05)
        NSLog("Field loaded successfully")
        
        // Load the robot, it should be relative to the field. 0,0 should be the center of the field
        guard let robot = sceneView.loadModelFromName("Robot") else {
            NSLog("Failed to load robot model")
            return
        }
        robotNode = robot
        fieldNode.addChildNode(robotNode)


        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate))
        rotateGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(rotateGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(pinchGestureRecognizer)

        NTClient = NT4Client(appName: "ARKit", serverBaseAddr: "192.168.1.130", onTopicAnnounce: { topic in
            NSLog("Announced topic: \(topic.name)")
        }, onTopicUnannounce: { topic in
            NSLog("Unannounced topic: \(topic.name)")
        }, onNewTopicData: { topic, timestamp, data in
            NSLog("New data for topic \(topic.name): \(data)")
            if topic.name == "/SmartDashboard/Field/Robot" {
                // [x, y, rot (degrees)]
                var newPos = topic.getDoubleArray();
                // The data is in meters relative to the field center (in the field model scale) so we need to scale it to the ARKit scale
                robotNode.position = SCNVector3(newPos[0] -8.25, 0, newPos[1] - 4)
                robotNode.eulerAngles.y = newPos[2] * .pi / 180
            }
        }, onConnect: {
            NSLog("Connected to NetworkTables")
        }, onDisconnect: ((String, UInt16) -> Void)? { reason, code in
            NSLog("Disconnected from NetworkTables, reason: \(reason), code: \(code)")
        })

        NTClient.connect()
        NTClient.subscribe(key: "/SmartDashboard/Field/Robot")
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        sceneView.frame = CGRect(origin: .zero, size: size)
    }

    // When the app is brought to the foreground, resume the WS connection
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NTClient.connect()
    }
}