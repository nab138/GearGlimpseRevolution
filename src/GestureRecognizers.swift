// GestureRecognizers.swift
import UIKit
import ARKit

extension RootViewController {
    @objc func handleTap(sender: UITapGestureRecognizer) {
        let tapLocation = sender.location(in: sceneView)
        guard let query = sceneView.raycastQuery(from: tapLocation, allowing: .estimatedPlane, alignment: .horizontal) else {
            return
        }
        
        let results = sceneView.session.raycast(query)
        guard let result = results.first else {
            return
        }

        let position = SCNVector3(result.worldTransform.columns.3.x, result.worldTransform.columns.3.y, result.worldTransform.columns.3.z)
        fieldNode.position = position

        if(!hasPlacedField){
            sceneView.scene.rootNode.addChildNode(fieldNode)
            hasPlacedField = true
        }
    }

    @objc func handleRotate(sender: UIRotationGestureRecognizer) {
        let rotation = Float(sender.rotation)
        // Update the field rotation relatively
        fieldNode.eulerAngles.y -= rotation
        sender.rotation = 0.0
    }

    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        let scale = Float(sender.scale)
        fieldNode.scale = SCNVector3(fieldNode.scale.x * scale, fieldNode.scale.y * scale, fieldNode.scale.z * scale)
    
        sender.scale = 1.0
    }
}