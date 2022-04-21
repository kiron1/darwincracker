import Foundation
import Virtualization
import os

class Machine {
    var logger: Logger
    var virtualMachine: VZVirtualMachine

    init(configuration: VZVirtualMachineConfiguration) {
        logger = Logger(subsystem: "cc.colorto.DarwinCracker", category: "machine")

        logger.info("Creating virtual machine")
        virtualMachine = VZVirtualMachine(configuration: configuration)

        let delegate = MachineDelegate(logger: logger)
        virtualMachine.delegate = delegate
    }

    func start() {
        virtualMachine.start { result in
            if case let .failure(error) = result {
                self.logger.error("Failed to start the virtual machine: \(error.localizedDescription)")
                print("Failed to start the virtual machine: \(error.localizedDescription)")
                exit(EXIT_FAILURE)
            }
        }
    }
}

class MachineDelegate: NSObject {
    var logger: Logger

    fileprivate init(logger: Logger) {
        self.logger = logger
    }

}

extension MachineDelegate: VZVirtualMachineDelegate {
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        logger.info("The guest shut down. Exiting.")
        exit(EXIT_SUCCESS)
    }
}

