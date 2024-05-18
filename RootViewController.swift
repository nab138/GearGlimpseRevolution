import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO

class RootViewController: UIViewController, UIGestureRecognizerDelegate {
    var sceneView: ARSceneView!
    var fieldNode: SCNNode!
    var robotNode: SCNNode!

    var hasPlacedField = false

    var NTHandler: NetworkTablesHandler!

    var statusLabel: PaddedLabel!

    override func loadView() {
        super.loadView()

        sceneView = ARSceneView(frame: UIScreen.main.bounds)
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
        // Create a dummy node so that I can offset the position of the robot
        let dummyNode = SCNNode()
        dummyNode.position = SCNVector3(0.35, -0.35, -0.875)
        dummyNode.addChildNode(robotNode)
        fieldNode.addChildNode(dummyNode)
        
        addGestureRecognizers()
        statusLabel = PaddedLabel()

        statusLabel.text = "NT: Disconnected"
        statusLabel.font = UIFont.systemFont(ofSize: 14)
        statusLabel.textColor = UIColor.white
        statusLabel.backgroundColor = UIColor.red.withAlphaComponent(0.4)
        statusLabel.textAlignment = .center
        statusLabel.layer.cornerRadius = 10
        statusLabel.layer.masksToBounds = true
        statusLabel.sizeToFit()
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        statusLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)

        statusLabel.leftInset = 10
        statusLabel.rightInset = 10

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        sceneView.addSubview(statusLabel)
        NSLayoutConstraint.activate([
            statusLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            statusLabel.heightAnchor.constraint(equalToConstant: 30)
        ])

        NTHandler = NetworkTablesHandler(robotNode: robotNode, statusLabel: statusLabel)
        NTHandler.connect()
    }

    // Done to allow rotation and pinch gestures to work simultaneously
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }

    // This is done to make sure the ARSceneView is resized when the device is rotated
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        sceneView.frame = CGRect(origin: .zero, size: size)
    }
}