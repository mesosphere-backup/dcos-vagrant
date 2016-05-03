# Architecture

**Networking**

- NatNetwork
  - DHCP
  - 10.0.1.0/24
  - No static port forwarding

- vboxnet0 ('VirtualBox Host-Only Ethernet Adapter' on Windows)
  - No DHCP
  - IP4 Address 192.168.65.1
  - Netmask 255.255.255.0

## Architecture Diagram

![Vagrant Diagram](./dcos_vagrant_setup.png?raw=true)