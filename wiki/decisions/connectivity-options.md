# Hybrid & Inter-Network Connectivity: Decision Guide

> **Compiled:** 2026-04-10 | **Sources:** wiki/services/ pages (vpn-gateway, expressroute, virtual-wan, virtual-network, bastion, route-server) + raw/articles/networking/hybrid-connectivity/hybrid-connectivity.md | **Status:** ✅ current

---

## Quick-pick matrix

> Legend: ✅ Primary / recommended fit | ⚠️ Possible but with constraints | ❌ Not applicable / anti-pattern

| Scenario | VPN Gateway | ExpressRoute | Virtual WAN | VNet Peering | Azure Bastion |
|---|---|---|---|---|---|
| **On-premises → Azure (general)** | ✅ S2S over internet; IPsec encrypted; cost-effective | ✅ Dedicated private link; use when latency/bandwidth/compliance requires it | ✅ If you also have branches; hub S2S or ER gateway | ❌ No on-prem connectivity | ❌ Not for network connectivity |
| **Branch-heavy enterprise (>10 sites)** | ⚠️ Max ~100 S2S tunnels per gateway; complex to manage at scale | ⚠️ Expensive per branch; no SD-WAN integration | ✅ Purpose-built; 1,000 S2S connections per hub; 30+ SD-WAN partner integrations | ❌ | ❌ |
| **VNet-to-VNet, same region** | ⚠️ Works but gateway overhead; ~10–15 s failover latency; egress cost | ❌ Anti-pattern; Microsoft explicitly discourages it | ✅ Via Standard hub transit | ✅ Preferred: lowest latency, no gateway, free transfer | ❌ |
| **VNet-to-VNet, cross-region** | ⚠️ VNet-to-VNet connection type; encrypted; cross-region egress charges | ❌ Anti-pattern | ✅ Inter-hub automatic in Standard SKU; uses Microsoft backbone | ✅ Global VNet Peering; low-latency backbone; Basic LB not reachable [VERIFY] | ❌ |
| **Remote user → Azure (P2S)** | ✅ P2S via OpenVPN/SSTP/IKEv2; up to 10,000 users on VpnGw5AZ [VERIFY] | ❌ | ✅ Virtual WAN P2S; up to 100,000 concurrent users [VERIFY]; global profile auto-selects nearest hub | ❌ | ⚠️ Bastion is for admin RDP/SSH to VMs only, not general user access |
| **Admin RDP/SSH to VMs (no public IP)** | ⚠️ P2S VPN to reach VM on private IP; requires VPN client | ❌ | ⚠️ P2S VPN via VWAN hub | ❌ | ✅ Purpose-built; TLS 443; portal or native client; no public IP on VM |
| **On-prem → on-prem via Azure backbone** | ❌ | ✅ ExpressRoute Global Reach; links two ER circuits over Microsoft backbone | ⚠️ Routing Intent with private policy can route ER-to-ER through hub (adds latency vs. Global Reach) | ❌ | ❌ |
| **Internet → private VM (secure access)** | ❌ Not designed for inbound internet | ❌ | ❌ | ❌ | ✅ Premium SKU with private-only deployment (via ER/VPN); all SKUs accept inbound TLS from internet on port 443 |
| **Encrypted backup/DR data transfer** | ⚠️ Adequate; internet path; encryption included | ✅ High-bandwidth, private; no internet bottleneck; Local/Unlimited SKU avoids egress charges | ⚠️ If already deployed | ❌ | ❌ |
| **Compliance: no-internet path** | ❌ Uses public internet (encrypted but not private) | ✅ Traffic never traverses public internet | ✅ ER circuits in VWAN qualify | ❌ | ✅ Premium private-only deployment (via ER/VPN) |

---

## Connectivity options overview

### Azure VPN Gateway

IPsec/IKE VPN service deployed as a virtual network gateway inside a VNet's `GatewaySubnet`. All traffic is encrypted over the **public internet**. A single gateway can host S2S, P2S, and VNet-to-VNet connection types simultaneously, sharing aggregate throughput. Supports BGP for dynamic routing and active-active mode for zero-interruption failover. Can coexist with an ExpressRoute gateway in the same VNet for failover or mixed connectivity patterns.

**Typical use case:** Cost-effective encrypted connectivity for one or a handful of on-premises sites; remote workforce P2S; encrypted failover for ExpressRoute.

**Bandwidth / latency profile:** Up to ~10 Gbps aggregate (VpnGw5AZ) [VERIFY]; latency varies with internet path quality (jitter possible); not suited for sub-10 ms latency requirements.

**Key constraints:** Max ~100 S2S tunnels per gateway (VpnGw4–5); 1 VPN gateway per VNet; 45+ min creation time; Basic SKU is dev/test only (no SLA, no RADIUS, no IKEv2 P2S); policy-based VPN creation blocked in portal since Oct 2023; non-AZ SKUs (VpnGw1–5) retiring Sep 16, 2026.

---

### Azure ExpressRoute

Private, dedicated Layer 3 BGP connectivity from on-premises to Azure via a connectivity provider or directly into Microsoft's global network (ExpressRoute Direct). Traffic **never traverses the public internet**. Every circuit has primary + secondary connections to two separate MSEEs (built-in redundancy). Supports Private Peering (Azure VNets via private IPs) and Microsoft Peering (M365, Azure PaaS via public IPs). Global Reach links two ER circuits together for on-prem–to–on-prem private routing over Microsoft's backbone.

**Typical use case:** Production workloads requiring predictable latency, high bandwidth (≥1 Gbps sustained), compliance mandates for private network paths, or massive data ingestion into Azure.

**Bandwidth / latency profile:** 50 Mbps–10 Gbps (provider circuits); 10/100/400 Gbps (ExpressRoute Direct); latency is consistent and deterministic; BFD reduces failure detection to <1 second.

**Key constraints:** Provider provisioning takes **weeks** (not minutes); no encryption by default (MACsec on Direct only; add IPsec over ER private peering for L3 encryption); ER gateway required in VNet (adds ~20–30 min provisioning); VNets per circuit limited (10 Standard, up to 100 Premium) [VERIFY]; MTU is 1,400 bytes (not 1,500 — tune VMs).

---

### Azure Virtual WAN

Microsoft-managed networking-as-a-service platform providing **global transit hub-and-spoke** architecture. Microsoft-managed virtual hubs act as the switching core; all Standard SKU hubs are automatically full-meshed via the Microsoft backbone. Unifies S2S VPN, P2S VPN, ExpressRoute, VNet-to-VNet transit, and secure internet routing under one resource hierarchy. 30+ SD-WAN partner integrations automate branch provisioning.

**Typical use case:** Enterprises with many branch offices; global multi-region networks requiring any-to-any connectivity without managing customer-owned hub VNets and transit configurations; large remote user populations.

**Bandwidth / latency profile:** S2S up to 20 Gbps aggregate per hub [VERIFY]; P2S up to 200 Gbps / 100,000 users at max scale units [VERIFY]; ER up to 20 Gbps per hub (10 scale units × 2 Gbps) [VERIFY]; hub router up to 50 Gbps at 50 RIUs [VERIFY]; single TCP flow hard-limited to 1.5 Gbps [VERIFY].

**Key constraints:** Spoke VNets **cannot** have their own VNet gateway or Azure Route Server; a VNet can connect to **only one** hub; Basic SKU is S2S-only with no hub mesh or VNet transit; IPv6 **not supported** in hub or gateways; Basic→Standard upgrade is one-way; hub address space is **immutable** after creation (requires /22+ if Azure Firewall deployed); ECMP for ExpressRoute is not enabled by default (requires Route-map workaround).

---

### VNet Peering (Local and Global)

Peering creates a low-latency, private, non-encrypted path between two VNets over Microsoft's backbone — either within the same region (Local Peering) or across regions (Global Peering). No gateway required. Traffic is routed by Azure SDN at line rate with the same latency profile as intra-VNet traffic. Peering is **not transitive**: VNet A peered with VNet B and VNet B peered with VNet C does not mean A can reach C (requires hub-and-spoke with gateway transit, or a third peering).

**Typical use case:** Hub-and-spoke topology where spokes need to reach shared services in a hub; same-region VNet-to-VNet connectivity; connecting two VNets in different subscriptions or tenants.

**Bandwidth / latency profile:** Line-rate; lowest possible latency (same as intra-VNet); intra-region data transfer free (charged at normal egress rates cross-region) [VERIFY].

**Key constraints:** Non-transitive by default (route through hub requires gateway transit or NVA); Basic Load Balancer frontend IPs **not reachable** across Global Peering; max 500 peered VNets per VNet (1,000 with VNet Manager) [VERIFY]; both ends of peering must be non-overlapping; UDR next-hop type `Virtual Network Gateway` works for VPN but **not** ExpressRoute gateways.

---

### Azure Bastion

Fully managed PaaS that terminates RDP/SSH sessions over TLS port 443 from the Azure portal or native clients, reaching VMs by private IP only. No public IP required on VMs, no agent, no VPN client. Deployed into a mandatory `/26` subnet named `AzureBastionSubnet`. In hub-and-spoke topologies, a single Bastion in the hub serves all spoke VMs via VNet peering.

**Typical use case:** Secure administrative access to VMs without public IP exposure; compliance environments requiring audited session logs (Premium SKU); hub-and-spoke centralized VM access.

**Bandwidth / latency profile:** RDP/SSH sessions over HTTPS; not a bulk data transfer path; session quality is interactive, not bandwidth-constrained in normal usage.

**Key constraints:** IPv4 only; does **not** support Azure Virtual Desktop, RDS, or being deployed inside a Virtual WAN hub; UDR and Private Link not supported on `AzureBastionSubnet`; force-tunneled networks (0.0.0.0/0 via ER/VPN) break Bastion control plane — remove default route from Bastion VNet; Premium private-only deployment requires ER private peering or VPN for client access.

---

## Decision flowchart (text)

```
START: What connectivity do you need?
│
├─► Secure admin RDP/SSH to VMs?
│       └─► Use AZURE BASTION (no public IP on VM; TLS 443)
│
├─► VNet-to-VNet only (no on-premises)?
│       ├─► Same region? → Use VNet PEERING (lowest latency, no cost overhead)
│       └─► Cross-region? → Use GLOBAL VNet PEERING (preferred) or Virtual WAN inter-hub
│
├─► On-premises ↔ Azure hybrid connectivity?
│   │
│   ├─► Need PRIVATE path (no internet), dedicated bandwidth, or compliance mandate?
│   │       ├─► < 10 Gbps, provider circuit acceptable? → EXPRESSROUTE (Standard/Premium)
│   │       ├─► ≥ 10 Gbps or direct fiber into Microsoft? → EXPRESSROUTE DIRECT (10/100/400 Gbps)
│   │       └─► Want private + encrypted? → EXPRESSROUTE + IPsec over ER private peering
│   │
│   ├─► Internet path acceptable (or ER too expensive/slow to provision)?
│   │       ├─► ≤ ~100 sites? → VPN GATEWAY (S2S; route-based; BGP recommended)
│   │       └─► > 100 sites or SD-WAN integration needed? → VIRTUAL WAN (Standard SKU)
│   │
│   └─► Already have ExpressRoute AND want encrypted failover?
│           └─► VPN GATEWAY COEXISTENCE (same VNet as ER gateway; VPN = internet backup)
│
├─► Remote users (P2S)?
│       ├─► < ~10,000 users? → VPN GATEWAY P2S (OpenVPN/IKEv2; Entra ID MFA supported)
│       └─► > 10,000 users or global distribution? → VIRTUAL WAN User VPN (P2S; up to 100,000 users)
│
├─► On-premises ↔ On-premises via Azure backbone?
│       └─► Use EXPRESSROUTE GLOBAL REACH (links two ER circuits; no hub required)
│
└─► Branch-heavy enterprise (many sites, SD-WAN, any-to-any routing)?
        └─► VIRTUAL WAN STANDARD (automated hub, full mesh, SD-WAN partner support)
```

---

## Head-to-head comparisons

### VPN Gateway vs ExpressRoute

| Dimension | VPN Gateway | ExpressRoute |
|---|---|---|
| **Network path** | Public internet (IPsec encrypted) | Private dedicated connection (no internet) |
| **SLA** | 99.9% (active-standby) / 99.95% (active-active) [VERIFY] | 99.95% circuit SLA [VERIFY] |
| **Max bandwidth (single gateway)** | ~10 Gbps (VpnGw5AZ) [VERIFY] | 10 Gbps (provider) / 400 Gbps (Direct) |
| **Typical latency** | Variable; internet-dependent; 10–100+ ms | Consistent, deterministic; typically <10 ms over private path |
| **Encryption** | ✅ IPsec/IKE always on | ❌ None by default; MACsec (Direct only); IPsec over ER private peering (optional) |
| **Provisioning time** | 45 minutes (gateway creation) | Weeks (provider circuit provisioning) |
| **Cost model** | Hourly gateway compute + egress data transfer | Monthly port/circuit charge + metered or unlimited data; gateway compute |
| **Failover / redundancy** | Active-active recommended; BGP multi-path | Dual MSEE links built-in; dual circuits for site-level resilience; BFD for <1s detection |
| **Compliance (no internet)** | ❌ Traffic transits internet | ✅ Never touches public internet |
| **Coexistence** | ✅ Can coexist with ER gateway in same VNet | ✅ Can coexist with VPN Gateway (same VNet) for encrypted fallback |
| **Best for** | Cost-sensitive, lower-bandwidth, rapid setup | Production workloads with latency/bandwidth/compliance requirements |

> ⚠️ **Coexistence requirement:** Both gateways can share one VNet but require a **larger GatewaySubnet** (/27 minimum recommended; /26+ preferred). The `GatewaySubnet` must accommodate IPs for both gateway types. Deploy the ER gateway first, then the VPN gateway.

---

### ExpressRoute vs Virtual WAN (for ER connectivity)

| Dimension | Standalone ExpressRoute + VNet Gateway | ExpressRoute via Virtual WAN Hub |
|---|---|---|
| **Topology** | Customer-managed hub VNet; gateway per VNet or shared via hub | Microsoft-managed virtual hub; ER gateway is a hub component |
| **BGP control** | Full control via VNet gateway and Route Server | Hub router manages BGP; Route-maps for per-connection manipulation |
| **Routing complexity** | Manual UDRs or Route Server for NVA integration | Hub router automates route propagation; custom route tables for segmentation |
| **Branch scale** | Limited by gateway SKU and VNet topology | 1,000 S2S + ER circuits per hub; hubs full-meshed |
| **SD-WAN integration** | Manual; partner-specific | ✅ 30+ certified SD-WAN partners; zero-touch IPsec provisioning |
| **VNet-to-VNet transit** | Via gateway transit (hub) or peering | ✅ Automatic in Standard SKU via hub router |
| **ER ECMP** | Standard BGP ECMP | Disabled by default; Route-map creation required to enable [VERIFY] |
| **ER max bandwidth per hub** | Per gateway SKU (up to ErGwScale, ~40+ Gbps [VERIFY]) | 20 Gbps (10 scale units × 2 Gbps) [VERIFY] |
| **Inter-hub ER-to-ER transit** | Via Global Reach (bypasses hub) | Via Routing Intent (routes through hub security appliance) |
| **IPv6** | ✅ Supported on ER gateway | ❌ Not supported in Virtual WAN hub or gateways |
| **Spoke VNet constraints** | Spoke can have own gateway; can have Route Server | Spoke **cannot** have own gateway or Route Server |
| **Best for** | Environments needing full routing control; IPv6; custom NVA topologies | Large enterprises wanting managed backbone; branch + ER + P2S unified |

---

### VNet Peering vs VPN Gateway (VNet-to-VNet)

| Dimension | VNet Peering | VPN Gateway (VNet-to-VNet) |
|---|---|---|
| **Latency** | Same as intra-VNet (lowest possible) | Adds gateway processing; ~1–2 ms additional [VERIFY] |
| **Bandwidth** | Line-rate; no gateway bottleneck | Shared with all other tunnels; aggregate per SKU |
| **Encryption** | ❌ No encryption (use VNet Encryption feature if needed) | ✅ IPsec/IKE always on |
| **Intra-region data transfer** | Free [VERIFY] | Free [VERIFY] |
| **Cross-region data transfer** | Billed at standard egress rates [VERIFY] | Billed at region-pair rates [VERIFY] |
| **Transitive routing** | ❌ Not transitive; requires hub with gateway transit or NVA | ✅ Transitive via gateway (BGP required) |
| **Cross-subscription** | ✅ Supported | ✅ Supported |
| **Cross-tenant** | ✅ Supported | ✅ Supported |
| **Gateway required** | ❌ None (no provisioning delay) | ✅ Required (45+ min creation) |
| **Overlapping address space** | ❌ Not allowed | ✅ NAT rules (VpnGw2+) resolve overlaps |
| **Best for** | Same-region VNet-to-VNet; hub-spoke within a region | Cross-region where encryption is required; overlapping address spaces; transit routing needed |

> **Rule of thumb:** Use peering when possible (lower latency, simpler); use VPN Gateway VNet-to-VNet when you need encryption between VNets, overlap resolution (NAT), or BGP-based transit routing.

---

## Common connectivity patterns

### Pattern 1: Hub-and-spoke with VPN Gateway (single-region)

A hub VNet hosts the VPN Gateway in `GatewaySubnet` plus shared services (Azure Firewall, DNS, Bastion). Spoke VNets connect via Local VNet Peering with **Use Remote Gateways** enabled on spokes and **Allow Gateway Transit** on hub peerings. On-premises connects via S2S VPN to the hub gateway.

- **Routing:** Enable BGP on VPN Gateway for automatic route propagation to spokes; avoid manual UDRs on every spoke for on-premises prefixes.
- **Access control:** Place Azure Firewall in hub; UDR on each spoke subnet forces traffic to firewall before exiting hub.
- **Limit:** Max ~100 S2S tunnels per gateway; consider Virtual WAN at that scale.
- **Bastion:** Deploy one Bastion in hub `AzureBastionSubnet`; serves all spoke VMs via peering.

---

### Pattern 2: ExpressRoute + VPN Gateway Coexistence (failover)

Both an ExpressRoute gateway (type=ExpressRoute) and a VPN Gateway (type=Vpn) deployed in the **same VNet's GatewaySubnet**. ExpressRoute is the primary path; S2S VPN over internet serves as encrypted warm standby.

- **Coexistence requirement:** GatewaySubnet must be `/27` or larger (ideally `/26`); both gateways share the subnet IP space.
- **Routing failover:** Use BGP on both gateways; advertise same prefixes from on-premises over both paths. AS-path prepend on VPN side makes ER preferred under normal operation. When ER fails, BGP reconverges to VPN path automatically.
- **Traffic during failover:** BFD on ER reduces detection to <1 s; BGP hold timer (180 s) is the fallback if BFD not configured.
- **Azure Route Server:** Can mediate route exchange between ER gateway, VPN gateway, and an NVA in the same VNet (enable branch-to-branch on Route Server).
- **Warning:** ER circuit-to-circuit transit is not supported through Route Server — use Global Reach instead.

---

### Pattern 3: Virtual WAN for branch-heavy enterprise

Deploy a Standard Virtual WAN with hubs in each primary Azure region. Branch CPE devices (SD-WAN or vanilla VPN) terminate IPsec tunnels on hub S2S VPN gateways. Each hub can handle up to **1,000 S2S connections (2,000 IPsec tunnels)** [VERIFY]. ExpressRoute circuits for data-center sites connect to the hub ER gateway. Remote users connect via P2S User VPN with a global profile (nearest hub auto-selected). All hubs are automatically full-meshed — branch in Region A reaches spoke VNet in Region B via the Microsoft backbone with no customer-managed transit.

- **Security:** Deploy Azure Firewall in each hub (Secure Virtual Hub) and enable Routing Intent to inspect all private and/or internet traffic through the firewall.
- **SD-WAN:** Use a certified partner NVA in the hub for zero-touch branch provisioning.
- **Key constraint:** Hub address space is **immutable** at creation; size to `/22+` if Firewall will be deployed. Plan this before hub creation — it cannot be changed later.
- **Cost:** Hub base fee ~$0.25/hr [VERIFY] + gateway scale units + hub data processing fees for VNet-to-VNet flows.

---

### Pattern 4: Multi-region with Global VNet Peering

Two or more regional hub VNets in different Azure regions, each with their own VPN Gateway and/or ExpressRoute gateway. The regional hubs are connected via **Global VNet Peering** with **Use Remote Gateways** / **Allow Gateway Transit** configured.

- **Benefit:** On-premises sites connected to one regional hub can reach workloads in spoke VNets connected to the other regional hub via gateway transit across the global peering.
- **Routing:** Requires BGP on VPN gateways; prefixes learned by one gateway are propagated across the peering to the other region's spoke VNets.
- **Alternative:** Azure Virtual WAN Standard automatically achieves this without manual peering and gateway transit configuration.
- **Limit:** Basic Load Balancer frontend IPs are **not reachable** across Global VNet Peering — upgrade to Standard LB.
- **FastPath note:** FastPath over ER supports same-region peering only; cross-region peering is NOT supported with FastPath.

---

### Pattern 5: Remote access — Bastion vs P2S VPN

| Criterion | Azure Bastion | P2S VPN Gateway |
|---|---|---|
| **Client software** | Browser (portal) or native RDP/SSH client | Azure VPN Client (or native OS client for IKEv2/SSTP) |
| **Accesses** | Individual VMs (RDP/SSH) | Entire VNet address space (all private IPs) |
| **Authentication** | Azure RBAC + Entra ID (portal auth) | Certificate / RADIUS / Entra ID (OpenVPN only) |
| **Conditional Access / MFA** | Via portal authentication | ✅ OpenVPN + Entra ID supports CA policies |
| **Session recording** | ✅ Premium SKU; immutable audit trail to Blob Storage | ❌ Not available |
| **Suitable for developers needing private APIs** | ❌ RDP/SSH only | ✅ Full network access |
| **Suitable for VM admin** | ✅ Purpose-built; no public IP on VM | ⚠️ Overkill; gives broader network access |
| **Cost** | Hourly per Bastion instance + data transfer | Hourly gateway + per-connection (P2S included in compute charge) |
| **Recommendation** | VM administrators, compliance-heavy environments, shared-access (shareable links) | Developers, DevOps accessing private endpoints and APIs, teams needing full VNet reach |

---

## Limits & key constraints

> All values tagged [VERIFY] — confirm against Azure service limit documentation before treating as authoritative.

| Service | Limit | Value | Notes |
|---|---|---|---|
| **VPN Gateway** | Max S2S tunnels (VpnGw1–3) | 30 [VERIFY] | Per gateway |
| **VPN Gateway** | Max S2S tunnels (VpnGw4–5 / AZ) | 100 [VERIFY] | Per gateway; use Virtual WAN beyond this |
| **VPN Gateway** | Max aggregate throughput (VpnGw5AZ) | ~10 Gbps [VERIFY] | Shared across all tunnels |
| **VPN Gateway** | Max aggregate throughput (VpnGw1AZ) | ~650 Mbps [VERIFY] | |
| **VPN Gateway** | P2S connections (VpnGw1, SSTP) | 128 | Independent from IKEv2 limit |
| **VPN Gateway** | P2S connections (VpnGw1, IKEv2) | 250 | Independent from SSTP limit |
| **VPN Gateway** | Active-standby failover (planned) | 10–15 seconds | S2S/VNet-to-VNet; P2S must reconnect |
| **VPN Gateway** | Active-standby failover (unplanned) | 1–3 minutes | |
| **VPN Gateway** | GatewaySubnet minimum | /27 (production) / /29 (Basic) | /26+ recommended when coexisting with ER gateway |
| **VPN Gateway** | NAT-capable SKUs | VpnGw2–5, VpnGw2AZ–5AZ | S2S only; not VNet-to-VNet or P2S |
| **VPN Gateway** | Non-AZ SKU retirement | Sep 16, 2026 | All new gateways must be AZ SKUs (effective Nov 1, 2025) |
| **ExpressRoute** | Bandwidth options (provider) | 50 Mbps – 10 Gbps | 8 tiers |
| **ExpressRoute** | Bandwidth (ExpressRoute Direct) | 10 / 100 / 400 Gbps | 400 Gbps: limited locations, enrollment required [VERIFY] |
| **ExpressRoute** | VNets per Standard circuit | 10 [VERIFY] | |
| **ExpressRoute** | VNets per Premium circuit | Up to 100 [VERIFY] | Scaled by circuit bandwidth |
| **ExpressRoute** | Max circuits per subscription | 50 (default) [VERIFY] | Increasable via support ticket |
| **ExpressRoute** | Circuits to same VNet (same peering location) | 4 | ECMP across all 4 |
| **ExpressRoute** | Circuits to same VNet (different peering locations) | 16 | ECMP only across 4; rest = failover |
| **ExpressRoute** | IPv4 BGP prefixes to Microsoft (Standard) | 4,000 | Session drops if exceeded |
| **ExpressRoute** | IPv4 BGP prefixes to Microsoft (Premium) | 10,000 | Session drops if exceeded |
| **ExpressRoute** | Total routes on ER gateway | 11,000 | Includes all VNet + on-premises + peered VNet prefixes |
| **ExpressRoute** | FastPath IP limit (provider ≤10 Gbps) | 25,000 IPs | Excess falls back through gateway |
| **ExpressRoute** | MTU | 1,400 bytes | Tune VM TCP/IP stack accordingly |
| **ExpressRoute** | BGP hold timer (Microsoft side) | 180 seconds | Not configurable by customer; BFD reduces detection to <1 s |
| **ExpressRoute** | Microsoft BGP ASN | 12076 | Reserved ASNs 65515–65520 cannot be used by customer |
| **Virtual WAN** | S2S connections per hub | 1,000 (2,000 IPsec tunnels) [VERIFY] | |
| **Virtual WAN** | S2S aggregate throughput per hub | 20 Gbps [VERIFY] | |
| **Virtual WAN** | ER scale units per hub | Max 10 (20 Gbps) [VERIFY] | 1 scale unit = 2 Gbps |
| **Virtual WAN** | P2S max concurrent users per hub | 100,000 [VERIFY] | At 200 scale units |
| **Virtual WAN** | P2S max aggregate throughput | 200 Gbps [VERIFY] | At 200 scale units |
| **Virtual WAN** | Hub router max throughput (50 RIUs) | 50 Gbps [VERIFY] | |
| **Virtual WAN** | Hub router max spoke VMs (50 RIUs) | 50,000 [VERIFY] | |
| **Virtual WAN** | Max routes per hub | 10,000 | Regardless of RIU count |
| **Virtual WAN** | Single TCP flow limit | 1.5 Gbps [VERIFY] | Hard ceiling per flow |
| **Virtual WAN** | Hub address space | Immutable after creation | Minimum /24; /22+ for Azure Firewall |
| **Virtual WAN** | IPv6 in hub | ❌ Not supported | Advertising IPv6 from on-premises breaks IPv4 |
| **Virtual WAN** | IKEv2 P2S tunnel routes | 255 max routes | OpenVPN: 1,000 max routes |
| **VNet Peering** | Peered VNets per VNet (default) | 500 [VERIFY] | |
| **VNet Peering** | Peered VNets per VNet (VNet Manager) | 1,000 [VERIFY] | |
| **Azure Bastion** | AzureBastionSubnet minimum | /26 | Must be named exactly `AzureBastionSubnet` |
| **Azure Bastion** | Basic SKU instances (fixed) | 2 | Cannot scale |
| **Azure Bastion** | Standard/Premium SKU instances | 2–50 [VERIFY] | 20 RDP / 40 SSH sessions per instance |
| **Azure Bastion** | Max concurrent RDP (50 instances) | 1,000 [VERIFY] | |
| **Azure Bastion** | Max concurrent SSH (50 instances) | 2,000 [VERIFY] | |
| **Route Server** | One per VNet | 1 | Cannot deploy more than one Route Server per VNet |
| **Route Server** | RouteServerSubnet minimum | /26 | Must be named exactly `RouteServerSubnet` |
| **Route Server** | BGP ASN format | 16-bit only | 32-bit ASNs not supported |
| **Route Server** | Max spoke VMs (default 2 RIUs) | 4,000 [VERIFY] | |
| **Route Server** | Max spoke VMs (48 RIUs) | 50,000 [VERIFY] | Hard maximum |

---

## BGP ASN reserved values (do not assign to NVAs or on-premises devices)

| Range | Reserved by |
|---|---|
| 8074, 8075, 12076 | Azure (public) |
| 65515–65520 | Azure (private / internal) |
| 23456, 64496–64511, 65535–65551 | IANA reserved |

> **Note:** Azure VPN Gateway default ASN is **65515** [VERIFY]. Azure Route Server and Virtual WAN hub router also use **65515**. On-premises BGP peers and NVAs must use a different ASN.

---

## Related pages

### Service pages
- [VPN Gateway](../services/vpn-gateway.md) — full SKU table, cryptography options, HA patterns, migration timeline
- [ExpressRoute](../services/expressroute.md) — peering types, Global Reach, FastPath, MACsec, NAT requirements, QoS
- [Azure Virtual WAN](../services/virtual-wan.md) — architecture patterns, Secure Virtual Hub, SD-WAN integration, routing deep-dive
- [Azure Virtual Network](../services/virtual-network.md) — VNet peering, gateway transit, UDRs, address space planning
- [Azure Bastion](../services/bastion.md) — SKU comparison, NSG requirements, architecture patterns, session recording
- [Azure Route Server](../services/route-server.md) — NVA BGP integration, branch-to-branch, ER + VPN coexistence via BGP

### Raw source
- [What is hybrid connectivity?](../../raw/articles/networking/hybrid-connectivity/hybrid-connectivity.md) — Azure overview article covering VPN Gateway, ExpressRoute, Virtual WAN decision factors

---

> **Compiler notes:**
> - All bandwidth figures (VpnGw SKU throughput, VWAN gateway scale unit throughput, ErGwScale performance) are tagged `[VERIFY]` because the source wiki pages inherit the same `[VERIFY]` from include-file gaps in the raw articles. Consult Azure pricing and limits pages before publishing to end users.
> - The VWAN S2S pricing `[CONFLICT]` ($0.261/hr vs $0.361/hr per scale unit in `pricing-concepts.md`) is unresolved — do not cite VWAN S2S pricing figures from this guide until verified against the current Azure pricing page.
> - ExpressRoute **does not encrypt traffic by default** — this is a common misconception. The private path is dedicated but not encrypted. Flag this explicitly in any security review.
> - VPN Gateway non-AZ SKUs (VpnGw1–5) creation was blocked November 1, 2025; retirement is September 16, 2026. All new designs must use AZ SKUs.