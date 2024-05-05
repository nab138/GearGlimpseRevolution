import UIKit
import ARKit
import SceneKit
import SceneKit.ModelIO

class RootViewController: UIViewController, UIGestureRecognizerDelegate {
    var sceneView: ARSceneView!
    var fieldNode: SCNNode!

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

        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate))
        rotateGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(rotateGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(pinchGestureRecognizer)

        sceneView.scene.rootNode.addChildNode(fieldNode)
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
}