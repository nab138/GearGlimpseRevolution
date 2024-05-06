
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
    var onDisconnect: (() -> Void)?

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
    
    init(appName: String, serverBaseAddr: String, onTopicAnnounce: ((NTTopic) -> Void)?, onTopicUnannounce: ((NTTopic) -> Void)?, onNewTopicData: ((NTTopic, Int, Any) -> Void)?, onConnect: (() -> Void)?, onDisconnect: (() -> Void)?) {
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
            case .connected(let headers):
                serverConnectionActive = true
                onConnect?()
                NSLog("websocket is connected: \(headers)")
            case .disconnected(let reason, let code):
                serverConnectionActive = false
                onDisconnect?()
                NSLog("websocket is disconnected: \(reason) with code: \(code)")
            case .text(let string):
                NSLog("Received text: \(string)")
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
                onDisconnect?()
                NSLog("websocket is cancelled")
            case .error(_):
                serverConnectionActive = false
                onDisconnect?()
                NSLog("An error occurred")
                case .peerClosed:
                    break
	    }
    }
    
}