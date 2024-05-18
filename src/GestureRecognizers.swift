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

    @objc func openConfig(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Configuration", message: "Configure GearGlimpse", preferredStyle: .alert)
        alert.addTextField { (textField) in
            textField.placeholder = "IP Address"
            textField.text = UserDefaults.standard.string(forKey: "ip")
        }
        alert.addTextField { (textField) in
            textField.placeholder = "Robot Key"
            textField.text = UserDefaults.standard.string(forKey: "robotKey")
        }
        let connected = NTHandler.client.serverConnectionActive
        alert.addAction(UIAlertAction(title: connected ? "Reconnect" : "Connect", style: .default, handler: { [weak alert] (_) in
            let ipField = alert?.textFields![0]
            let robotKeyField = alert?.textFields![1]
            self.NTHandler.ip = ipField!.text
            self.NTHandler.robotKey = robotKeyField!.text
            self.NTHandler.connect()
            UserDefaults.standard.set(ipField!.text!, forKey: "ip")
            UserDefaults.standard.set(robotKeyField!.text!, forKey: "robotKey")
        }))
        self.present(alert, animated: true, completion: nil)
    }
}