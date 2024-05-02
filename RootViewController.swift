import UIKit
import ARKit

class RootViewController: UIViewController {

    var sceneView: ARSCNView!

    override func loadView() {
        super.loadView()

        sceneView = ARSCNView(frame: self.view.frame)
        self.view.addSubview(sceneView)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let configuration = ARWorldTrackingConfiguration()
        sceneView.session.run(configuration)

        let box = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0)
        let node = SCNNode()
        node.geometry = box
        node.position = SCNVector3(0, 0, -0.2)

        sceneView.scene.rootNode.addChildNode(node)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
}