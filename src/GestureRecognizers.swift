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

    @objc func handleDoubleTap(sender: UITapGestureRecognizer) {
        let alert = UIAlertController(title: "Configuration", message: "Configure the robot", preferredStyle: .alert)
        alert.addTextField { (textField) in
            // Default value
            textField.text = "192.168.1.130"
        }
        alert.addAction(UIAlertAction(title: "Connect", style: .default, handler: { [weak alert] (_) in
            let textField = alert?.textFields![0]
            self.NTClient.disconnect()
            self.NTClient = NT4Client(appName: "ARKit", serverBaseAddr: textField!.text!,
            onTopicAnnounce: { topic in
                NSLog("Announced topic: \(topic.name)")
            }, onTopicUnannounce: { topic in
                NSLog("Unannounced topic: \(topic.name)")
            }, onNewTopicData: { topic, timestamp, data in
                NSLog("New data for topic \(topic.name): \(data)")
                if topic.name == "/SmartDashboard/Field/Robot" {
                    // [x, y, rot (degrees)]
                    let newPos = topic.getDoubleArray();
                    // The data is in meters relative to the field center (in the field model scale) so we need to scale it to the ARKit scale
                    self.robotNode.position = SCNVector3(-newPos![0] + 8.25, 0, newPos![1] - 4)
                    self.robotNode.eulerAngles.y = Float(newPos![2] * .pi / 180)
                }
            }, onConnect: {
            NSLog("Connected to NetworkTables")
        }, onDisconnect: ((String, UInt16) -> Void)? { reason, code in
            NSLog("Disconnected from NetworkTables, reason: \(reason), code: \(code)")
        })
            self.NTClient.connect()
        }))
        self.present(alert, animated: true, completion: nil)
    }
}