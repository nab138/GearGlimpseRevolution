import ARKit

class CommandScheduler {
  var namesSubID: Int?

  let view = CommandSchedulerView()
  var node: SCNNode!
  var plane: SCNPlane!
  var arScene: ARSceneView!

  var planeSize: Float = 0.25

  var commands: [String] = []

  var hasUpdatedLabel = false

  init(scene: ARSceneView) {
    arScene = scene
    loadViewNode()
  }

  func subscribeToCommandScheduler(client: NT4Client, key: String) {
    if namesSubID != nil {
      client.unsubscribe(subID: namesSubID!)
    }
    namesSubID = client.subscribe(
      key: key + "/Names",
      callback: { topic, timestamp, data in
        if let commands = data as? [String] {
          if commands != self.commands {
            self.commands = commands
            self.updateCommands()
          }
        }
      }, periodic: 0.1)
  }

  private func loadViewNode() {
    plane = SCNPlane(width: CGFloat(planeSize), height: CGFloat(planeSize))
    plane.firstMaterial?.isDoubleSided = true

    node = SCNNode(geometry: plane)
    regenImage()

    let billboardConstraint = SCNBillboardConstraint()
    billboardConstraint.freeAxes = [.Y, .X]
    node.constraints = [billboardConstraint]

    node.isHidden = !UserDefaults.standard.bool(forKey: "schedulerVisible")
  }

  private func updateCommands() {
    view.setCommands(commands)

    if commands.count > 0 {
      view.updateLabel(with: "\(commands.count) Commands")
    } else {
      view.updateLabel(with: "No Data")
    }

    regenImage()
  }

  func regenImage() {
    let image = view.asImage()
    let aspectRatio = image.size.width / image.size.height
    plane.width = CGFloat(planeSize)
    plane.height = CGFloat(planeSize) / aspectRatio
    plane.firstMaterial?.diffuse.contents = image

    node.geometry = plane
  }
}
