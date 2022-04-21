import ArgumentParser
import Foundation
import Virtualization

@main
struct DarwinCracker: ParsableCommand {
    static var configuration = CommandConfiguration(
        abstract: "A utility for running virtual machines.",
        version: "0.1.0",
        subcommands: [Info.self, Run.self, Print.self])
}

extension DarwinCracker {
    struct Info: ParsableCommand {
        static var configuration =
            CommandConfiguration(abstract: "Print information about supported virutal machines.")

        mutating func run() {
            print("Minimum allowed CPUs: \(VZVirtualMachineConfiguration.minimumAllowedCPUCount)")
            print("Minimum allowed CPUs: \(VZVirtualMachineConfiguration.maximumAllowedCPUCount)")
            print("Minimum allowed RAM: \(VZVirtualMachineConfiguration.minimumAllowedMemorySize / 1024 / 1024) MiB")
            print("Maximum allowed RAM: \(VZVirtualMachineConfiguration.maximumAllowedMemorySize / 1024 / 1024) MiB")

            let networkInterfaces = VZBridgedNetworkInterface.networkInterfaces
            print("Available interfaces for bridging: \(networkInterfaces.count)")
            for interface in networkInterfaces {
                print("  - \(interface.identifier) (\(interface.localizedDisplayName ?? ""))")
            }
        }
    }

    struct Run: ParsableCommand {
        static var configuration =
            CommandConfiguration(abstract: "Run a virtual machine bundle.")

        @Argument(help: "Path to the virtual machine bundle.")
        var path: String

        mutating func run() throws {
            let bundleURL = URL(fileURLWithPath: path, isDirectory: true)
            let bundle = try MachineBundle.fromURL(url: bundleURL).get()
            let machine = try bundle.assemble().get()

            machine.start()

            RunLoop.main.run(until: Date.distantFuture)
        }
    }

    struct Print: ParsableCommand {
        static var configuration =
            CommandConfiguration(abstract: "Print information about a virtual machine bundle.")

        @Argument(help: "Path to the virtual machine bundle.")
        var path: String

        mutating func run() throws {
            var bundleURL = URL(fileURLWithPath: path, isDirectory: true)
            bundleURL.appendPathComponent("Machine.plist")
            let configuration = try MachineConfiguration.fromFile(url: bundleURL).get()
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configuration)
            let info = String(data: data, encoding: .utf8)
            if let info = info {
                print(info)
            }
        }
    }
}
