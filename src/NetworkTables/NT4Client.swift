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
    var onNewTopicData: ((NTTopic, Int, Any) -> Void)?
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
    
    init(appName: String, serverBaseAddr: String, onTopicAnnounce: ((NTTopic) -> Void)?, onTopicUnannounce: ((NTTopic) -> Void)?, onNewTopicData: ((NTTopic, Int, Any) -> Void)?, onConnect: (() -> Void)?, onDisconnect: ((String, UInt16) -> Void)?) {
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
                            print("[NT4] Failed to decode JSON message: \(string)")
                            return
                        }
                        // Iterate through the messages
                        for obj in msg {
                            let objStr = String(describing: obj)
                            // Attempt to decode the message as a JSON object
                            if let msgObj = try? JSONSerialization.jsonObject(with: objStr.data(using: .utf8)!, options: []) as? [String: Any] {
                                if msgObj == nil {
                                    print("[NT4] Failed to decode JSON message: \(obj)")
                                    continue
                                }
                                // Handle the message
                                handleJsonMessage(msgObj)
                            }
                        }
                    }
                }

            case .binary(let data):
                NSLog("Received data: \(data.count)")
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
                        NSLog("Announce: \(params)")
                    default:
                        NSLog("Unknown method: \(method)")
                }
            }
        }
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

    private static func getClientTimeUS() -> Int {
        return Int(Date().timeIntervalSince1970 * 1000000)
    }

    private func getServerTimeUS() -> Int {
        if serverTimeOffset_us == nil {
            // TODO: maybe return nil?
            return 0
        }
        return NT4Client.getClientTimeUS() + serverTimeOffset_us!
    }
    
}
