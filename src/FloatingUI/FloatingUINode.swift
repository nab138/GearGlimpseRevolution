import ARKit

class FloatingUINode {
  let node: SCNNode
  let scheduler: CommandScheduler
  let fms: FMS

  var size: Float = 0.25
  var height: Float = 3.0
  var visible = true

  init(scene: ARSceneView) {
    scheduler = CommandScheduler(scene: scene)
    fms = FMS(scene: scene)
    node = SCNNode()
  }

  func adjustPositionsBasedOnHidden() {
    if !scheduler.node.isHidden && !fms.node.isHidden {
      scheduler.node.position.x = 0.15
      fms.node.position.x = -0.15
    } else if !scheduler.node.isHidden {
      scheduler.node.position.x = 0
    } else if !fms.node.isHidden {
      fms.node.position.x = 0
    }
  }
}
