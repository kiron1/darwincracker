import Foundation

struct MachineConfiguration: Codable {
    var cpuCount: Int
    var memorySize: UInt64
    var boot: Boot

    var storageDevices: [StorageDevice]?

    var networkDevices: [NetworkDevice]?

    // private enum CodingKeys: String, CodingKey {
    //     case cpuCount = "CPUCount"
    //     case memorySize = "MemorySize"
    //     case boot = "Boot"
    // }

    static func fromFile(url: URL) -> Result<MachineConfiguration, Error> {
        let data = Result { try Data(contentsOf: url) }
        return data.flatMap { data in
            let decoder = PropertyListDecoder()
            return Result {
                try decoder.decode(MachineConfiguration.self, from: data)
            }
        }
    }
}

struct Boot: Codable {
    var kernel: String
    var initrd: String
    var cmdline: String
}

struct StorageDevice : Codable {
    var deviceIdentifier: String
    var path: String
    var readOnly: Bool
}

enum NetworkDeviceType : String, Codable, CaseIterable {
    case nat = "NAT"
    case bridge = "Bridge"
}

struct NetworkDevice : Codable {
    var type: NetworkDeviceType
    var identifier: String?
}
