# Azure Networking Fundamentals

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current | **Source articles:** 13

This page is the entry point for the Azure Networking KB. It maps every Azure networking service to its category, explains the core concepts that underpin all of them, and cross-references the deeper concept and service pages that cover each topic in full. If you are new to Azure networking — or are a traditional network engineer mapping on-premises concepts to Azure equivalents — start here.

---

## Azure networking service map

Azure networking services fall into five functional categories. All services listed below have compiled wiki pages.

### Foundation services

The building blocks every Azure network depends on.

| Service | One-line description | Wiki page |
|---|---|---|
| Azure Virtual Network (VNet) | Software-defined private network; the fundamental isolation boundary for all Azure resources | [virtual-network.md](../services/virtual-network.md) |
| Azure Private Link | Private endpoint connectivity from a VNet to PaaS services and partner services — no public internet traversal | [private-link.md](../services/private-link.md) |
| Azure DNS | Public DNS hosting, Private DNS zones, and DNS Private Resolver for hybrid name resolution | [dns.md](../services/dns.md) |
| NAT Gateway | Managed outbound SNAT for private subnets — static public IPs, no inbound path | [nat-gateway.md](../services/nat-gateway.md) |
| Azure Route Server | BGP peering between NVAs and the Azure SDN fabric; eliminates manual UDR maintenance for dynamic routing | [route-server.md](../services/route-server.md) |
| Azure Bastion | Browser-based RDP/SSH to VMs over TLS; no public IPs required on VMs | [bastion.md](../services/bastion.md) |

### Load balancing and content delivery

Traffic distribution, application delivery, and global routing services.

| Service | Layer | Scope | One-line description | Wiki page |
|---|---|---|---|---|
| Azure Load Balancer | L4 (TCP/UDP) | Regional or cross-region | High-throughput, low-latency distribution for all TCP/UDP traffic; internal and external | [load-balancer.md](../services/load-balancer.md) |
| Azure Application Gateway | L7 (HTTP/S) | Regional | Web traffic load balancer with URL routing, SSL offload, and integrated WAF | [application-gateway.md](../services/application-gateway.md) |
| Azure Front Door | L7 (HTTP/S) | Global | Global application delivery network with edge caching, acceleration, and WAF | [front-door.md](../services/front-door.md) |
| Azure Traffic Manager | DNS-based | Global | DNS-level traffic routing across regions using priority, weighted, geographic, or performance methods | [traffic-manager.md](../services/traffic-manager.md) |

### Hybrid connectivity

Services that connect on-premises networks, branches, and remote users to Azure.

| Service | Transport | One-line description | Wiki page |
|---|---|---|---|
| VPN Gateway | IPsec/IKE over internet | Encrypted site-to-site and point-to-site tunnels to Azure VNets | [vpn-gateway.md](../services/vpn-gateway.md) |
| ExpressRoute | Private dedicated circuit | Private, high-bandwidth, low-latency connections via connectivity providers or ExpressRoute Direct | [expressroute.md](../services/expressroute.md) |
| Virtual WAN | Managed hub (VPN + ER + SD-WAN) | Unified branch, remote user, and VNet connectivity with Microsoft-managed hub routing | [virtual-wan.md](../services/virtual-wan.md) |
| Peering Service | BGP over internet (optimized) | Optimizes public internet routing to Microsoft services for enterprise/ISP customers | [peering-service.md](../services/peering-service.md) |
| Internet Peering | BGP direct peering | Direct BGP peering with Microsoft's global network for Autonomous System operators | [internet-peering.md](../services/internet-peering.md) |

### Network security

Services that protect workloads, filter traffic, and prevent attacks.

| Service | One-line description | Wiki page |
|---|---|---|
| Azure Firewall | Managed stateful L3–L7 firewall with FQDN filtering, IDPS, and TLS inspection | [azure-firewall.md](../services/azure-firewall.md) |
| Web Application Firewall (WAF) | OWASP rule-set protection for HTTP/S workloads; deployable on Application Gateway or Front Door | [web-application-firewall.md](../services/web-application-firewall.md) |
| Azure DDoS Protection | Layer 3/4 volumetric and protocol attack mitigation; two tiers: Network Protection and IP Protection | [ddos-protection.md](../services/ddos-protection.md) |
| Azure Firewall Manager | Centralized security policy and routing management across multiple Azure Firewall instances | [firewall-manager.md](../services/firewall-manager.md) |

### Network management and monitoring

Services for visibility, diagnostics, governance, and operational control.

| Service | One-line description | Wiki page |
|---|---|---|
| Network Watcher | Per-region diagnostics: connection monitor, packet capture, flow logs, topology view, next-hop and effective-routes tools | [network-watcher.md](../services/network-watcher.md) |
| Azure Virtual Network Manager | Centralized VNet grouping, connectivity configuration, and security admin rule deployment at subscription/management-group scope | [virtual-network-manager.md](../services/virtual-network-manager.md) |
| Network Function Manager | Manages third-party network function deployments on Azure Stack Edge and Azure Arc-enabled infrastructure | [network-function-manager.md](../services/network-function-manager.md) |

---

## Core networking concepts

### Virtual networks and subnets

A **Virtual Network (VNet)** is the fundamental isolation boundary in Azure — the cloud equivalent of a physical network segment. When you create a VNet, you define one or more IPv4 (and optionally IPv6) address ranges. These ranges are not advertised to the internet; they are private to your deployment regardless of the RFC-1918 status of the addresses you choose.

Within a VNet, you carve **subnets** from the address space. Azure reserves the first four IP addresses and the last IP address in every subnet — plan your CIDRs accordingly. There is no concept of VLANs in Azure; isolation is achieved through subnets combined with Network Security Groups (NSGs) and, where needed, separate VNets.

**Key VNet capabilities:**

| Capability | How it works |
|---|---|
| Resource communication | Resources in the same VNet communicate over private IP by default, no configuration needed |
| VNet peering | Connects two VNets (same or different regions) over the Azure backbone; non-transitive |
| Hybrid connectivity | VPN Gateway or ExpressRoute attach to a VNet via a `GatewaySubnet` |
| Service endpoints | Extends VNet identity to Azure PaaS services over the backbone; secures PaaS to the VNet only |
| Private endpoints | Brings PaaS services into the VNet with a private IP via Azure Private Link |
| VNet encryption | Encrypts VM-to-VM traffic within and across peered VNets (requires supported VM SKUs) [VERIFY] |

> **For a network engineer transitioning from on-premises:** A VNet is equivalent to a VLAN or a routed segment in a physical datacenter. There is no STP, no broadcast domain management, and no need for routing protocols within a single VNet — Azure manages intra-VNet routing automatically.

### IP addressing

Azure assigns two categories of IP to network interfaces (NICs):

| Type | Description | Allocation |
|---|---|---|
| **Private IP** | Used within the VNet, on-premises networks, and outbound internet (via NAT) | Dynamic (default) or static; allocated from subnet range |
| **Public IP** | Used for direct inbound internet connectivity and outbound without NAT | Dynamic or static; drawn from Microsoft's public IP pool |

The first four IPs and last IP in each subnet are reserved by Azure. Dynamic private IPs are allocated when a VM starts and released when it stops or is deleted. Set allocation to **static** if the IP must persist across stop/start cycles.

### Routing

Azure creates and manages routing tables automatically. The route selection order (highest to lowest priority) is:

1. **User-Defined Routes (UDR)** — custom static routes you create and associate with subnets
2. **BGP routes** — learned from on-premises via VPN Gateway or ExpressRoute
3. **System routes** — Azure-managed defaults (intra-VNet, internet, service endpoints)

Azure uses longest-prefix-match, consistent with traditional routing behavior. To force traffic through a hub firewall or NVA, you must create explicit UDR entries — a default route (`0.0.0.0/0`) alone is not sufficient when more-specific peering routes exist. See [hub-spoke-networking.md](hub-spoke-networking.md) for the full UDR pattern.

### Network Security Groups (NSGs)

NSGs are stateful L3/L4 ACL filters. They contain inbound and outbound rules evaluated in priority order; the first matching rule wins. NSGs can be applied to **subnets** (affecting all resources in the subnet) and/or to individual **NICs** (affecting a single VM). Both associations apply, and both sets of rules are evaluated — subnet NSG first for inbound, NIC NSG first for outbound.

Default rules (lowest priority, cannot be deleted):
- Allow all intra-VNet traffic
- Allow inbound from Azure Load Balancer
- Deny all other inbound
- Allow all outbound

### DNS fundamentals

Azure's DNS stack has three layers relevant to most architectures:

| Service | Scope | Use case |
|---|---|---|
| **Azure Public DNS** | Internet-resolvable | Host public DNS zones; manage records with same Azure credentials as other services |
| **Azure Private DNS zones** | VNet-internal | Name resolution for private resources; linked to one or more VNets |
| **Azure DNS Private Resolver** | Hybrid | Resolves Azure Private DNS zones from on-premises, and on-premises zones from Azure, without VM-based DNS servers |

By default, Azure-provided DNS (`168.63.129.16`) handles internal resolution. Override this per-VNet to point to custom DNS servers or the DNS Private Resolver inbound endpoint when hybrid resolution is needed.

### Azure Private Link and Private Endpoints

**Azure Private Link** brings PaaS services (Storage, SQL, Key Vault, etc.) into your VNet via a **private endpoint** — a NIC with a private IP allocated from your subnet. Traffic to the service traverses the Microsoft backbone and never touches the public internet. Private endpoints require a matching **private DNS zone** record so that FQDNs resolve to the private IP rather than the public IP. See [private-link.md](../services/private-link.md) for full details and [private-access-to-paas.md](private-access-to-paas.md) for the decision guide.

---

## Network design patterns

### Hub-spoke topology

The dominant multi-VNet design pattern in Azure. A **hub VNet** hosts shared services (firewall, gateways, Bastion, DNS); **spoke VNets** contain individual workloads and connect to the hub via non-transitive VNet peering. This concentrates security inspection at the hub and allows expensive resources (VPN/ER gateways, Azure Bastion, DNS Resolver) to be deployed once and shared by all spokes.

➡️ **Full coverage:** [hub-spoke-networking.md](hub-spoke-networking.md) — UDR requirements, hub component table, peering topology, VWAN comparison.

### Secure hub-spoke for web applications

A minimal hub-spoke pattern for regional web workloads layers security controls in order:

| Layer | Component | Role |
|---|---|---|
| 1 | Hub + spoke VNets, VNet peering | Network isolation boundary |
| 2 | NSGs on every subnet (default-deny) | L3/L4 traffic control |
| 3 | DDoS Protection (conditional) | Volumetric attack mitigation on public IPs |
| 4 | Application Gateway WAF_v2 (in spoke) | L7 inspection, SSL offload, WAF |
| 5 | Azure Bastion (in hub) | Secure VM management without public IPs |
| 6 | Azure Firewall (optional, in hub) | Centralized egress FQDN filtering |

Always deploy NSGs before placing resources in subnets — resources should never operate in an uncontrolled subnet, even briefly. See the [design-secure-hub-spoke-network.md](../../raw/articles/networking/cross-service-scenarios/design-secure-hub-spoke-network.md) article for the full layered deployment order.

### Virtual WAN topology

Azure Virtual WAN provides a Microsoft-managed hub that handles transitive routing between VNets, branches, and remote users automatically — without customer-managed UDRs for spoke-to-spoke routing. Virtual WAN hubs support simultaneous VPN Gateway, ExpressRoute Gateway, Azure Firewall, and SD-WAN termination. Choose Virtual WAN over DIY hub-spoke when:
- You have many branch offices requiring SD-WAN or VPN termination at scale
- You need multi-region transitive routing without managing a hub VNet in each region
- You want Microsoft to own the hub routing plane

See [virtual-wan.md](../services/virtual-wan.md) and [hub-spoke-networking.md](hub-spoke-networking.md) for the full topology comparison table.

### Secure network topology decision guide

Two key questions determine your topology direction:

1. **Global distribution or single-region?** Global → consider Azure Front Door + Virtual WAN. Single-region → hub-spoke.
2. **Third-party NVAs for routing and security?** Yes → hub-spoke with NVAs; use Azure Route Server for BGP integration. No → Azure Firewall in hub (or Virtual WAN Secured Hub with Azure Firewall Manager).

Azure Virtual Network Manager can apply connectivity configurations and security admin rules across all VNets in network groups, regardless of subscription — useful for enforcing baseline NSG rules at enterprise scale without coordinating per-VNet deployments.

---

## Load balancing and content delivery

### Service selection guide

| Scenario | Recommended service | Layer | Notes |
|---|---|---|---|
| Internal TCP/UDP load balancing within a VNet | Azure Load Balancer (internal) | L4 | No public IP; VNet-only; ultra-low latency |
| Internet-facing TCP/UDP (non-HTTP/S) | Azure Load Balancer (public) | L4 | Supports any TCP/UDP protocol |
| Regional HTTP/S with WAF, SSL offload, URL routing | Application Gateway (WAF_v2) | L7 | Best for single-region web apps behind a firewall boundary |
| Global HTTP/S with failover, caching, acceleration | Azure Front Door | L7 | Runs at Microsoft's edge POPs globally; includes CDN and WAF |
| DNS-based global traffic routing (failover, geo, performance) | Traffic Manager | DNS | Works with any endpoint reachable via DNS; protocol-agnostic |
| Multi-region with regional backend pooling | Front Door + Application Gateway | L7 + L7 | Front Door at edge for global routing; App Gateway per region for WAF granularity |

### Application delivery decision tree (summary)

Start with the WAF question:
- **Need WAF at the edge with global distribution?** → Azure Front Door (with WAF policy)
- **Need WAF within a VNet boundary (single region)?** → Application Gateway WAF_v2
- **Media-based streaming workloads?** → Verizon Media Streaming via Azure [VERIFY — check current availability]
- **Non-HTTP/S or internal TCP/UDP?** → Azure Load Balancer

> Full decision tree: see [load-balancing-options.md](../decisions/load-balancing-options.md).

---

## Hybrid connectivity

### Quick reference

| Service | Best for | Transport | Bandwidth | Encryption |
|---|---|---|---|---|
| **VPN Gateway (S2S)** | Smaller sites; moderate BW; cost-sensitive; where ExpressRoute is unavailable | IPsec over public internet | Up to ~10 Gbps (GW5AZ) [VERIFY] | ✅ Always (IPsec/IKEv2) |
| **ExpressRoute (provider circuit)** | Low latency, high BW, private connectivity to Azure and M365; compliance | Private dedicated fiber via partner | 50 Mbps – 10 Gbps [VERIFY] | ❌ Not encrypted by default |
| **ExpressRoute Direct** | 10/100 Gbps dedicated port directly into Microsoft network | Direct port into Microsoft POP | 10 / 100 / 400 Gbps [VERIFY] | ❌ MACsec optional |
| **Virtual WAN (managed hub)** | Multi-branch, multi-region, SD-WAN; managed hub routing | VPN, ER, or SD-WAN; customer's choice per branch | 20 Gbps per hub [VERIFY] | ✅ / ❌ Depends on transport |

**Decision factors to weigh:** bandwidth needed, acceptable latency, encryption requirement, compliance posture, lead time (ExpressRoute takes weeks via provider), cost, and whether branch-at-scale management is needed.

➡️ **Full coverage — including BGP routing details, route filtering, ExpressRoute communities, and ExpressRoute Global Reach:** [hybrid-connectivity.md](hybrid-connectivity.md)

---

## Microsoft global network

### Backbone infrastructure

Microsoft owns and operates one of the largest backbone networks in the world — spanning more than 500,000 miles and connecting datacenters across 80+ Azure regions with a mesh of globally placed edge nodes. All inter-datacenter traffic (VM-to-VM, Azure service-to-service, M365, Xbox) travels over this private backbone; it never traverses the public internet.

Edge nodes interconnect with 4,000+ unique internet peers (via 1,000s of connections in 190+ locations), enabling Microsoft to use **cold-potato routing**: customer traffic enters the Microsoft network at the closest edge point and stays on the Microsoft backbone for as long as possible before being handed off.

### Why this matters for your architecture

- **Traffic between peered VNets** routes through the Microsoft backbone regardless of region — no internet exposure, no peering point charges for latency.
- **Global VNet peering** connects VNets across regions over the backbone transparently.
- **ExpressRoute** places your traffic on the Microsoft backbone at the peering location. ExpressRoute Direct gives up to 100 Gbps at 400 Gbps direct ports, bypassing third-party provider handoffs.
- **ExpressRoute Global Reach** uses the backbone to interconnect your on-premises sites globally without hairpinning through Azure VNets.

### Latency characteristics

Azure publishes P50 round-trip latency statistics between region pairs, updated every 6–9 months. These are measured via internal network probes at 1-minute intervals across the backbone. Representative sample values (as of June 2025, indicative only — always verify current data):

| Region pair | Approximate P50 RTT |
|---|---|
| East US ↔ West US 2 | ~68 ms [VERIFY] |
| West US ↔ Japan East | ~107 ms [VERIFY] |
| West US ↔ North Europe | ~139 ms [VERIFY] |
| East US ↔ West Europe | ~80–90 ms [VERIFY] |
| US regions (same geography) | 18–50 ms [VERIFY] |

> [VERIFY] — All latency figures should be validated against the current `azure-network-latency.md` source article. Latency tables change with new region additions and backbone upgrades. Use `virtual-network-test-latency` VM-based tooling for workload-specific measurements.

**For multi-region architecture:** Use latency data to choose region pairs for active-active deployments, disaster recovery secondaries, and data residency boundaries. Same-continent region pairs typically stay under 100 ms; trans-Pacific and trans-Atlantic pairs range from 100–180 ms.

---

## NVA accelerated connections

### What it is

**Accelerated Connections** is a vNIC-level performance feature for Network Virtual Appliances (NVAs) and high-connection-count VMs. When enabled alongside Accelerated Networking, it offloads SDN policy evaluation from the data path, eliminating bottlenecks for workloads that maintain large numbers of simultaneous connections.

> **Status:** Limited General Availability (GA) — sign-up required [VERIFY current availability status].

### Performance characteristics

| Metric | Impact |
|---|---|
| Connections Per Second (CPS) | Up to **25× improvement** over baseline for high-concurrency workloads [VERIFY] |
| Total Active Connections | Significantly increased ceiling [VERIFY] |
| VM throughput under high concurrency | Consistent — negligible degradation at peak connection counts |
| Applicable VM sizes | All SKUs supported by Accelerated Networking up to v5 series; 4 vCPU minimum |

Four performance tiers are configurable at the vNIC level — tier selection is independent of VM size, allowing smaller VMs to achieve NVA-grade connection performance without upsizing.

### When to use it

| Use case | Why Accelerated Connections helps |
|---|---|
| Virtual firewalls / next-gen firewalls (NVAs) | Firewall appliances establish and tear down millions of short-lived connections; CPS throughput is the binding constraint |
| Virtual load balancers and ADCs | NAT and load-balancing state requires tracking many simultaneous connections |
| VPN concentrators and SD-WAN appliances | Branch aggregation creates high concurrent session counts |
| High-connection-rate application VMs | Any VM workload where active connection count is the bottleneck, not raw throughput |

### Constraints

- Available on new deployments only — cannot be enabled on existing NICs without redeployment
- NIC detach/re-attach requires stop-deallocate first
- Azure Marketplace portal not supported during limited GA; use ARM templates, CLI, Terraform, or SDK
- Sign-up required: [sign-up form](https://go.microsoft.com/fwlink/?linkid=2223706)
- Supported regions include: East US, West US, West US 2/3, North/South Central US, West Central US, North/West Europe, Sweden Central, UK South, Central India, Southeast Asia, Australia East [VERIFY for current region list]

### Relationship to Accelerated Networking

Accelerated Networking (SR-IOV) bypasses the hypervisor software switch and is a **prerequisite** for Accelerated Connections. Accelerated Networking reduces per-packet overhead; Accelerated Connections optimizes the connection-tracking and SDN policy path specifically for CPS-bound workloads. Both features work together — Accelerated Connections adds no value without Accelerated Networking enabled.

---

## Network monitoring quick reference

Azure provides layered monitoring coverage. The key tools:

| Tool | Type | Primary use |
|---|---|---|
| **Azure Network Watcher** | Diagnostics + flow logging | Connection monitor, packet capture, topology view, next-hop verification, NSG flow logs, VNet flow logs | 
| **Traffic Analytics** | Flow analysis (NSG flow log–based) | Visibility into top talkers, traffic patterns, malicious flows, capacity utilization across VNets and subnets |
| **Connection Monitor** | Synthetic probing | End-to-end reachability and latency monitoring between Azure resources and external endpoints; replaces legacy NPM |
| **ExpressRoute Monitor (NPM)** | Circuit health | Auto-detects ER circuits; monitors E2E connectivity and performance for private and Microsoft peering |
| **Azure Monitor** | Metrics + alerts | Cross-resource metrics, log queries (KQL), and alert rules for all networking services |
| **DNS Analytics** | DNS log analysis | Identifies malicious domain lookups, stale records, DNS request load anomalies |

> ⚠️ Network Performance Monitor (NPM) and Connection Monitor (Classic) are deprecated. Migrate to Connection Monitor in Azure Network Watcher. See [network-watcher.md](../services/network-watcher.md) and [monitoring.md](monitoring.md).

---

## Related concept pages

- [hub-spoke-networking.md](hub-spoke-networking.md) — Full hub-spoke topology reference: UDR patterns, hub components, peering setup, VWAN comparison
- [hybrid-connectivity.md](hybrid-connectivity.md) — VPN Gateway, ExpressRoute, Virtual WAN; BGP routing, route filtering, ExpressRoute Global Reach
- [ip-addressing.md](ip-addressing.md) — VNet/subnet CIDR planning, public vs. private IP, address allocation strategies
- [routing.md](routing.md) — System routes, UDRs, BGP route propagation, effective route analysis
- [network-security-design.md](network-security-design.md) — NSG design, Azure Firewall placement, WAF patterns, defense-in-depth topology
- [private-access-to-paas.md](private-access-to-paas.md) — Private endpoints, service endpoints, DNS integration for Private Link
- [monitoring.md](monitoring.md) — Network Watcher toolset, Traffic Analytics, Connection Monitor setup

---

## Decision guides

| Decision | Guide |
|---|---|
| Which connectivity method for hybrid? | [connectivity-options.md](../decisions/connectivity-options.md) |
| Which load balancing service? | [load-balancing-options.md](../decisions/load-balancing-options.md) |
| Which firewall / security solution? | [firewall-and-security-options.md](../decisions/firewall-and-security-options.md) |
| Private access pattern for PaaS? | [private-access-options.md](../decisions/private-access-options.md) |

---

## Source articles

| Title | Path | Date |
|---|---|---|
| Azure networking services overview | `raw/articles/networking/fundamentals/networking-overview.md` | 2025-06-26 |
| Azure Networking architecture documentation | `raw/articles/networking/fundamentals/architecture-guides.md` | 2023-06-13 |
| Azure for network engineers | `raw/articles/networking/azure-for-network-engineers.md` | 2020-06-25 |
| Azure network round-trip latency statistics | `raw/articles/networking/azure-network-latency.md` | 2025-07-07 |
| Microsoft global network | `raw/articles/networking/microsoft-global-network.md` | 2023-04-06 |
| What is hybrid connectivity? | `raw/articles/networking/hybrid-connectivity/hybrid-connectivity.md` | 2025-06-24 |
| Azure network foundation services overview | `raw/articles/networking/foundations/network-foundations-overview.md` | 2025-07-26 |
| What is load balancing and content delivery? | `raw/articles/networking/load-balancer-content-delivery/load-balancing-content-delivery-overview.md` | 2025-06-24 |
| Choose a secure application delivery service | `raw/articles/networking/secure-application-delivery.md` | 2024-06-17 |
| Choose a secure network topology | `raw/articles/networking/secure-network-topology.md` | 2024-06-17 |
| Network monitoring solutions | `raw/articles/networking/network-monitoring-overview.md` | 2023-10-30 |
| Accelerated connections on NVAs or other VMs | `raw/articles/networking/nva-accelerated-connections.md` | 2023-02-01 |
| Design a secure hub-spoke network for regional web applications | `raw/articles/networking/cross-service-scenarios/design-secure-hub-spoke-network.md` | 2026-03-24 |