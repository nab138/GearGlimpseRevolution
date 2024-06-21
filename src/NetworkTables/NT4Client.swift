import UIKit

class NT4Client: WebSocketDelegate {
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

  var ws: WebSocket?
  var timestampInterval: Timer?
  var disconnectTimeout: Timer?
  var serverConnectionActive = false
  var serverConnectionRequested = false
  var serverTimeOffset_us: Int?
  var networkLatency_us: Int = 0

  var subscriptions = [Int: NTSubscription]()
  var publishedTopics = [String: NTTopic]()
  var serverTopics = [String: NTTopic]()

  var queuedSubscriptions = [NTSubscription]()

  var subscriptionCallbacks = [String: (NTTopic, Int64, Any) -> Void]()

  init(
    appName: String, onTopicAnnounce: ((NTTopic) -> Void)?, onTopicUnannounce: ((NTTopic) -> Void)?,
    onNewTopicData: ((NTTopic, Int64, Any) -> Void)?, onConnect: (() -> Void)?,
    onDisconnect: ((String, UInt16) -> Void)?
  ) {
    self.appName = appName
    self.onTopicAnnounce = onTopicAnnounce
    self.onTopicUnannounce = onTopicUnannounce
    self.onNewTopicData = onNewTopicData
    self.onConnect = onConnect
    self.onDisconnect = onDisconnect
  }

  /**
 Connect to the NetworkTables server at the specified address and port

 - Parameter serverBaseAddr: The base address of the server (e.g. "roborio-1234-frc.local")
 - Parameter port: The port to connect to (default is "5810")
*/
  func connect(serverBaseAddr: String, port: String = "5810") {
    if serverConnectionActive {
      return
    }
    serverConnectionRequested = true
    let serverAddr = "ws://" + serverBaseAddr + ":" + port + "/nt/" + appName
    NSLog("Connecting to \(serverAddr)")
    let url = URL(string: serverAddr)!
    let urlRequest = URLRequest(url: url)
    ws = WebSocket(request: urlRequest)
    ws?.delegate = self
    ws?.connect()
  }

  /**
    Disconnect from the NetworkTables server
*/
  func disconnect() {
    if serverConnectionActive {
      ws?.disconnect()
      serverConnectionActive = false
    }
  }

  /**
Subscribe to a NetworkTables topic

- Parameter key: The key of the topic to subscribe to
- Parameter callback: The callback to be called when new data is received (topic, timestamp, data)
- Parameter periodic: The period at which to request updates from the server (default is 0.1s)
- Parameter all: Whether to receive all updates or just the latest (default is false)
- Parameter topicsOnly: Whether to only receive updates for topics (default is false)
- Parameter prefix: Whether to use the given key as a prefix (default is false) (may cause unexpected behavior with callback)

- Returns: The subscription ID, can be used to unsubscribe
*/
  func subscribe(
    key: String, callback: @escaping (NTTopic, Int64, Any) -> Void = { _, _, _ in },
    periodic: Double = 0.1,
    all: Bool = false, topicsOnly: Bool = false, prefix: Bool = false
  ) -> Int {
    let options = NTSubscriptionOptions(
      periodic: periodic, all: all, topicsOnly: topicsOnly, isPrefix: prefix)
    let sub = NTSubscription(uid: NT4Client.getNewUid(), topics: [key], options: options)
    subscriptionCallbacks[key] = callback
    subscriptions[sub.uid] = sub
    queuedSubscriptions.append(sub)
    if serverConnectionActive {
      wsSendJson(method: "subscribe", params: sub.toSubscribeObj())
    }
    return sub.uid
  }

  /**
Subscribe to a NetworkTables topic

- Parameter key: The key of the topic to subscribe to
- Parameter callback: The callback to be called when new data is received (topic, timestamp, data)
- Parameter options: The options for the subscription

- Returns: The subscription ID, can be used to unsubscribe
*/
  func subscribe(
    key: String,
    callback: @escaping (NTTopic, Int64, Any) -> Void = { _, _, _ in },
    options: NTSubscriptionOptions
  ) -> Int {
    let sub = NTSubscription(uid: NT4Client.getNewUid(), topics: [key], options: options)
    subscriptionCallbacks[key] = callback
    subscriptions[sub.uid] = sub
    queuedSubscriptions.append(sub)
    if serverConnectionActive {
      wsSendJson(method: "subscribe", params: sub.toSubscribeObj())
    }
    return sub.uid
  }

  /**
Subscribe to a set of NetworkTables topics

- Parameter key: The keys of the topics to subscribe to
- Paramter options: The options for the subscription

- Returns: The subscription ID, can be used to unsubscribe
*/
  func subscribe(
    key: Set<String>, options: NTSubscriptionOptions
  ) -> Int {
    let sub = NTSubscription(uid: NT4Client.getNewUid(), topics: key, options: options)
    subscriptions[sub.uid] = sub
    queuedSubscriptions.append(sub)
    if serverConnectionActive {
      wsSendJson(method: "subscribe", params: sub.toSubscribeObj())
    }
    return sub.uid
  }

  /**
Unsubscribe from a NetworkTables topic

- Parameter subID: The subscription ID to unsubscribe from
*/
  func unsubscribe(subID: Int) {
    if let sub = subscriptions[subID] {
      if serverConnectionActive {
        wsSendJson(method: "unsubscribe", params: sub.toUnsubscribeObj())
      }
      subscriptions.removeValue(forKey: subID)
      queuedSubscriptions.removeAll { $0.uid == subID }
    }
  }

  func didReceive(event: WebSocketEvent, client: WebSocketClient) {
    switch event {
    case .connected(_):
      serverConnectionActive = true
      wsSendTimestamp()
      onConnect?()
      for sub in queuedSubscriptions {
        wsSendJson(method: "subscribe", params: sub.toSubscribeObj())
      }
    case .disconnected(let reason, let code):
      serverConnectionActive = false
      onDisconnect?(reason, code)
    case .text(let string):
      if let data = string.data(using: .utf8) {
        if let msg = try? JSONSerialization.jsonObject(with: data, options: []) as? [[String: Any]]
        {
          // Iterate through the messages
          for obj in msg {
            // Handle the message
            handleJsonMessage(msg: obj)
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
      serverConnectionActive = false
      onDisconnect?("Peer closed", 0)
      NSLog("Peer closed")
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
        default:
          NSLog("Unknown method: \(method)")
        }
      }
    }
  }

  private func handleMsgPackMessage(msg: [Any?]) {
    var unsignedTimestamp = UInt64((msg[1] as? UInt32) ?? 0)
    if unsignedTimestamp == 0 {
      unsignedTimestamp = (msg[1] as? UInt64) ?? 0
      if unsignedTimestamp == 0 {
        NSLog("Failed to decode timestamp, it is \(type(of: msg[1]!))")
      }
    }
    let timestamp = Int64(unsignedTimestamp)
    let data = msg[3]!

    if let topicID = msg[0]! as? Int8 {
      if topicID == -1 {
        guard let clientTimestamp = data as? Int64 else {
          NSLog("Failed to decode clientTimestamp, it is \(type(of: data))")
          return
        }
        NSLog("Received timestamp: \(clientTimestamp)")
        // Handle receive timestamp
        wsHandleReceiveTimestamp(serverTimestamp: timestamp, clientTimestamp: clientTimestamp)
      }
    } else if let topicID = msg[0]! as? UInt16 {
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
      topic.latestValue = data
      topic.latestTimestamp = timestamp
      onNewTopicData?(topic, timestamp, data)
      if let callback = subscriptionCallbacks[topic.name] {
        NSLog("Found callback for topic \(topic.name)")
        callback(topic, timestamp, data)
      }
    } else {
      NSLog("Failed to decode topicID")
      return
    }

  }

  private func wsHandleReceiveTimestamp(serverTimestamp: Int64, clientTimestamp: Int64) {
    let rxTime = NT4Client.getClientTimeUS()

    // Recalculate server/client offset based on round trip time
    let rtt = Int(rxTime - clientTimestamp)
    networkLatency_us = rtt / 2
    let serverTimeAtRx = serverTimestamp + Int64(networkLatency_us)
    serverTimeOffset_us = Int(serverTimeAtRx - rxTime)

    NSLog(
      "[NT4] New server time: " + String(Double(getServerTimeUS()) / 1000000.0) + "s with "
        + String(Double(networkLatency_us) / 1000.0) + "ms latency"
    )
  }

  private func wsSendTimestamp() {
    // Send the timestamp (convert using MessagePack) in the format: -1, 0, type, timestamp
    do {
      let timestamp = NT4Client.getClientTimeUS()
      var data = Data()
      let array: [Any] = [-1, 0, NTTopic.typestrIdxLookup["int"]!, timestamp]
      try data.pack(array)
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
        ws?.write(
          string:
            "[{\"method\":\"\(method)\",\"params\":\(String(data: jsonData, encoding: .utf8)!)}]")
      } catch {
        NSLog("Failed to encode JSON")
      }
    }
  }

  private static func getClientTimeUS() -> Int64 {
    return Int64(Date().timeIntervalSince1970 * 1_000_000)
  }

  private func getServerTimeUS() -> Int64 {
    if serverTimeOffset_us == nil {
      return -1
    }
    return NT4Client.getClientTimeUS() + Int64(serverTimeOffset_us!)
  }

  private static func getNewUid() -> Int {
    // Return a random int
    return Int.random(in: 0..<10_000_000)
  }
}
