import ARKit
import UIKit

extension RootViewController {
  func addGestureRecognizers() {
    let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
    tapGestureRecognizer.delegate = self
    sceneView.addGestureRecognizer(tapGestureRecognizer)

    let rotateGestureRecognizer = UIRotationGestureRecognizer(
      target: self, action: #selector(handleRotate))
    rotateGestureRecognizer.delegate = self
    sceneView.addGestureRecognizer(rotateGestureRecognizer)

    let pinchGestureRecognizer = UIPinchGestureRecognizer(
      target: self, action: #selector(handlePinch))
    pinchGestureRecognizer.delegate = self
    sceneView.addGestureRecognizer(pinchGestureRecognizer)

    let longPressGestureRecognizer = UILongPressGestureRecognizer(
      target: self, action: #selector(openConfig))
    longPressGestureRecognizer.delegate = self
    longPressGestureRecognizer.minimumPressDuration = 0.5
    sceneView.addGestureRecognizer(longPressGestureRecognizer)

    // Prevent the tap gesture from being recognized until the long press gesture fails
    tapGestureRecognizer.require(toFail: longPressGestureRecognizer)
  }

  @objc func handleTap(sender: UITapGestureRecognizer) {
    let tapLocation = sender.location(in: sceneView)
    guard
      let query = sceneView.raycastQuery(
        from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal)
    else {
      return
    }

    let results = sceneView.session.raycast(query)
    guard let result = results.first else {
      return
    }

    let position = SCNVector3(
      result.worldTransform.columns.3.x, result.worldTransform.columns.3.y,
      result.worldTransform.columns.3.z)
    sceneView.fieldNode.position = position
    sceneView.updateRobotNodeTransform()
    sceneView.updateTrajectoryTransform()
    sceneView.updateGamePieceTransforms()

    floatingUI.node.position = SCNVector3(
      position.x, position.y + floatingUI.height * sceneView.fieldNode.scale.y, position.z)

    if !hasPlacedField {
      sceneView.scene.rootNode.addChildNode(sceneView.fieldNode)
      hasPlacedField = true
      sceneView.hasPlacedField = true
      sceneView.trajectoryNode?.isHidden = false
      for node in sceneView.gamePieceNodes {
        node.isHidden = false
      }
      sceneView.curContainerDummyNode?.isHidden = false
      floatingUI.node.addChildNode(floatingUI.scheduler.node)
      floatingUI.node.addChildNode(floatingUI.fms.node)
      sceneView.scene.rootNode.addChildNode(floatingUI.node)
      floatingUI.adjustPositionsBasedOnHidden()
    }
  }

  @objc func handleRotate(sender: UIRotationGestureRecognizer) {
    let rotation = Float(sender.rotation)
    // Update the field rotation relatively
    sceneView.fieldNode.eulerAngles.y -= rotation
    sender.rotation = 0.0
    sceneView.updateRobotNodeTransform()
    sceneView.updateTrajectoryTransform()
    sceneView.updateGamePieceTransforms()

    floatingUI.node.eulerAngles.y = sceneView.fieldNode.eulerAngles.y
  }

  @objc func handlePinch(sender: UIPinchGestureRecognizer) {
    let scale = Float(sender.scale)
    sceneView.fieldNode.scale = SCNVector3(
      sceneView.fieldNode.scale.x * scale, sceneView.fieldNode.scale.y * scale,
      sceneView.fieldNode.scale.z * scale)

    floatingUI.node.scale = SCNVector3(
      floatingUI.node.scale.x * scale, floatingUI.node.scale.y * scale,
      floatingUI.node.scale.z * scale
    )

    floatingUI.node.position.y =
      sceneView.fieldNode.position.y + (floatingUI.height * sceneView.fieldNode.scale.y)

    sender.scale = 1.0
    sceneView.updateRobotNodeTransform()
    sceneView.updateTrajectoryTransform()
    sceneView.updateGamePieceTransforms()
  }

  @objc func openConfig(sender: UITapGestureRecognizer) {
    let configViewController = ConfigViewController()
    let navigationController = UINavigationController(rootViewController: configViewController)
    configViewController.NTHandler = NTHandler
    configViewController.fieldNode = sceneView.fieldNode
    configViewController.controller = self
    UIView.animate(withDuration: 0.2) {
      self.openSettingsLabel.alpha = 0
    } completion: { _ in
      self.openSettingsLabel.isHidden = true
    }
    if !UserDefaults.standard.bool(forKey: "hasOpenedSettings") {
      UserDefaults.standard.set(true, forKey: "hasOpenedSettings")
    }
    present(navigationController, animated: true, completion: nil)
  }

  // Done to allow rotation and pinch gestures to work simultaneously
  func gestureRecognizer(
    _ gestureRecognizer: UIGestureRecognizer,
    shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
  ) -> Bool {
    return true
  }
}
