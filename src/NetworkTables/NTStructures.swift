import UIKit

class NTSubscription {
    var uid: Int = -1
    var topics = Set<String>()
    var options = NTSubscriptionOptions()

    init(uid: Int, topics: Set<String>, options: NTSubscriptionOptions) {
        self.uid = uid
        self.topics = topics
        self.options = options
    }

    func toSubscribeObj() -> [String: Any] {
        return [
            "topics": Array(topics),
            "subuid": uid,
            "options": options.toObj()
        ]
    }

    func toUnsubscribeObj() -> [String: Int] {
        return [
            "subuid": uid
        ]
    }
}

class NTSubscriptionOptions {
  var periodic = 0.1;
  var all = false;
  var topicsOnly = false;
  var isPrefix = false;

    init() {}

    init(periodic: Double, all: Bool, topicsOnly: Bool, isPrefix: Bool) {
        self.periodic = periodic
        self.all = all
        self.topicsOnly = topicsOnly
        self.isPrefix = isPrefix
    }

  func toObj()-> [String: Any] {
    return [
      "periodic": periodic,
      "all": all,
      "topicsonly": topicsOnly,
      "prefix": isPrefix
    ];
  }
}

class NTTopic {
    static let typestrIdxLookup = [
        "boolean": 0,
        "double": 1,
        "int": 2,
        "float": 3,
        "string": 4,
        "json": 4,
        "raw": 5,
        "rpc": 5,
        "msgpack": 5,
        "protobuf": 5,
        "boolean[]": 16,
        "double[]": 17,
        "int[]": 18,
        "float[]": 19,
        "string[]": 20
    ]
    var uid: Int = -1 // "id" if server topic, "pubuid" if published
    var name: String = ""
    var type: String = ""
    var properties: [String: Any] = [:]

    init(uid: Int, name: String, type: String, properties: [String: Any]) {
        self.uid = uid
        self.name = name
        self.type = type
        self.properties = properties
    }

    init(data: [String: Any]){
        if let id = data["id"] as? Int {
            uid = id
        } else if let id = data["pubuid"] as? Int {
            uid = id
        } else {
            NSLog("Error: Topic does not have an id")
        }
        if let n = data["name"] as? String {
            name = n
        } else {
            NSLog("Error: Topic does not have a name")
        }
        if let t = data["type"] as? String {
            type = t
        } else {
            NSLog("Error: Topic does not have a type")
        }
        if let p = data["properties"] as? [String: Any] {
            properties = p
        } else {
            NSLog("Error: Topic does not have properties")
        }
    }
    

    func toPublishObj() -> [String: Any] {
        return [
            "name": name,
            "type": type,
            "pubuid": uid,
            "properties": properties
        ]
    }

    func toUnpublishObj() -> [String: Int] {
        return [
            "pubuid": uid
        ]
    }

    func getTypeIdx() -> Int {
        if let index = NTTopic.typestrIdxLookup[type] {
            return index
        } else {
            return 5 // Default to binary
        }
    }
}