# Project Phoenix: High-Availability Trading Infrastructure

A cost-optimized, enterprise-grade Hub-and-Spoke landing zone on Azure. This environment is designed to host an ephemeral ("Phoenix") algorithmic trading bot that scales to zero to minimize costs while maintaining strict governance and security.

## Network Architecture

The architecture uses a centralized Hub to govern traffic and decentralized Spokes to isolate workloads.

```mermaid
graph TD
    subgraph "Azure Cloud"
        direction TB
        
        subgraph "Hub VNet (10.0.0.0/16)"
            NVA[Ubuntu Linux Router/NVA]
            MA[Management/Jumpbox Subnet]
            LA[Log Analytics Workspace]
        end

        subgraph "Data Spoke (10.2.0.0/16)"
            SQL[(Azure SQL - Private Endpoint)]
            KV[Key Vault - Service Endpoint]
        end

        subgraph "Compute Spoke (10.1.0.0/16)"
            K3s[K3s Cluster - Spot Instances]
        end

        %% Connections
        NVA <--> |VNet Peering| K3s
        NVA <--> |VNet Peering| SQL
        K3s --> |Force Tunneling 0.0.0.0/0| NVA
        NVA --> |Egress| Internet((Internet))
    end


## Design Decisions and Philosophy

### 1. Networking: The Hub-and-Spoke Choice
* **Centralized Egress:** All traffic from Spokes is "Force Tunneled" through the Hub NVA via User-Defined Routes (UDRs). This allows for a single point of inspection and logging.
* **Scalable IPAM:** Using 10.x.0.0/16 increments allows for over 65,000 IPs per spoke, simplifying routing table management as the project grows.

### 2. The NVA Pivot (Cost Management)
Originally, I attempted an OPNsense deployment. However, due to FreeBSD agent signaling issues in Azure (TypeError in SSH injection), I pivoted to a hardened Ubuntu 22.04 Router.

* **Cost Savings:** Using a Standard_B1s Linux VM instead of Azure Firewall saved ~$300/month in lab fees.
* **Configuration:** Implemented Kernel IP Forwarding and iptables masquerading via Cloud-init.

### 3. Security: ACLs vs. Private Link
* **Azure SQL:** Utilizes Private Endpoints ($7.50/mo) for maximum security on the data layer.
* **Key Vault:** Utilizes Service Endpoints + VNet ACLs (Free). Access is restricted at the network layer to only the Hub LAN and Compute Spoke subnets, effectively isolating secrets without the Private Link surcharge. Since these are Alpaca Paper accounts and no real capital is at stake, the Private Endpoint is unnecessary at this stage.

##Lessons Learned
The Asymmetric Routing Trap
Problem: Ping worked from Hub to Spoke, but failed from Spoke to Hub.

Discovery: I forgot to create a return route in the Hub's route table. The NVA received the packet but didn't know how to send the "reply" back to the specific Spoke subnet.

Resolution: Mastered the use of Azure Effective Routes tool to visualize the routing hop-by-hop.

The Ghost Bastion Outage
Problem: Bastion Developer SKU returned InternalServerError.

Research: Discovered a regional service degradation in West US (2/7/26).

Adaptation: I pivoted to a temporary "Just-In-Time" (JIT) whitelisted SSH access on the NVA, ensuring I could continue development while the platform stabilized.

## Deployment and Usage

### 1. Infrastructure (Terraform)

```bash
terraform init
terraform apply -target=module.network_hub
terraform apply # Deploys spokes and data layers

## Cost Breakdown (~$35/mo)

| Component | Cost | Optimization |
| :--- | :--- | :--- |
| **NVA (B1s)** | ~$8/mo | Hardened Linux vs Azure FW |
| **Azure SQL** | ~$7.50/mo | Basic Tier + Private Link |
| **Log Analytics** | Pay-As-You-Go | 30-day Retention |
| **K3s Nodes** | ~$5/mo | Spot Instances (90% discount) |

## Roadmap

- [ ] Finish refactor of Kubernetess trading bot.
- [ ] Implement GitHub Actions for "Phoenix" ephemeral deployment.
- [ ] Add Cloudflare Tunnels for secure dashboard access.
- [ ] Configure Azure Monitor alerts for Budget > 100% (Kill-switch).