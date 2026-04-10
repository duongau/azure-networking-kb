# Private AKS Cluster Networking

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

This pattern covers the complete networking architecture for a private AKS cluster: API server behind a private endpoint, node pools in dedicated subnets, ingress via Application Gateway (AGIC) or internal load balancer, egress through NAT Gateway or Azure Firewall, and hybrid DNS resolution for the private API server FQDN. It is the most asked-about cross-service networking pattern in Azure.

---

## Architecture diagram

```
                    ON-PREMISES / ADMIN WORKSTATION
                              │
                    ExpressRoute / VPN / Bastion
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          HUB VNET (10.0.0.0/16)                             │
│                                                                             │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────────────────────┐ │
│  │ GatewaySubnet    │  │ AzureBastionSub. │  │ AzureFirewallSubnet        │ │
│  │ /27              │  │ /26              │  │ /26                        │ │
│  │ VPN/ER Gateway   │  │ Bastion Premium  │  │ Azure Firewall Standard    │ │
│  └──────────────────┘  └──────────────────┘  │ (or NAT Gateway)           │ │
│                                              └────────────────────────────┘ │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ DNS Resolver Subnets (/28 each)                                       │  │
│  │ Inbound EP: 10.0.1.4 ← on-prem conditional forwarder                  │  │
│  │ Outbound EP: → corp.contoso.com forwarding                            │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  Private DNS Zones (linked to hub):                                         │
│  - privatelink.{region}.azmk8s.io  (AKS API server)                        │
│  - privatelink.azurecr.io          (ACR)                                    │
│  - privatelink.blob.core.windows.net (storage)                              │
└─────────────────────────────────────────────────────────────────────────────┘
                              │
                         VNet Peering
                              │
┌─────────────────────────────────────────────────────────────────────────────┐
│                          SPOKE VNET (10.1.0.0/16)                           │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ AppGatewaySubnet (/24)                                                │  │
│  │                                                                       │  │
│  │  ┌─────────────────────────────────────────┐                          │  │
│  │  │ Application Gateway WAF_v2              │                          │  │
│  │  │ - Public frontend (optional)            │◄──── Internet traffic    │  │
│  │  │ - Private frontend                      │                          │  │
│  │  │ - AGIC managed (reads Ingress objects)  │                          │  │
│  │  └─────────────────────────────────────────┘                          │  │
│  │                        │                                              │  │
│  │                 Backend pool: AKS pod IPs                             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                              │                                              │
│  ┌───────────────────────────────────────────────────────────────────────┐  │
│  │ AKS Node Subnet (/21 — large for Azure CNI)                           │  │
│  │                                                                       │  │
│  │  ┌─────────────────────────────────────────────────────────────────┐  │  │
│  │  │ AKS PRIVATE CLUSTER                                             │  │  │
│  │  │                                                                 │  │  │
│  │  │  ┌─────────────────┐  ┌─────────────────┐                       │  │  │
│  │  │  │ System Node Pool│  │ User Node Pool  │                       │  │  │
│  │  │  │ (3+ nodes)      │  │ (autoscale 3-50)│                       │  │  │
│  │  │  └─────────────────┘  └─────────────────┘                       │  │  │
│  │  │                                                                 │  │  │
│  │  │  API Server: accessed via Private Endpoint only                 │  │  │
│  │  │  Outbound: NAT Gateway / Azure Firewall                         │  │  │
│  │  └─────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                       │  │
│  │  Private Endpoint (10.1.10.5): → AKS API server                       │  │
│  │  Private Endpoint (10.1.10.6): → Azure Container Registry             │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
│                                                                             │
│  Route table on AKS subnet:                                                 │
│  - 0.0.0.0/0 → Azure Firewall (10.0.0.4) OR NAT Gateway                    │
│  - BGP propagation: disabled                                                │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Component breakdown

### 1. Private AKS cluster

A **private cluster** has no public IP on the API server. The control plane is accessible only via a Private Endpoint injected into your VNet.

| Setting | Value | Notes |
|---|---|---|
| `--enable-private-cluster` | Required | API server gets a private endpoint |
| `--private-dns-zone` | `system` (default) / `none` / `{resource-id}` | `system` = Azure creates zone; BYO zone for custom DNS |
| Public FQDN | Disabled by default; can enable `--enable-public-fqdn` | Allows public DNS resolution but still requires PE for access |
| Authorized IP ranges | Not applicable | Private cluster doesn't use authorized IP ranges |

### 2. Node pool subnets

AKS nodes need IPs from a VNet subnet. Subnet sizing depends on network plugin:

| Network plugin | IP consumption | Subnet sizing guidance |
|---|---|---|
| **Azure CNI** | 1 IP per node + 1 IP per pod | Large subnets required: /21 for 100 nodes × 30 pods |
| **Azure CNI Overlay** | 1 IP per node (pods use overlay) | Smaller subnets: /24 for 250 nodes |
| **Kubenet** | 1 IP per node (pods use internal NAT) | Smaller subnets: /24 for 250 nodes |

**Recommended:** Azure CNI Overlay for new clusters — combines Azure CNI networking model with efficient IP usage.

**Calculation example (Azure CNI classic):**
```
Nodes: 50 (max)
Max pods per node: 30 (default)
IPs needed: 50 × 30 = 1,500 pod IPs + 50 node IPs = 1,550
Subnet size: /21 (2,046 usable IPs)
```

### 3. Ingress: AGIC (Application Gateway Ingress Controller)

AGIC reads Kubernetes `Ingress` resources and configures Application Gateway automatically.

| Deployment option | Method |
|---|---|
| **AKS add-on** | `az aks enable-addons --addons ingress-appgw --appgw-subnet-id ...` |
| **Helm** | Manually deploy AGIC pod; more configuration flexibility |

**Requirements:**
- App Gateway v2 (Standard_v2 or WAF_v2) in a **dedicated subnet** (cannot share with AKS nodes)
- AGIC needs network line-of-sight to AKS API server — with private cluster, AGIC pod runs inside the cluster, so this is automatic
- Managed identity or service principal with permissions to update App Gateway

**Subnet sizing:** /24 recommended for App Gateway (supports 125 autoscale instances).

### 4. Egress: NAT Gateway or Azure Firewall

Private cluster nodes need outbound internet access to pull images, contact Azure APIs, and more.

| Egress option | Use case | Configuration |
|---|---|---|
| **NAT Gateway** | Simplest; high SNAT port capacity (64,512/IP) | Associate NAT GW with AKS node subnet |
| **Azure Firewall** | Centralized egress with FQDN filtering, threat intel | UDR `0.0.0.0/0 → Firewall`; configure required FQDN rules |
| **User-defined outbound** | Full control; no Azure-managed outbound | `--outbound-type userDefinedRouting` + Firewall/NAT GW |

**Azure Firewall required FQDNs for AKS:** [VERIFY — reference wiki/services/azure-firewall.md for full list]

| FQDN | Port | Purpose |
|---|---|---|
| `*.hcp.{region}.azmk8s.io` | 443 | AKS API server communication |
| `mcr.microsoft.com` | 443 | Microsoft Container Registry |
| `*.data.mcr.microsoft.com` | 443 | MCR data endpoint |
| `management.azure.com` | 443 | Azure Resource Manager |
| `login.microsoftonline.com` | 443 | Entra ID authentication |
| `packages.microsoft.com` | 443 | Microsoft packages |
| `acs-mirror.azureedge.net` | 443 | AKS node components |

### 5. DNS: Private DNS zone for API server

Private cluster API server FQDN (e.g., `mycluster.privatelink.eastus.azmk8s.io`) must resolve to the Private Endpoint's private IP.

| DNS option | How it works |
|---|---|
| **System-managed (default)** | AKS creates private DNS zone in node resource group; links to AKS VNet automatically |
| **Bring your own zone** | You create `privatelink.{region}.azmk8s.io` zone; AKS adds A record |
| **None** | No private DNS zone; you manage DNS manually (host files, custom DNS) |

**For hybrid resolution (on-premises `kubectl` access):**
1. Link the private DNS zone to **hub VNet** where DNS Private Resolver lives
2. Configure on-premises DNS with conditional forwarder: `privatelink.{region}.azmk8s.io → 10.0.1.4` (resolver inbound endpoint)

### 6. Bastion for kubectl access

With no public IP on API server, you need a private path for `kubectl`:

| Access method | Configuration |
|---|---|
| **Azure Bastion (native client)** | Bastion Standard/Premium; `az network bastion tunnel`; tunnel to jump VM |
| **Jump VM** | VM in hub VNet peered to AKS VNet; SSH/RDP via Bastion; run kubectl from VM |
| **ExpressRoute / VPN** | On-premises workstation with VPN client; DNS resolves API server to private IP |

### 7. ACR: Private Endpoint for image pulls

AKS nodes should pull images from ACR via Private Endpoint, not public internet.

| Configuration step | Detail |
|---|---|
| ACR SKU | Premium (required for Private Endpoint) |
| Private Endpoint | Create in AKS VNet or hub VNet |
| Private DNS Zone | `privatelink.azurecr.io`; link to VNet |
| ACR public access | Disable (`--public-network-enabled false`) |
| AKS → ACR auth | `az aks update --attach-acr` (managed identity) |

---

## Key configuration gotchas

### Gotcha 1: Private cluster + custom DNS = API server resolution failure

**Symptom:** AGIC crashes; nodes can't register; kubectl times out.

**Cause:** AKS nodes use VNet DNS servers to resolve API server FQDN. If custom DNS (not Azure-provided) is configured on the VNet, and it doesn't have a conditional forwarder to the private DNS zone, resolution fails.

**Fix:**
1. Link `privatelink.{region}.azmk8s.io` zone to VNet with custom DNS server
2. Configure conditional forwarder on custom DNS server for `privatelink.{region}.azmk8s.io` → Azure DNS (168.63.129.16) or DNS Private Resolver inbound endpoint

### Gotcha 2: AGIC + private cluster network path

**Symptom:** AGIC pod fails to sync with App Gateway.

**Cause:** AGIC needs to update App Gateway configuration via ARM API. AGIC pod runs in AKS; it needs outbound access to `management.azure.com`.

**Fix:** Ensure Firewall rules (if using Azure Firewall egress) allow `management.azure.com:443`.

### Gotcha 3: Cluster upgrade requires extra IPs (node surge)

**Symptom:** Upgrade fails with "insufficient IP addresses."

**Cause:** AKS creates surge nodes during upgrade (default: 1 extra node per node pool). With Azure CNI, each surge node needs node IP + pod IPs.

**Fix:** Ensure subnet has headroom:
```
Headroom = (max_surge_nodes) × (1 + max_pods_per_node)
Example: 1 surge × 31 = 31 IPs headroom per node pool
```

### Gotcha 4: NSG on AKS subnet blocks Azure Load Balancer probes

**Symptom:** Internal Load Balancer services show unhealthy backends.

**Cause:** Health probes from Azure Load Balancer (source: `168.63.129.16`) are blocked by NSG.

**Fix:** NSG inbound rule: Allow source `AzureLoadBalancer` to AKS subnet on probe port.

### Gotcha 5: Network policy conflicts

**Symptom:** Pods can't communicate; ingress blocked.

**Cause:** Azure Network Policy or Calico policy denying traffic not explicitly allowed.

**Fix:** Create NetworkPolicy objects allowing required flows (ingress from App Gateway CIDR, DNS egress, etc.).

---

## Network policy: Azure vs Calico

| Feature | Azure Network Policy | Calico |
|---|---|---|
| Layer | L3/L4 (IP, port) | L3/L4/L7 (with Calico Enterprise) |
| Egress policies | ✅ Supported | ✅ Supported |
| FQDN egress rules | ❌ | ✅ (Calico Enterprise) |
| GUI management | Azure Portal (limited) | Calico UI (Enterprise) |
| Open-source | ❌ | ✅ |

**Recommendation:** Start with Azure Network Policy for simplicity. Move to Calico if you need advanced features (FQDN policies, L7 rules, global network sets).

---

## Subnet sizing reference

| Component | Subnet | Size | Notes |
|---|---|---|---|
| AKS nodes (Azure CNI) | AksSubnet | /21 or larger | 1 IP/node + 1 IP/pod |
| AKS nodes (CNI Overlay) | AksSubnet | /24 | 1 IP/node only |
| Application Gateway | AppGwSubnet | /24 | Up to 125 instances |
| Private Endpoints | PeSubnet (or AksSubnet) | /28 | 1 IP per PE |
| Azure Firewall | AzureFirewallSubnet | /26 | Exact name required |
| DNS Resolver inbound | DnsInboundSubnet | /28 | Delegated to dnsResolvers |
| DNS Resolver outbound | DnsOutboundSubnet | /28 | Delegated to dnsResolvers |
| Bastion | AzureBastionSubnet | /26 | Exact name required |

---

## Decision checklist

| # | Question | Expected answer for this pattern |
|---|---|---|
| 1 | Should AKS API server be publicly accessible? | No — private cluster |
| 2 | How will admins access kubectl? | Bastion tunnel / Jump VM / VPN |
| 3 | How will nodes pull container images? | ACR via Private Endpoint |
| 4 | How will nodes reach the internet (for updates, telemetry)? | NAT Gateway or Azure Firewall |
| 5 | Is centralized egress filtering required? | Yes → Azure Firewall; No → NAT Gateway |
| 6 | What ingress controller? | AGIC (App Gateway) or internal LB + nginx/traefik |
| 7 | What network plugin? | Azure CNI Overlay (recommended) or Azure CNI |
| 8 | Is on-premises kubectl access needed? | Yes → DNS Private Resolver + ER/VPN |

---

## Service limits reference [VERIFY all]

| Limit | Value |
|---|---|
| Nodes per cluster | 5,000 [VERIFY] |
| Pods per node (Azure CNI) | 250 max; 30 default [VERIFY] |
| Pods per node (Kubenet) | 110 max [VERIFY] |
| Private Endpoints per VNet | 1,000 (default); 5,000 (High Scale) |
| App Gateway max instances | 125 |
| NAT Gateway SNAT ports per IP | 64,512 |
| Azure Firewall SNAT ports per IP | 2,496 |

---

## Related pages

| Page | Relationship |
|---|---|
| [Application Gateway](../services/application-gateway.md) | AGIC, WAF_v2, backend pools |
| [Private Link](../services/private-link.md) | Private Endpoints for AKS API server and ACR |
| [Azure DNS](../services/dns.md) | Private DNS zones for AKS and ACR |
| [Azure Firewall](../services/azure-firewall.md) | Egress FQDN filtering; required rules for AKS |
| [NAT Gateway](../services/nat-gateway.md) | Alternative egress; SNAT port capacity |
| [Bastion](../services/bastion.md) | kubectl access via native client tunnel |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | Hub-spoke topology; DNS centralization |
| [Hybrid DNS Resolution](./dns-hybrid-resolution.md) | On-premises resolution of AKS private DNS |

---

## Source pages

| Source | Notes |
|---|---|
| [Application Gateway](../services/application-gateway.md) | AGIC, subnet sizing, WAF policies |
| [Private Link](../services/private-link.md) | Private Endpoint DNS, network policies |
| [Azure DNS](../services/dns.md) | Private DNS zones, DNS Private Resolver |
| [Virtual Network](../services/virtual-network.md) | Subnet sizing, NSG rules |
| [Bastion](../services/bastion.md) | Native client tunnel for kubectl |
| [Load Balancer](../services/load-balancer.md) | Internal LB for AKS services |
