# DarwinCracker

## Build


Run the included `Makefile` using `make`. The default target will build a release version.

```sh
make
```

## Install

```sh
sudo make install
```

## Usage

If we run `DarwinCraker` without any options it will show the usage:

```sh
DarwinCracker
```

We can show some informations using the `info` verb:

```sh
DarwinCracker info
```

We can confirm that our virtual machine configuration is correct with:

```sh
DarwinCracker print SomeVirtualMachineBundle.machine
```

Finally we can run our virtual machine with:

```sh
DarwinCracker run SomeVirtualMachineBundle.machine
```

To view any produced log messages, we can run:

```sh
log stream --level debug --predicate 'subsystem == "cc.colorto.DarwinCracker"'
```

## How-to guides and examples

### Create your first virtual machine

Here we will create a virtual machine based on the Ubuntu 21.04 cloud image.
The output will be a directory named `Ubuntu.machine` (can be adapted to our
own preferences) which will contain the virtual machine configuration. The
virtual machine configuration contains a file called `Machine.plist` which
describes the virtual hardware associated with this machine and the necessary
files like Kernel and RAM disk as well as optional files like a virtual hard
disk.

Prepare a directory which will be our virtual machine bundle:

```sh
mkdir Ubuntu.machine
```

Download the kernel and ram disk into our bundle (from above):

```sh
curl -Lo Ubuntu.machine/vmlinuz https://cloud-images.ubuntu.com/releases/hirsute/release/unpacked/ubuntu-21.04-server-cloudimg-amd64-vmlinuz-generic
curl -Lo Ubuntu.machine/initrd https://cloud-images.ubuntu.com/releases/hirsute/release/unpacked/ubuntu-21.04-server-cloudimg-amd64-initrd-generic
```

Create the virtual machine configuration (Plist format):

```sh
/usr/libexec/PlistBuddy -c "Add :cpuCount integer 2" Ubuntu.machine/Machine.plist
/usr/libexec/PlistBuddy -c "Add :memorySize integer 2048" Ubuntu.machine/Machine.plist
/usr/libexec/PlistBuddy -c "Add :boot:kernel string vmlinuz" Ubuntu.machine/Machine.plist
/usr/libexec/PlistBuddy -c "Add :boot:initrd string initrd" Ubuntu.machine/Machine.plist
/usr/libexec/PlistBuddy -c "Add :boot:cmdline string 'console.hvc0'" Ubuntu.machine/Machine.plist
```

We can confirm the `Machine.plist` file is correct with the following command:

```sh
/usr/libexec/PlistBuddy -c "Print" Ubuntu.machine/Machine.plist
```

### Run a virtual machine as a daemon

We can have a virtual machine running in the background using a launch agent:


Use some variables for easy adjustments:

```sh
VM_LABEL=org.example.UbuntuMachine
VM_AGENT_PLIST=${HOME}/Library/LaunchAgents/${VM_LABEL}.plist
```

Create a launch agents file:

```sh
/usr/libexec/PlistBuddy -c "Add :Label string ${VM_LABEL}" "${VM_AGENT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :RunAtLoad bool true" "${VM_AGENT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string /bin/sh" "${VM_AGENT_PLIST}"
/usr/libexec/PlistBuddy -c "Add :ProgramArguments:1 string -c" "${VM_AGENT_PLIST}"
/usr/libexec/PlistBuddy -c 'Add :ProgramArguments:2 string "DarwinCracker run $HOME/Ubuntu.machine"' "${VM_AGENT_PLIST}
```

Install, enable and start the virtual machine agent:

```sh
launchctl bootstrap "gui/$(id -u)" "${VM_AGENT_PLIST}"
launchctl enable "gui/$(id -u)/${VM_LABEL}"
launchctl print "gui/$(id -u)/${VM_LABEL}"
launchctl kickstart -kp "gui/$(id -u)/${VM_LABEL}"
```

## Developer Resources

### Swift Language
- [Swift Language Guide](https://docs.swift.org/swift-book/LanguageGuide/TheBasics.html)

### Frameworks

- [Foundation](https://developer.apple.com/documentation/foundation)
- [Hypervisor.framework](https://developer.apple.com/documentation/hypervisor)
- [Virtualization.framework](https://developer.apple.com/documentation/virtualization)

### Distribution

- [Signing a Mac Product For Distribution](https://developer.apple.com/forums/thread/128166)
