# Azure Virtual WAN

> **Compiled:** 2026-04-10 | **Source articles:** 133 | **Status:** ✅ current

## What it is

**Azure Virtual WAN** is a Microsoft-managed, cloud-hosted **networking-as-a-service** platform that unifies
**branch connectivity**, **remote user access**, **private ExpressRoute circuits**, and **VNet-to-VNet transit**
under a single operational interface. It implements a **global transit hub-and-spoke architecture** where
Microsoft-managed **virtual hubs** in Azure regions act as the switching core — replacing customer-managed
hub VNets, VPN concentrators, and transit VNets.

Any spoke (branch site, remote user, VNet, or ExpressRoute circuit) connected to any hub can reach any other
spoke via the **Microsoft global backbone**, without requiring full-mesh peering or customer-managed routing
infrastructure. All hubs in a **Standard Virtual WAN** are automatically interconnected in full mesh.

Key behavior:
- **Microsoft manages the hub** — the virtual hub is a Microsoft-provisioned VNet; customers do not directly control it
- Hub gateways are **distinct resource types** from standalone VPN Gateway / ExpressRoute gateway resources
- Spoke VNets connected to a hub **cannot** have their own virtual network gateway or Azure Route Server
- One VNet can be connected to **only one** virtual hub
- Hub-to-hub links are automatic in Standard SKU; inter-hub traffic uses the Microsoft backbone
- Routing is BGP-based; the **virtual hub router** is the central route manager for all gateways and connections
- Virtual WAN **does not store customer data**

---

## Key capabilities

| Capability | Detail |
|---|---|
| **Site-to-site VPN** | IPsec/IKEv2 tunnels from branch CPE devices to hub VPN gateway. Up to 1,000 S2S connections (2,000 IPsec tunnels) per hub. Aggregate throughput up to 20 Gbps per hub [VERIFY]. Active-active dual-instance gateway. |
| **User VPN (point-to-site)** | IKEv2 or OpenVPN tunnels for remote users. Auth: certificate, RADIUS, or Microsoft Entra ID (OpenVPN only). Scale units 1–200 supporting up to 100,000 concurrent users per hub. Aggregate throughput up to 200 Gbps at max scale [VERIFY]. |
| **ExpressRoute** | Connects ER circuits (Local, Standard, Premium, Direct) to hub ER gateway. 1 scale unit = 2 Gbps; max 10 scale units = 20 Gbps per hub [VERIFY]. Max 4 circuits from same peering location, 8 from different peering locations per hub. |
| **VNet-to-VNet transit** | Transitive connectivity between all spoke VNets via the hub router (Standard SKU only). Hub router supports up to 50 Gbps aggregate [VERIFY]. |
| **Hub-to-hub (inter-hub)** | All Standard WAN hubs automatically meshed. Cross-region traffic uses Microsoft backbone. |
| **Secure Virtual Hub** | Deploy **Azure Firewall**, **NVA firewall**, or **SaaS security** in the hub. Use **Routing Intent + Routing Policies** to route internet and/or private traffic through the security appliance. |
| **NVA in hub** | Select SD-WAN and NGFW NVAs (Barracuda, Check Point, Cisco, Fortinet, Palo Alto, etc.) can be deployed directly in the hub as a managed application. Acts as third-party gateway and/or firewall. |
| **BGP peering with hub** | Hub router can peer via BGP with NVAs deployed in spoke VNets. Hub router IP pairs must both receive route advertisements. |
| **Route-maps** | Per-connection inbound/outbound route manipulation: prefix filtering, route aggregation, AS-PATH prepend/replace/remove, BGP community add/replace/remove. Applicable to S2S, P2S, ER, and VNet connections. |
| **Routing Intent & policies** | Hub-level policy to send all internet-bound or all private traffic through a designated next-hop security appliance (Azure Firewall, NVA, or SaaS). Enables inter-hub traffic inspection. |
| **Hub routing preference (HRP)** | Control hub router's best-path selection when multiple path types exist: **ExpressRoute** (default), **VPN**, or **AS Path**. |
| **NAT rules (S2S VPN)** | Static or dynamic source NAT on the S2S VPN gateway for overlapping on-premises address spaces. IngressSnat / EgressSnat modes. Incompatible with policy-based traffic selectors. |
| **Customer-controlled maintenance** | Schedule maintenance windows for S2S VPN, P2S VPN, ExpressRoute gateways, and Azure Firewall. |
| **Cross-tenant VNet connections** | Connect VNets from different Azure AD tenants to a hub via Azure CLI/PowerShell. |
| **SD-WAN partner automation** | 30+ certified partners (Cisco, VMware, Versa, etc.) provide zero-touch IPsec provisioning via Azure APIs. |
| **Forced tunneling** | Enable default route propagation (0.0.0.0/0) per connection. Default route must already exist in the hub (from Firewall or on-premises advertisement); hub does not originate it. |
| **IPsec over ExpressRoute** | Encrypt ExpressRoute private peering traffic with an IPsec/IKEv2 tunnel over the ER circuit. Provides encryption without public internet exposure. |
| **Packet capture** | Capture packets on S2S VPN gateway instances via portal or PowerShell. |
| **Effective routes** | View programmed routes for any hub connection or resource from the portal. |
| **Private Link integration** | Private Endpoints in spoke VNets work with Virtual WAN; traffic to Private Endpoints does NOT incur VNet peering charges (billed as Private Link data processing instead). |
| **Global P2S profile** | Single downloadable profile covering all hubs; built-in traffic manager selects nearest available hub for P2S clients. |
| **Azure Monitor Insights** | Pre-built topology and dependency view for the full Virtual WAN deployment. |

---

## SKUs / tiers

| SKU | Connectivity types | Hub mesh | VNet-to-VNet transit | ER / P2S | Hub base fee | Data processing fee |
|---|---|---|---|---|---|---|
| **Basic** | Site-to-site VPN only | ❌ Not meshed | ❌ | ❌ | $0.00/hr | None |
| **Standard** | S2S VPN, P2S VPN, ExpressRoute, VNet connections | ✅ Full mesh (automatic) | ✅ | ✅ | $0.25/hr per hub [VERIFY] | Hub data processing fee applies for VNet-to-VNet flows [VERIFY] |

**Upgrade notes:**
- Basic → Standard upgrade is **one-way**; cannot revert to Basic
- Basic hubs cannot adjust gateway scale units; upgrade to Standard for higher throughput

### Gateway scale units (Standard SKU)

| Gateway type | 1 scale unit | Max scale units | Max throughput | Notes |
|---|---|---|---|---|
| **S2S VPN** | 500 Mbps [VERIFY] | — | 20 Gbps per hub [VERIFY] | Dual active-active instances; each instance supports up to 1,000 tunnels |
| **ExpressRoute** | 2 Gbps [VERIFY] | 10 | 20 Gbps per hub [VERIFY] | ER ECMP not enabled by default; requires Route-map creation to activate |
| **User VPN (P2S)** | 500 Mbps / 500 users | 200 | 100 Gbps / 100,000 users [VERIFY] | Scale ≥40 requires multi-CIDR client address pool planning |

> [VERIFY] S2S pricing: pricing-concepts.md shows $0.261/hr per scale unit in the components table but $0.361/hr in the calculation section. **[CONFLICT]** — verify against current Azure pricing page before publishing.

### Routing Infrastructure Units (hub router)

| Routing Infrastructure Units | Hub router throughput | Max spoke VMs |
|---|---|---|
| 2 (default) | 3 Gbps | 2,000 |
| 3 | 3 Gbps | 3,000 |
| 4–50 | 1 Gbps per RIU | 1,000 VMs per RIU |
| **50 (max)** | **50 Gbps** | **50,000** |

- Hub autoscales based on spoke VM utilization and data processed; will not scale below the provisioned minimum
- Scaling takes up to 25 minutes; plan minimums proactively for latency-sensitive workloads
- Single TCP flow is hard-limited to **1.5 Gbps** regardless of RIU count [VERIFY]
- Hub can accept a maximum of **10,000 routes** from all connected resources regardless of RIU count

---

## Architecture patterns

### 1. Global backbone WAN (any-to-any)
All hubs in a Standard Virtual WAN are automatically full-meshed. Branches, remote users, and VNets in any
region can reach each other through the Microsoft backbone without customer-managed transit.

- **Default behavior:** All connections associate and propagate to the `defaultRouteTable`
- Works out of the box; no custom route tables needed for pure any-to-any
- Branch-to-branch must be enabled in WAN settings (on by default)

### 2. Hub-and-spoke with SD-WAN / VPN branches
Branch CPE devices (SD-WAN or vanilla VPN) terminate IPsec tunnels on the hub S2S VPN gateway. Up to
1,000 connections (4 links each) per hub. Partners automate device info export and Azure config download.

- Each branch connection = up to 4 link connections = up to 2 IPsec tunnels per link
- ECMP load-balances across parallel links by default (per-flow)
- For BCDR: use multi-hub, multi-link topology; consider multi-region for regional failure protection

### 3. Secure Virtual Hub
Deploy Azure Firewall (or a supported NVA/SaaS) inside the hub and use **Routing Intent** to redirect all
internet and/or private traffic through the security appliance.

- Internet Traffic Routing Policy → all internet-bound traffic from all branches and VNets via firewall
- Private Traffic Routing Policy → all branch-to-VNet, VNet-to-VNet, and inter-hub private traffic via firewall
- Requires hub address space **/22 or larger** when Azure Firewall is deployed
- Azure Firewall is NOT automatically AZ-deployed; must be explicitly configured at creation; cannot be
  changed on an existing Firewall deployment (delete and redeploy)
- Each hub must have its own Firewall — a Firewall cannot be shared across hubs

### 4. NVA-in-hub (SD-WAN + NGFW)
Select third-party NVAs (e.g., Barracuda CloudGen WAN, Check Point CloudGuard, Cisco Catalyst SDWAN,
Fortinet FortiGate, Palo Alto) deployed directly in the hub as a managed application. Participates in
hub BGP routing. Supports SD-WAN branch termination and/or NGFW inspection.

- Deployed in 'n+1' overprovisioned instances for HA
- NVA Infrastructure Units: 1 unit ≈ 500 Mbps; range 2–80 units per hub deployment (vendor-specific)
- Cannot be configured directly; management via vendor portal only
- Cannot apply Route-maps to NVA connections within the hub

### 5. Remote user connectivity (P2S)
Users connect via Azure VPN Client (IKEv2 or OpenVPN) or any OpenVPN-compatible client. Auth options:
certificate, RADIUS, Microsoft Entra ID. Global profile auto-selects nearest hub.

- User groups (multi-pool): assign different IP pools per user group for ACL/firewall segmentation
- IKEv2 tunnel type: supports 255 routes maximum
- OpenVPN tunnel type: supports 1,000 routes maximum

### 6. ExpressRoute private connectivity
ER circuits (Local, Standard, Premium) connect to the hub ER gateway. Transit between VPN branches and
ER sites is automatic (branch-to-branch flag must be enabled).

- **ER-to-ER transit**: Use ExpressRoute Global Reach (bypasses hub) OR Routing Intent with private routing
  policy (routes through hub security appliance)
- ER Local circuits connect only to ER gateways in the same region but can route to VNets in other regions

### 7. Forced tunneling / default route
Propagate 0.0.0.0/0 from hub to branches or VNets for internet traffic inspection. Note:
- Default route does **not** originate from the hub; it must be learned (from deployed Firewall or on-premises BGP)
- Default route is **hub-local** — it does not propagate to other hubs across hub-to-hub links
- Azure Firewall Manager setting overrides any on-premises-learned default route

---

## Configuration essentials

### Hub creation
| Setting | Guidance |
|---|---|
| **Hub address space** | **Immutable after creation.** Minimum /24; recommended **/23 or larger**. Requires **/22 or larger** if Azure Firewall will be deployed. Requires careful sizing for NVAs (affects IP pool size). Must not overlap with spoke VNets, other hubs, or on-premises ranges. |
| **Routing Infrastructure Units** | Default = 2 RIUs (3 Gbps, 2,000 VMs). Set minimum RIUs based on peak workload; autoscaling adds on demand but takes up to 25 minutes. |
| **Hub type** | Empty hub + gateways later is valid. Hub billing starts at creation even with no gateways. Hub creation takes 5–7 min (no gateways) or ~30 min (with gateways). |
| **Multiple hubs per region** | Supported. Use for BCDR or to exceed per-hub connection limits. |

### Routing fundamentals
| Concept | Key facts |
|---|---|
| **Default route table** | All connections associate and propagate to `defaultRouteTable` by default. Branch connections should all use the same route table for consistent route propagation. |
| **Labels** | Group route tables for multi-hub propagation. Built-in label `Default` applies to all defaultRouteTables in the WAN. |
| **Static routes** | Injected into a route table with a next-hop IP; must point at NVA in a spoke VNet. Do **not** use hub router IPs as next hop. |
| **Hub routing preference** | Default is **ExpressRoute**. Options: ExpressRoute, VPN, AS Path. Affects on-premises path selection only. |
| **Route-maps** | Applied per-connection in inbound and/or outbound direction. Only one route-map per direction per connection. Cannot be applied to NVA connections inside the hub. Only 2-byte ASNs supported. Summarization only (no more-specific routes). |
| **ECMP for ExpressRoute** | NOT enabled by default. Create a Route-map (even empty, then delete it) to upgrade hub software to support ER ECMP. |
| **Inter-hub 0.0.0.0/0** | Default route does NOT propagate across hub-to-hub links. Each hub must independently learn the default route. |

### BGP reserved ASNs (do not use)
| Type | Reserved values |
|---|---|
| Azure public ASNs | 8074, 8075, 12076 |
| Azure private ASNs | 65515, 65517, 65518, 65519, 65520 |
| IANA reserved | 23456, 64496–64511, 65535–65551 |
| Inter-hub prepend | 65520-65520 (auto-prepended by hub when advertising to other hubs) |

### NAT rules (S2S VPN)
- Static NAT: fixed 1:1 mapping (internal ↔ external); both pools must be same size
- Dynamic NAT: port-based; on-premises BGP peer IP cannot be in the pre-NAT range (create a separate static rule for it)
- Policy-based (narrow) traffic selectors are **incompatible** with NAT
- A prefix can be modified by either Route-maps OR NAT — **not both**
- Enable **BGP Route Translation** to auto-advertise post-NAT ranges via BGP

### P2S client address pools
- Each P2S gateway instance independently allocates IPs; pool is split across instances (explains why P2S clients may see split routes)
- For scale units ≥40, plan multiple CIDR blocks for the client address pool
- DNS servers can be pushed to P2S clients via gateway configuration (preferred) or profile XML

### IPsec defaults (S2S VPN)
- Default and custom IPsec/IKE policies supported
- Recommended algorithm for optimal performance: **GCMAES256** for both IPsec Encryption and Integrity [VERIFY]
- AES256 + SHA256 is less performant; expect higher latency and packet drops vs. GCMAES256

### Spoke VNet constraints
- A spoke VNet **cannot** have a virtual network gateway
- A spoke VNet **cannot** have an Azure Route Server
- A VNet can connect to **only one** virtual hub
- VNet peering between spokes (direct) takes precedence over VNet-to-VNet transit via the hub
- Virtual WAN **cannot** inject routes that are more specific than the spoke VNet prefix; cannot attract
  traffic between subnets within the same VNet

### IPv6
- **IPv6 is NOT supported** in the virtual hub or its gateways
- Advertising IPv6 prefixes from on-premises **breaks IPv4 connectivity** for Azure resources
- P2S users on modern clients should disable IPv6 on the device for internet-breakout scenarios

### API minimum version
Minimum API version for automation scripts: **2022-05-01**

---

## Monitoring and troubleshooting

### Key tools

| Tool | What it shows | Where |
|---|---|---|
| **Azure Monitor Insights** | Full topology view, dependency tree, health status across all Virtual WAN resources | Azure portal → Virtual WAN → Insights |
| **Effective Routes** | Programmed routes for any hub, connection, or gateway resource | Azure portal → Virtual Hub → Effective Routes |
| **BGP Dashboard** | BGP session status, advertised/learned prefixes, AS Path for S2S connections | Azure portal → VPN Gateway → BGP Dashboard |
| **Route Map Dashboard** | Routes, AS Path, BGP communities per connection with Route-map applied | Azure portal → Virtual Hub → Route Maps |
| **Packet Capture (S2S)** | Raw packet captures on VPN gateway instances; portal or PowerShell | Azure portal → VPN Gateway → Packet Capture |
| **Network Watcher** | VM-level: packet capture, IP flow verify, NSG diagnostics, connection troubleshoot | Azure Network Watcher (does not validate through-hub datapath) |
| **P2S Connection Monitor** | Diagnostic logs for P2S user connections | Azure Monitor → Diagnostic settings |
| **Hub Reset / Router Reset** | Recovers failed hub resources or hub router back to provisioned state without resetting gateways | Azure portal → Virtual Hub → Reset |

### Key metrics by resource type

**Virtual hub router** (`Microsoft.Network/virtualhubs`):
| Metric | Description |
|---|---|
| Routing Infrastructure Units | Current deployed RIUs; use to verify autoscaling behavior |
| Spoke VM Utilization | % of max VMs supported by current RIUs; alert when approaching 100% |
| Count of Routes Advertised to Peer | Routes advertised per BGP session; use with **per-peer-IP splitting** and **Max aggregation**; Sum aggregation is inaccurate |

**S2S VPN gateway** (`microsoft.network/vpngateways`):
| Metric | Description |
|---|---|
| Gateway S2S Bandwidth | Aggregate gateway throughput (bytes/sec) |
| Tunnel Bandwidth | Per-tunnel throughput |
| Tunnel Egress / Ingress Packet Drop Count | Drop counters by tunnel; key for IPsec health |
| Tunnel TS Mismatch Packet Drop | Traffic selector mismatch drops |
| BGP Peer Status | Per-peer, per-instance BGP session status |
| BGP Routes Advertised / Learned | Per-peer route counts |
| Tunnel MMSA / QMSA Count | IKE SA creation/deletion events |
| Gateway Inbound/Outbound Flows | 5-tuple flow counts; limit is 250,000 flows [VERIFY] |

**P2S VPN gateway** (`microsoft.network/p2svpngateways`):
| Metric | Description |
|---|---|
| P2S Connection Count | Use **Sum** aggregation (not Average); split by Instance for per-instance view |
| Gateway P2S Bandwidth | Aggregate P2S throughput |
| User VPN Routes Count | Static vs. Dynamic route breakdown |

**ExpressRoute gateway** (`microsoft.network/expressroutegateways`):
| Metric | Description |
|---|---|
| BitsInPerSecond / BitsOutPerSecond | Per-connection breakout available |
| CPU Utilization | Gateway CPU; scale up if approaching limits |
| Count of routes advertised/learned to peer | Route stability monitoring |
| Frequency of routes change | Alert on unexpected churn |

### Diagnostic logs
- Resource logs available for: ExpressRoute gateway, S2S VPN gateway, P2S VPN gateway
- Send to: Log Analytics, Event Hubs, Storage Account
- Azure Monitor Logs tables available for S2S VPN for deep-dive analysis

### Troubleshooting quick reference
1. **Hub/routing in failed state** → Use **Hub Reset** (portal) before opening support; doesn't touch gateways
2. **Hub router routing status failed but connectivity works** → Use **Reset Router** (takes <10 min, rarely disrupts traffic)
3. **VPN tunnel disconnected but on-premises looks OK** → Use **Gateway Reset** (sequential instance reboot; <1 min gap; public IPs unchanged)
4. **Check known issues** → `whats-new.md` Known Issues section before troubleshooting
5. **Validate service limits** → Check deployment is within subscription/service limits

---

## Common gotchas / known limits

- **Hub address space is immutable.** Plan /23 minimum (general), /22 minimum (with Azure Firewall). There is no fix after creation other than deleting and recreating the hub.
- **Basic → Standard upgrade is one-way.** Cannot downgrade from Standard to Basic.
- **IPv6 is not supported.** Advertising IPv6 prefixes from on-premises breaks IPv4 connectivity for Azure resources — not just IPv6 traffic.
- **Spoke VNets cannot have a VPN Gateway or Route Server.** Connecting a spoke VNet with either resource to a hub will fail or cause routing issues.
- **0.0.0.0/0 does not cross hub boundaries.** Default route is confined to the local hub's route table; each hub with a firewall must independently advertise the default route.
- **Single TCP flow cap is 1.5 Gbps** regardless of RIU count. Applications requiring high per-flow throughput cannot overcome this with more RIUs. [VERIFY]
- **ECMP for ExpressRoute is NOT on by default.** Must create a Route-map (can be empty, then deleted) to upgrade the hub software version to enable ER ECMP.
- **RIU autoscaling is not instantaneous.** Scaling out takes up to 25 minutes. Set minimum RIUs based on peak demand rather than relying on autoscale.
- **Private Endpoints can be affected by RIU scale changes and autoscaling.** Review Private Link best practices before changing hub capacity.
- **Route-maps only summarize; they cannot create more-specific routes.** Do not attempt to use Route-maps to inject more-specific prefixes.
- **Route-maps only support 2-byte ASNs.** 4-byte ASNs are not supported.
- **Reserved ASNs cannot be used for AS-PATH prepending.** Azure (8074, 8075, 12076; 65515, 65517–65520) and IANA reserved ASNs must be avoided in Route-map AS-PATH actions.
- **NAT is incompatible with policy-based (narrow) traffic selectors** on S2S VPN connections.
- **A prefix cannot be modified by both Route-maps AND NAT** on the same connection.
- **BGP peer IP on-premises cannot be in a Dynamic NAT pre-NAT range.** Create a separate Static NAT rule to handle the BGP peering address.
- **Azure Firewall cannot be shared across hubs.** Each secured hub needs its own Firewall instance.
- **Azure Firewall AZ configuration is set at creation.** Existing Firewall without AZ cannot be modified; must delete and redeploy.
- **Maximum 10,000 routes accepted per hub** from all connected resources combined — regardless of RIU count.
- **Maximum address spaces for Routing Intent hubs: 600** directly-connected VNet address spaces per hub. Remote hub VNet spaces do not count toward this limit.
- **IKEv2 P2S: 255-route limit per client.** OpenVPN P2S: 1,000-route limit per client.
- **ASN 0 in AS-Path causes route drops.** Virtual WAN hub drops any route with ASN 0 in the path.
- **Hubs in different Virtual WANs cannot communicate.** Cross-WAN hub connectivity is not supported.
- **Multiple hubs per region** are supported but require separate resource group support via PowerShell only (portal requires same resource group as the WAN resource).
- **VNet address space changes in spoke VNets** propagate automatically — no peering reset needed — but must not overlap with existing spoke VNets.
- **Customer-controlled maintenance** supports S2S VPN, P2S VPN, ER gateways, and Azure Firewall. Not all maintenance types are controllable (platform-critical maintenance is exempt).
- **ExpressRoute Local circuit:** Can only attach to ER gateways in its own region; however, traffic CAN route to spoke VNets in other regions.
- **P2S client pool split between gateway instances** — each instance gets its own sub-range. This is by design and explains split-tunnel route duplication.
- **SLA = 99.95%** at the Virtual WAN platform level; individual component SLAs (Firewall, ER, VPN) are calculated separately. [VERIFY]

---

## Related services

- [VPN Gateway](../services/vpn-gateway.md) — Standalone per-VNet VPN gateway. Use for single-VNet or small-scale connectivity; limited to 100 tunnels vs. Virtual WAN's 1,000+ connections per hub. Cannot coexist in a spoke VNet connected to Virtual WAN.
- [ExpressRoute](../services/expressroute.md) — Private connectivity circuits consumed by Virtual WAN ER gateways. Virtual WAN supports Local, Standard, and Premium ER SKUs.
- [Azure Firewall](../services/azure-firewall.md) — Deployed inside a Virtual WAN Secure Hub. Managed via Azure Firewall Manager for centralized policy. Must be provisioned per hub.
- [Azure Virtual Network](../services/virtual-network.md) — Spoke VNets connect to Virtual WAN hubs via hub virtual network connections. Spoke VNets cannot have their own gateway or Route Server.
- [Private Link](../services/private-link.md) — Private Endpoints in spoke VNets work with Virtual WAN. Traffic to Private Endpoints is exempt from VNet peering charges but incurs Private Link data processing fees.
- [Azure Bastion](../services/bastion.md) — Usable with Virtual WAN with limitations; see Azure Bastion FAQ for vWAN-specific constraints.
- [Network Watcher](../services/network-watcher.md) — Provides VM-level diagnostics (IP flow verify, packet capture, NSG diag, connection troubleshoot). Does not validate datapath through Virtual WAN hubs directly.

---

## Source articles

| Article | Key content |
|---|---|
| [virtual-wan-about.md](../../raw/articles/virtual-wan/virtual-wan-about.md) | Overview, resource types, Basic vs. Standard, connectivity types |
| [virtual-wan-global-transit-network-architecture.md](../../raw/articles/virtual-wan/virtual-wan-global-transit-network-architecture.md) | Global transit architecture, any-to-any paths, security transit patterns |
| [virtual-wan-faq.md](../../raw/articles/virtual-wan/virtual-wan-faq.md) | Limits, scale units, throughput caps, behavioral Q&A |
| [hub-settings.md](../../raw/articles/virtual-wan/hub-settings.md) | RIU table, hub capacity, autoscaling, hub address space, routing preference |
| [gateway-settings.md](../../raw/articles/virtual-wan/gateway-settings.md) | S2S / P2S / ER scale units, Basic vs. Standard gateway types |
| [about-virtual-hub-routing.md](../../raw/articles/virtual-wan/about-virtual-hub-routing.md) | Route tables, association, propagation, labels, routing concepts |
| [about-virtual-hub-routing-preference.md](../../raw/articles/virtual-wan/about-virtual-hub-routing-preference.md) | HRP algorithm, ExpressRoute/VPN/AS-Path preference modes |
| [virtual-wan-expressroute-about.md](../../raw/articles/virtual-wan/virtual-wan-expressroute-about.md) | ER circuit SKUs, gateway performance, ER limits, BGP concepts |
| [point-to-site-concepts.md](../../raw/articles/virtual-wan/point-to-site-concepts.md) | P2S tunnel types, auth methods, user groups/multi-pool, gateway concepts |
| [about-nva-hub.md](../../raw/articles/virtual-wan/about-nva-hub.md) | NVA partners, infrastructure units, hub address space for NVA, lifecycle |
| [route-maps-about.md](../../raw/articles/virtual-wan/route-maps-about.md) | Route-map architecture, match conditions, actions, limitations |
| [pricing-concepts.md](../../raw/articles/virtual-wan/pricing-concepts.md) | Pricing components, scale units, connection units, topology scenarios |
| [monitor-virtual-wan-reference.md](../../raw/articles/virtual-wan/monitor-virtual-wan-reference.md) | Metrics reference for hub router, S2S, P2S, ER gateways |
| [virtual-wan-troubleshooting-overview.md](../../raw/articles/virtual-wan/virtual-wan-troubleshooting-overview.md) | Troubleshooting tools, routing/BGP, datapath, health/logs |
| [secure-virtual-wan.md](../../raw/articles/virtual-wan/secure-virtual-wan.md) | Security best practices: encryption, identity, data protection, logging |
| [disaster-recovery-design.md](../../raw/articles/virtual-wan/disaster-recovery-design.md) | BCDR topologies: multi-link, multi-hub, multi-region |
| [nat-rules-vpn-gateway.md](../../raw/articles/virtual-wan/nat-rules-vpn-gateway.md) | Static/dynamic NAT, ingress/egress modes, BGP translation |
| [upgrade-virtual-wan.md](../../raw/articles/virtual-wan/upgrade-virtual-wan.md) | Basic → Standard upgrade (one-way) |
| [virtual-wan-ipsec.md](../../raw/articles/virtual-wan/virtual-wan-ipsec.md) | Default and custom IPsec/IKE policy combinations |
| [scenario-any-to-any.md](../../raw/articles/virtual-wan/scenario-any-to-any.md) | Any-to-any routing scenario, default route table behavior |
| [migrate-from-hub-spoke-topology.md](../../raw/articles/virtual-wan/migrate-from-hub-spoke-topology.md) | Migration guide from customer-managed hub-and-spoke to Virtual WAN |
| [create-bgp-peering-hub-portal.md](../../raw/articles/virtual-wan/create-bgp-peering-hub-portal.md) | BGP peering with hub router, dual-IP peer requirement |
| *(+ 110 additional articles covering P2S clients, routing scenarios, partners, automation, cross-tenant VNets, specific NVA configs, and operational how-tos)* | |
