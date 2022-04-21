import Foundation
import Virtualization
import os

enum MachineError : Error {
    case bundleInvlaid
    case machineBundleNotFound(URL)
    case kernelNotFound(URL)
    case initrdNotFound(URL)
}

struct MachineBundle {
    var bundleURL: URL
    var configuration: MachineConfiguration

    fileprivate init(bundleURL: URL, configuration: MachineConfiguration) {
        self.bundleURL = bundleURL
        self.configuration = configuration
    }

    static func fromURL(url: URL) -> Result<MachineBundle, Error> {
        let machinePlistURL = url.appendingPathComponent("Machine.plist")
        if !FileManager.default.fileExists(atPath: machinePlistURL.path) {
            return .failure(MachineError.machineBundleNotFound(machinePlistURL))
        }
        let configuration = MachineConfiguration.fromFile(url: machinePlistURL)
        return configuration.map { configuration in
            return MachineBundle.init(bundleURL: url, configuration: configuration)
        }
    }

    func assemble() -> Result<Machine, Error> {
        let kernelURL = URL(fileURLWithPath: bundleURL.appendingPathComponent(configuration.boot.kernel).absoluteURL.path)
        let initrdURL = URL(fileURLWithPath: bundleURL.appendingPathComponent(configuration.boot.initrd).absoluteURL.path)
        if !FileManager.default.fileExists(atPath: kernelURL.path) {
            return .failure(MachineError.kernelNotFound(kernelURL))
        }
        if !FileManager.default.fileExists(atPath: initrdURL.path) {
            return .failure(MachineError.initrdNotFound(initrdURL))
        }
        let cmdline = self.configuration.boot.cmdline

        let configuration = VZVirtualMachineConfiguration()
        configuration.cpuCount = self.configuration.cpuCount
        configuration.memorySize = self.configuration.memorySize * 1024 * 1024
        configuration.serialPorts = [ createConsoleConfiguration() ]
        configuration.bootLoader = createBootLoader(
            kernelURL: kernelURL,
            initrdURL: initrdURL,
            cmdline: cmdline)
        configuration.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

        if let storageDevices = self.configuration.storageDevices {
            configuration.storageDevices = createStorageDevices(devices: storageDevices, root:bundleURL)
        }

        if let networkDevices = self.configuration.networkDevices {
            configuration.networkDevices = createNetworkDevices(devices: networkDevices)
        }
        
        do {
            try configuration.validate()
        } catch(let error) {
            return .failure(error)
        }

        let machine = Machine(configuration: configuration)

        return .success(machine)
    }
}


/// Creates a Linux bootloader with the given kernel and initial ramdisk.
func createBootLoader(kernelURL: URL, initrdURL: URL, cmdline: String) -> VZBootLoader {
    let bootLoader = VZLinuxBootLoader(kernelURL: kernelURL)

    bootLoader.initialRamdiskURL = initrdURL
    bootLoader.commandLine = cmdline

    return bootLoader
}

/// Creates a serial configuration object for a virtio console device,
/// and attaches it to stdin and stdout.
func createConsoleConfiguration() -> VZSerialPortConfiguration {
    let consoleConfiguration = VZVirtioConsoleDeviceSerialPortConfiguration()

    let inputFileHandle = FileHandle.standardInput
    let outputFileHandle = FileHandle.standardOutput

    // Put stdin into raw mode, disabling local echo, input canonicalization,
    // and CR-NL mapping.
    var attributes = termios()
    tcgetattr(inputFileHandle.fileDescriptor, &attributes)
    attributes.c_iflag &= ~tcflag_t(ICRNL)
    attributes.c_lflag &= ~tcflag_t(ICANON | ECHO)
    tcsetattr(inputFileHandle.fileDescriptor, TCSANOW, &attributes)

    let stdioAttachment = VZFileHandleSerialPortAttachment(fileHandleForReading: inputFileHandle,
                                                           fileHandleForWriting: outputFileHandle)

    consoleConfiguration.attachment = stdioAttachment

    return consoleConfiguration
}

func createStorageDevices(devices: [StorageDevice], root: URL) -> [VZVirtioBlockDeviceConfiguration] {
    let sd: [VZVirtioBlockDeviceConfiguration] = devices.compactMap { dev in 
        let path = URL(fileURLWithPath: root.appendingPathComponent(dev.path).absoluteURL.path)
        let attachment = Result { try VZDiskImageStorageDeviceAttachment(url: path, readOnly: dev.readOnly) }
        let deviceConfig = attachment.map { attachment in 
            return VZVirtioBlockDeviceConfiguration(attachment: attachment)
        }
        return try? deviceConfig.get()
    }
    return sd
}

func createNetworkDevices(devices: [NetworkDevice]) -> [VZVirtioNetworkDeviceConfiguration] {
    let nd: [VZVirtioNetworkDeviceConfiguration] = devices.compactMap { dev -> VZVirtioNetworkDeviceConfiguration in 
        let devConf = VZVirtioNetworkDeviceConfiguration()
        if dev.type == .nat {
            devConf.attachment = VZNATNetworkDeviceAttachment()
        } else if dev.type == .bridge {
            let networkInterfaces = VZBridgedNetworkInterface.networkInterfaces
            // TODO: error handling when dev.identifier is nil.
            let netIf = networkInterfaces.first(where: {$0.identifier == dev.identifier ?? "en0"})
            if let netIf = netIf {
                devConf.attachment = VZBridgedNetworkDeviceAttachment(interface: netIf)
            }
        }
        return devConf
    }
    return nd
}
