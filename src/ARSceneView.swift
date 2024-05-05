import ARKit
import SceneKit
import SceneKit.ModelIO

class ARSceneView: ARSCNView {
    var fieldNode: SCNNode!

    func loadModelFromName(_ name: String) -> SCNNode? {
        let url = Bundle.main.url(forResource: name, withExtension: "usdz")!
        let mdlAsset = MDLAsset(url: url)
        mdlAsset.loadTextures()
        let scene = SCNScene(mdlAsset: mdlAsset)
        return scene.rootNode
    }
}