**Components Diagram**
![Components diagram](draw/poc-fw-ado-agent.drawio.svg)

**Reference**

**Self-hosted Agent (Azure Container Instance)**
- [Run a self-hosted agent in Docker](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops)
- [Register an agent using a service principal](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/service-principal-agent-registration?view=azure-devops)
- [Unattended config](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/windows-agent?view=azure-devops&tabs=IP-V4#unattended-config)

**Network**
- [Communication with Azure Pipelines](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/agents?view=azure-devops&tabs=yaml%2Cbrowser#communication)
- Domain Name resolution: [Link the private DNS zone with all virtual networks that need to resolve your private endpoint DNS name](
https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network#name-resolution:~:text=Link%20the%20private%20DNS%20zone%20with%20all%20virtual%20networks%20that%20need%20to%20resolve%20your%20private%20endpoint%20DNS%20name); [Private DNS zones are typically hosted centrally in the same Azure subscription where the hub virtual network deploys.](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/private-link-and-dns-integration-at-scale#private-link-and-dns-integration-in-hub-and-spoke-network-architectures:~:text=Private%20DNS%20zones%20are%20typically%20hosted%20centrally%20in%20the%20same%20Azure%20subscription%20where%20the%20hub%20virtual%20network%20deploys.)
- Firewall: [Determine whether you use a network virtual appliance such as Azure Firewall](https://learn.microsoft.com/en-us/azure/architecture/networking/guide/private-link-hub-spoke-network#determine-whether-you-use-a-network-virtual-appliance-such-as-azure-firewall)
- [Communication through an NVA](https://learn.microsoft.com/en-us/azure/architecture/networking/architecture/hub-spoke?tabs=cli#communication-through-an-nva)
- [Firewall Configuration recommendations](https://learn.microsoft.com/en-us/azure/well-architected/service-guides/azure-firewall?toc=%2Fazure%2Ffirewall%2Ftoc.json&bc=%2Fazure%2Ffirewall%2Fbreadcrumb%2Ftoc.json#configuration-recommendations)
- If you're running a firewall and your code is in Azure Repos. These articles has information about which domain URLs and IP addresses your private agent needs to communicate with. [Azure Pipelines self-hosted agents](https://learn.microsoft.com/en-us/azure/devops/organizations/security/allow-list-ip-url?view=azure-devops&tabs=IP-V4#azure-pipelines-self-hosted-agents); [Allowed IP addresses and domain URLs](https://learn.microsoft.com/en-us/azure/devops/organizations/security/allow-list-ip-url?view=azure-devops&tabs=IP-V4)
