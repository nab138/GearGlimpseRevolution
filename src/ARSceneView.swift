import ARKit
import SceneKit
import SceneKit.ModelIO

struct Robot {
    var url: URL
    var name: String
    var positionOffset: SCNVector3

    static let robot3044 = Robot.fromResources(name: "R0xstar (3044)", file: "R0xstar", offset: SCNVector3(0.35, -0.35, -0.875))
    static let kitBot = Robot.fromResources(name: "2024 KitBot", file: "2024KitBot", offset: SCNVector3(0.35, 0.1, -0.4))

    static func fromResources(name: String, file: String, offset: SCNVector3) -> Robot {
        return Robot(url: Bundle.main.url(forResource: file, withExtension: "usdz")!, name: name, positionOffset: offset)
    }

    static func getByName(_ name: String) -> Robot {
        switch name {
        case "R0xstar (3044)":
            return robot3044
        case "2024 KitBot":
            return kitBot
        default:
            return robot3044
        }
    }
}

class ARSceneView: ARSCNView {
    var fieldNode: SCNNode!

    func loadModelFromResources(_ name: String) -> SCNNode? {
        let url = Bundle.main.url(forResource: name, withExtension: "usdz")!
        return loadModelFromURL(url)
    }

    func loadModelFromURL(_ url: URL) -> SCNNode? {
        let mdlAsset = MDLAsset(url: url)
        mdlAsset.loadTextures()
        let scene = SCNScene(mdlAsset: mdlAsset)
        return scene.rootNode
    }

    func loadRobot(_ robot: Robot) -> SCNNode? {
        guard let robotNode = loadModelFromURL(robot.url) else {
            return nil
        }
        let dummyNode = SCNNode()
        dummyNode.position = robot.positionOffset
        dummyNode.addChildNode(robotNode)
        fieldNode.addChildNode(dummyNode)
        return robotNode
    }
}