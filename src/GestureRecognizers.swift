// GestureRecognizers.swift
import UIKit
import ARKit

extension RootViewController {

    func addGestureRecognizers(){
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(tapGestureRecognizer)

        let rotateGestureRecognizer = UIRotationGestureRecognizer(target: self, action: #selector(handleRotate))
        rotateGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(rotateGestureRecognizer)

        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        pinchGestureRecognizer.delegate = self
        sceneView.addGestureRecognizer(pinchGestureRecognizer)

        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(openConfig))
        longPressGestureRecognizer.delegate = self
        longPressGestureRecognizer.minimumPressDuration = 0.5
        sceneView.addGestureRecognizer(longPressGestureRecognizer)

        // Prevent the tap gesture from being recognized until the long press gesture fails
        tapGestureRecognizer.require(toFail: longPressGestureRecognizer)
    }

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
        sceneView.fieldNode.position = position

        if(!hasPlacedField){
            sceneView.scene.rootNode.addChildNode(sceneView.fieldNode)
            hasPlacedField = true
        }
    }

    @objc func handleRotate(sender: UIRotationGestureRecognizer) {
        let rotation = Float(sender.rotation)
        // Update the field rotation relatively
        sceneView.fieldNode.eulerAngles.y -= rotation
        sender.rotation = 0.0
    }

    @objc func handlePinch(sender: UIPinchGestureRecognizer) {
        let scale = Float(sender.scale)
        sceneView.fieldNode.scale = SCNVector3(sceneView.fieldNode.scale.x * scale, sceneView.fieldNode.scale.y * scale, sceneView.fieldNode.scale.z * scale)
    
        sender.scale = 1.0
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
}