import ARKit

class CommandScheduler {
  var subscriptionID: Int?

  let view = CommandSchedulerView()
  var node: SCNNode!
  var plane: SCNPlane!
  var arScene: ARSceneView!

  var size: Float = 0.25
  var height: Float = 3.0
  var visible = true

  // add constructor
  init(scene: ARSceneView) {
    arScene = scene

    loadViewNode()
  }

  func subscribeToCommandScheduler(client: NT4Client, key: String) {
    if subscriptionID != nil {
      client.unsubscribe(subID: subscriptionID!)
    }
    subscriptionID = client.subscribe(
      key: key, callback: { topic, timestamp, data in }, periodic: 0.1)
  }

  func loadViewNode() {
    let image = view.asImage()
    let aspectRatio = image.size.width / image.size.height
    plane = SCNPlane(width: CGFloat(size), height: CGFloat(size) / aspectRatio)
    plane.firstMaterial?.diffuse.contents = image
    plane.firstMaterial?.isDoubleSided = true

    node = SCNNode(geometry: plane)

    let billboardConstraint = SCNBillboardConstraint()
    billboardConstraint.freeAxes = [.Y, .X]
    node.constraints = [billboardConstraint]

    node.isHidden = UserDefaults.standard.bool(forKey: "schedulerVisible")

    arScene.scene.rootNode.addChildNode(node)
  }
}
