import UIKit

class NT4Client: WebSocketDelegate {
    let PORT = 5810
    let RTT_PERIOD_MS_V40 = 1000
    let RTT_PERIOD_MS_V41 = 250
    let TIMEOUT_MS_V40 = 5000
    let TIMEOUT_MS_V41 = 1000

    var appName: String
    var onTopicAnnounce: ((NTTopic) -> Void)?
    var onTopicUnannounce: ((NTTopic) -> Void)?
    var onNewTopicData: ((NTTopic, Int64, Any) -> Void)?
    var onConnect: (() -> Void)?
    var onDisconnect: ((String, UInt16) -> Void)?

    var serverBaseAddr: String
    var ws: WebSocket?
    var timestampInterval: Timer?
    var disconnectTimeout: Timer?
    var serverAddr = ""
    var serverConnectionActive = false
    var serverConnectionRequested = false
    var serverTimeOffset_us: Int?
    var networkLatency_us: Int = 0

    var subscriptions = [Int: NTSubscription]()
    var publishedTopics = [String: NTTopic]()
    var serverTopics = [String: NTTopic]()
    
    init(appName: String, serverBaseAddr: String, onTopicAnnounce: ((NTTopic) -> Void)?, onTopicUnannounce: ((NTTopic) -> Void)?, onNewTopicData: ((NTTopic, Int64, Any) -> Void)?, onConnect: (() -> Void)?, onDisconnect: ((String, UInt16) -> Void)?) {
        self.appName = appName
        self.serverBaseAddr = serverBaseAddr
        self.onTopicAnnounce = onTopicAnnounce
        self.onTopicUnannounce = onTopicUnannounce
        self.onNewTopicData = onNewTopicData
        self.onConnect = onConnect
        self.onDisconnect = onDisconnect
    }

    func connect(){
        if serverConnectionActive {
            return
        }
        serverConnectionRequested = true
        serverAddr = "ws://" + serverBaseAddr + ":" + String(PORT) + "/nt/" + appName
        NSLog("Connecting to \(serverAddr)")
        let url = URL(string: serverAddr)!
        let urlRequest = URLRequest(url: url)
        ws = WebSocket(request: urlRequest)
        ws?.delegate = self
        ws?.connect()
    }

    func didReceive(event: WebSocketEvent, client: WebSocketClient) {
        switch event {
            case .connected(_):
                serverConnectionActive = true
                wsSendTimestamp()
                onConnect?()
            case .disconnected(let reason, let code):
                serverConnectionActive = false
                onDisconnect?(reason, code)
            case .text(let string):
                if let data = string.data(using: .utf8) {
                    if let msg = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]] {
                        if msg == nil {
                            NSLog("[NT4] Failed to decode JSON message: \(string)")
                            return
                        }
                        // Iterate through the messages
                        for obj in msg {
                            let objStr = String(describing: obj)
                            // Attempt to decode the message as a JSON object
                            if let msgObj = try? JSONSerialization.jsonObject(with: objStr.data(using: .utf8)!, options: []) as? [String: Any] {
                                // Handle the message
                                handleJsonMessage(msg: msgObj)
                            }
                        }
                    }
                }

            case .binary(let data):
                do {
                    let decodedObj: [Any]? = try data.unpack() as? [Any]
                    guard let decodedObj = decodedObj else { return }
                    handleMsgPackMessage(msg: decodedObj)
                } catch {
                    NSLog("Something went wrong while unpacking data: \(error)")
                }
            case .ping(_):
                break
            case .pong(_):
                break
            case .viabilityChanged(_):
                break
            case .reconnectSuggested(_):
                break
            case .cancelled:
                serverConnectionActive = false
                onDisconnect?("Cancelled", 0)
                NSLog("websocket is cancelled")
            case .error(_):
                serverConnectionActive = false
                onDisconnect?("Error", 0)
                NSLog("An error occurred")
                case .peerClosed:
                    break
	    }
    }

    private func handleJsonMessage(msg: [String: Any]) {
        if let method = msg["method"] as? String {
            if let params = msg["params"] as? [String: Any] {
                switch method {
                    case "announce":
                        let newTopic = NTTopic(data: params)
                        serverTopics[newTopic.name] = newTopic
                        onTopicAnnounce?(newTopic)
                        NSLog("Announce: \(params)")
                    default:
                        NSLog("Unknown method: \(method)")
                }
            }
        }
    }

    private func handleMsgPackMessage(msg: [Any]){
        let topicID = msg[0] as! Int
        let timestamp = msg[1] as! Int64
        let data = msg[2]

        if topicID >= 0 {
            var topic: NTTopic? = nil
            // Check to see if the topic ID matches any of the server topics
            for serverTopic in serverTopics.values {
                if serverTopic.uid == topicID {
                    topic = serverTopic
                    break
                }
            }
            // If the topic is not found, return
            guard let topic = topic else { return }
            onNewTopicData?(topic, timestamp, data)
        } else if topicID == -1 {
            // Handle receive timestamp
            wsHandleReceiveTimestamp(serverTimestamp: timestamp, clientTimestamp: Int64(data as! Int))
        }
    }

    private func wsHandleReceiveTimestamp(serverTimestamp: Int64, clientTimestamp: Int64) {
        let rxTime = NT4Client.getClientTimeUS()

        // Recalculate server/client offset based on round trip time
        let rtt = Int(rxTime - clientTimestamp)
        networkLatency_us = rtt / 2
        let serverTimeAtRx = serverTimestamp + Int64(networkLatency_us)
        serverTimeOffset_us = Int(serverTimeAtRx - rxTime)

        print(
            "[NT4] New server time: " +
            String(Double(getServerTimeUS()) / 1000000.0) +
            "s with " +
            String(Double(networkLatency_us) / 1000.0) +
            "ms latency"
        )
    }

    private func wsSendTimestamp(){
        // Send the timestamp (convert using MessagePack) in the format: -1, 0, type, timestamp
        do {
            let timestamp = NT4Client.getClientTimeUS()
            var data = Data()
            try data.pack(-1, 0, NT4Client.getClientTimeUS(), timestamp)
            wsSendBinary(data: data)
        } catch {
            NSLog("Failed to encode timestamp")
        }
    }

    private func wsSendBinary(data: Data) {
        if serverConnectionActive {
            ws?.write(data: data)
        }
    }

    private func wsSendJson(method: String, params: [String: Any]) {
        if serverConnectionActive {
            // send {"method": "method", "params": "params}
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
                ws?.write(string: "{\"method\":\"\(method)\",\"params\":\(String(data: jsonData, encoding: .utf8)!)}")
            } catch {
                NSLog("Failed to encode JSON")
            }
        }
    }

    private static func getClientTimeUS() -> Int64 {
        return Int64(Date().timeIntervalSince1970 * 1000000)
    }

    private func getServerTimeUS() -> Int64 {
        if serverTimeOffset_us == nil {
            // TODO: maybe return nil?
            return 0
        }
        return NT4Client.getClientTimeUS() + Int64(serverTimeOffset_us!)
    }
    
}
