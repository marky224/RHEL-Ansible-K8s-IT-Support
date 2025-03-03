# RHEL-Ansible-K8s-IT-Support

Welcome to my IT support and automation project repository! This project is focused on building a virtualized network environment with automation scripts to streamline provisioning and management. The goal is to simulate a robust enterprise-grade network, leveraging tools like Red Hat Enterprise Linux (RHEL), Ansible, Active Directory, Kubernetes, and now Cisco and F5 technologies.

## Project Overview
This repository contains scripts, configurations, and documentation for setting up and managing a virtualized network environment. The network currently includes a mix of Windows and Linux systems, with plans to integrate Cisco routing equipment and F5 Load Balancers to enhance functionality and align with real-world enterprise needs, such as those in financial institutions requiring PCI DSS compliance.

## Objectives
- Automate the provisioning of a virtualized network using Ansible for scalability and efficiency.
- Integrate Active Directory for centralized domain authentication.
- Incorporate Cisco routing equipment for network connectivity and F5 Load Balancers for traffic management, reflecting enterprise-grade infrastructure.

### Current Network Setup
- **Windows 11 Pro VM**: A fully operational virtual machine running Windows 11 Pro, serving as a client or testing workstation.
- **RHEL 9 Workstation VM**: A Red Hat Enterprise Linux 9 workstation VM, set up for administrative tasks and testing.
- **Active Directory Domain Controller**: Recently completed (the hardest part!), this Windows-based VM manages domain authentication for the network.
- **Ansible Control Node**: In progress, this RHEL-based node will handle most automation tasks within the network once finalized.

### Planned Additions
- **Cisco Routing Equipment**: Scripts will be developed to automate the provisioning and configuration of a Cisco router virtual image, ensuring network connectivity and routing across the virtual environment.
- **F5 Load Balancers**: Scripts will also automate the provisioning of an F5 Load Balancer virtual image, enabling traffic distribution and load balancing for simulated web applications, with a focus on security and reliability.

## Next Steps
1. **Finalize the Ansible Control Node**: Complete the setup and configuration of the Ansible control node on the RHEL 9 VM. This will serve as the central hub for automating network provisioning and management tasks.
2. **Develop Cisco Router Automation Scripts**: Create Ansible playbooks to provision and configure the Cisco router virtual image, ensuring it integrates with the existing network for routing and connectivity.
3. **Develop F5 Load Balancer Automation Scripts**: Build scripts to automate the provisioning and setup of the F5 Load Balancer virtual image, configuring it to handle traffic distribution within the network.
4. **Test Network Integration**: Validate that the Active Directory Domain Controller, Cisco router, and F5 Load Balancer work seamlessly with the Windows 11 Pro and RHEL 9 VMs.
5. **Documentation**: Update this README and add detailed guides for each component’s setup and automation process.

## Progress Update
- **Completed**: Active Directory Domain Controller setup (the most challenging component), Windows 11 Pro VM, and RHEL 9 Workstation VM.
- **In Progress**: Finalizing the Ansible control node, which will take on the bulk of the network automation workload.
- **Upcoming**: Automation scripts for Cisco routing equipment and F5 Load Balancers.

## Tools and Technologies
- **Red Hat Enterprise Linux 9**: Base OS for the workstation and Ansible control node.
- **Ansible**: Automation tool for provisioning and managing network components.
- **Active Directory**: Domain authentication and user management.
- **Windows 11 Pro**: Client OS for testing and simulation.
- **Cisco Router Virtual Image**: Network routing and connectivity.
- **F5 Load Balancer Virtual Image**: Traffic distribution and load balancing.
- **GitHub**: Version control and project documentation.

## Contributing
Feel free to fork this repository, submit issues, or suggest improvements via pull requests. This is a learning project, and collaboration is welcome!

## License
This project is licensed under the MIT License – see the [LICENSE](LICENSE) file for details.
