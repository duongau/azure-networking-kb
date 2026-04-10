# Azure Virtual WAN vs DIY Hub-Spoke

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Both patterns implement a hub-and-spoke WAN topology in Azure. The fundamental choice is: **do you want Microsoft to manage the hub routing infrastructure**, or do you want full control? This page compares them across routing complexity, cost, scale, NVA support, firewall integration, and operational overhead.

---

## Core comparison

| Dimension | DIY Hub-Spoke | Azure Virtual WAN (Standard) |
|---|---|---|
| **Hub ownership** | Customer — you manage hub VNet, gateways, UDRs, peerings | Microsoft — virtual hub is a Microsoft-provisioned resource |
| **Transitive routing (spoke-to-spoke)** | ❌ Non-transitive by default — manual UDRs + Firewall rules required | ✅ Automatic — hub router handles transitive routing without UDRs |
| **UDR management** | O(N²) — every new spoke requires UDR entries on all other spokes | ✅ None for basic any-to-any — hub router programs routes automatically |
| **Multi-region hub meshing** | Manual — Global VNet peering + custom routing + NVA tunnels | ✅ Automatic — all Standard WAN hubs are full-mesh over Microsoft backbone |
| **S2S VPN branch connections** | Up to 100 tunnels per standalone VPN Gateway | Up to 1,000 connections (2,000 tunnels) per hub; SD-WAN partner automation |
| **P2S user VPN scale** | Per-SKU limit (VpnGw1AZ: 128 SSTP + 250 IKEv2) | Up to 100,000 concurrent users / 200 Gbps at max scale (200 SU) [VERIFY] |
| **ExpressRoute integration** | Standard ERGateway in hub VNet | Hub ER gateway; up to 20 Gbps (10 SU) [VERIFY]; ER ECMP requires Route-map creation |
| **SD-WAN partner automation** | Manual — no native zero-touch provisioning | ✅ 30+ certified partners (Cisco, VMware, Versa, etc.) — zero-touch via Azure APIs |
| **IPv6 support** | ✅ Dual-stack (VNet + VPN Gateway) | ❌ Not supported in virtual hub or hub gateways |
| **Azure Firewall integration** | Deploy Azure Firewall in hub VNet; manual UDRs on all spoke subnets | Secured Virtual Hub — Firewall in hub; Routing Intent automates all UDRs |
| **Third-party NVA in hub** | Deploy NVA VM in hub; requires Route Server for dynamic routing | ✅ Select NVAs (Barracuda, Check Point, Cisco, Fortinet, Palo Alto) deployed directly in hub as managed app |
| **Routing control** | ✅ Full — custom route tables, BGP policy, UDR per-subnet | Limited — route-maps for basic manipulation; no arbitrary UDRs in hub |
| **Spoke VNet gateway** | ✅ Allowed (gateway transit from hub) | ❌ Spoke VNets cannot have virtual network gateways or Azure Route Server |
| **One VNet, multiple hubs** | ✅ Possible (dual peering) | ❌ One VNet can connect to only one virtual hub |
| **Hub address space** | Flexible; can be resized (address space can be added) | ⚠️ Immutable after creation — plan minimum /24; /22 if deploying Azure Firewall |
| **Hub base cost** | VNet is free; pay for gateway SKUs, Firewall, peering data | $0.25/hr per Standard hub [VERIFY] + gateway scale units + data processing fees |
| **Hub routing throughput** | Firewall/NVA throughput (30–100 Gbps Firewall [VERIFY]) | Hub router: 3 Gbps (2 RIU) to 50 Gbps (50 RIU); single TCP flow limited to 1.5 Gbps [VERIFY] |
| **Max spoke VMs** | 500 peerings/hub VNet [VERIFY]; ~unlimited VMs across spokes | Up to 50,000 VMs at 50 RIUs [VERIFY] |
| **Route limits** | 400 UDRs/route table [VERIFY] (1,000 with AVNM) | 10,000 routes total per hub (all connected resources) [VERIFY] |
| **Operational model** | IaC-driven (Bicep/Terraform); mature tooling; full audit trail | Azure portal + APIs; less IaC-friendly for routing configs; Insights dashboard |

---

## Firewall integration comparison

| Scenario | DIY Hub-Spoke | Azure Virtual WAN |
|---|---|---|
| **Azure Firewall in hub** | Manually deploy to `AzureFirewallSubnet` (/26); manually add UDRs on every spoke subnet for every flow type | **Secured Virtual Hub** — Firewall deployed in hub; Routing Intent sets internet + private routing policies once |
| **Internet traffic inspection** | UDR `0.0.0.0/0 → Firewall private IP` on every spoke subnet; disable BGP propagation on spoke route tables | Routing Intent: Internet Traffic Routing Policy → all internet traffic through Firewall hub-wide |
| **East-west (spoke-to-spoke) inspection** | UDR for each spoke CIDR → Firewall private IP on every other spoke subnet | Routing Intent: Private Traffic Routing Policy → all private traffic through Firewall |
| **Inter-hub inspection** | Manual tunnels + NVA or not supported natively | ✅ Routing Intent with inter-hub Routing Policies — traffic between hubs inspected in each hub's Firewall |
| **Firewall per-hub requirement** | One Firewall per hub VNet | One Firewall per virtual hub — cannot be shared across hubs |
| **AZ deployment for Firewall** | Configure at creation — ✅ straightforward | ⚠️ Must be explicitly configured at hub Firewall creation; **cannot be changed** on existing Firewall — delete and redeploy |
| **Hub address space for Firewall** | `/26` for `AzureFirewallSubnet` + routing room | Virtual hub must be **/22 or larger** when Azure Firewall is deployed |
| **UDR maintenance** | High — each new spoke = new UDR entries everywhere | None — Routing Intent manages all route programming automatically |

---

## Cost model comparison

| Cost component | DIY Hub-Spoke | Azure Virtual WAN (Standard) |
|---|---|---|
| Hub VNet | Free | $0.25/hr per hub [VERIFY] |
| VPN Gateway | VpnGw1AZ–5AZ hourly rates [VERIFY] | S2S VPN: ~$0.361/hr per scale unit [VERIFY — CONFLICT in source: $0.261 vs $0.361; verify pricing page] |
| ER Gateway | ERGw1Az–ErGwScale hourly rates | ER gateway: $2/hr per scale unit [VERIFY] |
| Data processing | VNet peering charges per GB both directions | Hub data processing fee for VNet-to-VNet flows [VERIFY]; peering not charged (VNet connection replaces peering) |
| Azure Firewall | Standard: ~$1.25/hr + $0.016/GB [VERIFY] | Same Firewall pricing; Routing Intent itself is free |
| NVA (third-party) | NVA VM compute + licensing | Hub NVA Infrastructure Units: ~$0.25/IU/hr [VERIFY] + vendor licensing |

**Rule of thumb:**
- **DIY hub-spoke is cheaper** for simple topologies with few branches and spokes, where you can manage UDRs manually
- **Virtual WAN becomes cost-competitive** when branch count exceeds ~30–50 sites, or when multi-region transit is needed (eliminates cost of transit VNets and cross-region NVA tunnels)

---

## Decision guide

| Criterion | Choose DIY Hub-Spoke | Choose Azure Virtual WAN |
|---|---|---|
| **Org size / branch count** | Small–medium; <50 branches; single or few regions | Large enterprise; 50–1,000+ branches; multi-region |
| **Routing control requirement** | High — need arbitrary UDRs, custom NVA routing, BGP policy | Medium — willing to accept hub router's opinionated model |
| **SD-WAN integration** | Possible but manual (VPN device config + BGP) | ✅ 30+ certified zero-touch SD-WAN partners |
| **Multi-region any-to-any transit** | Complex — Global VNet peering + NVA tunnels | ✅ Automatic — hubs auto-meshed over Microsoft backbone |
| **Operational team skill** | Strong IaC / network engineering skills available | Willing to use Azure portal + APIs; less routing expertise required |
| **Existing hub VNets** | You already have hub VNets deployed at scale | Greenfield or willing to migrate (migration guide available) |
| **IPv6** | Required in hub gateways | ❌ Not supported in VWAN hub gateways — use DIY |
| **Spoke VNet owns gateway** | Required | ❌ Not allowed in VWAN spoke |
| **Custom NVA in DIY pattern** | Supported (deploy NVA VM + Route Server for BGP) | Supported for select vendors as hub-managed app only |
| **Routing inspection + Firewall** | Willing to manage UDRs manually or use AVNM | ✅ Routing Intent automates this completely |

---

## Migration path: DIY → Virtual WAN

Key constraints to resolve before migration:

| Constraint | Required action |
|---|---|
| Spoke VNets cannot have VPN Gateway or Route Server | Disconnect and delete before connecting spoke to VWAN hub |
| One VNet → one hub only | Resolve any dual-hub spoke designs |
| Hub address space is immutable | Plan hub CIDR carefully; minimum /24 general; /22 for Azure Firewall |
| ASNs must not conflict with Azure reserved ASNs | Verify NVA/on-prem ASNs don't use: 8074, 8075, 12076, 65515–65520 |
| ER ECMP not default in VWAN | Create a Route-map on ER connection to activate ER ECMP |

---

## Source pages

| Source | Notes |
|---|---|
| [Virtual WAN](../services/virtual-wan.md) | Capabilities, SKUs, hub router, Routing Intent, NVA-in-hub, SD-WAN, monitoring |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | DIY topology, UDR patterns, Route Server, AVNM, scaling limits, migration |