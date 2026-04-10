# Azure Route Server

> **Compiled:** 2026-04-10 | **Source articles:** 21 | **Status:** ✅ current

## What it is

**Azure Route Server** is a fully managed Azure service that enables dynamic routing between **network virtual appliances (NVAs)** and Azure virtual networks using **Border Gateway Protocol (BGP)**. It acts as a BGP route reflector within a VNet, automatically exchanging routes between NVAs and Azure's Software Defined Network (SDN) — eliminating manual route-table management. Route Server operates **exclusively in the control plane**: it does not route, inspect, or forward data traffic.

Key behavior:
- Establishes eBGP peering sessions with NVAs; learns routes from NVAs and programs them into the VNet SDN
- Propagates VNet prefixes back to NVAs (bidirectional)
- Exposes **two BGP peer IPs** (two internal instances) for high availability — every NVA must peer with both
- Zone-redundant in regions that support Availability Zones
- Does **not** store customer data; only exchanges BGP routes
- Branch-to-branch route exchange (NVA ↔ VPN/ER gateway) is **disabled by default** and must be explicitly enabled
- Fixed BGP timers: keepalive **60 s**, hold **180 s**

---

## Key capabilities

| Capability | Detail |
|---|---|
| BGP route exchange | Automatically programs NVA-learned routes into all VMs in the VNet and peered spoke VNets |
| Branch-to-branch | When enabled, mediates route exchange between NVAs, ExpressRoute gateways, and VPN gateways in the same VNet |
| Route injection into spokes | Spoke VNets peered with *Use Remote Route Server* receive dynamically injected routes — no manual UDRs needed |
| Routing preference | Configurable preference: **ExpressRoute** (default) > **VPN/NVA** > **AS Path** (standard BGP) |
| Next hop IP support | NVAs can advertise the frontend IP of an internal load balancer as the BGP next hop, enabling active/active or active/passive HA patterns |
| Anycast routing | Same prefix advertised from NVAs in multiple regions enables BGP-level anycast over ExpressRoute/VPN |
| Dual-homed networks | Route Server in a spoke can peer with NVAs in multiple hub VNets simultaneously |
| Multi-region routing | Route Server in each regional hub, with NVA-to-NVA tunnels (IPsec/VXLAN) and AS-override, enables cross-region dynamic routing |
| Autoscaling | Scales routing infrastructure units based on spoke VM utilization; minimum provisioned RIUs are never reduced |
| DDoS protection | Route Server's public IP can be protected by Azure DDoS Network Protection applied to its VNet |
| ECMP | When multiple NVAs advertise the same route with equal AS path length, Route Server programs all next hops and VMs use ECMP |
| NO_ADVERTISE community | Routes tagged with `NO_ADVERTISE` BGP community are not forwarded to other peers (e.g., suppresses ER advertisement) |

---

## SKUs / tiers

Azure Route Server has a single **Standard** SKU. Capacity is expressed in **Routing Infrastructure Units (RIUs)**.

| RIUs | Max supported VMs | Notes |
|---|---|---|
| 2 (default) | 4,000 [VERIFY] | Minimum; set at creation time as the floor for autoscaling |
| 3 | 5,000 [VERIFY] | Each additional RIU adds ~1,000 VM capacity |
| 8 | 10,000 [VERIFY] | — |
| 18 | 20,000 [VERIFY] | — |
| 28 | 30,000 [VERIFY] | — |
| 38 | 40,000 [VERIFY] | — |
| 48 (max) | 50,000 [VERIFY] | Hard maximum |

> Scale-out takes up to **25 minutes**. Route Server maintains existing capacity until scale-out completes.  
> Additional RIUs cost **$0.10/hour** per unit (US pricing) [VERIFY — regional pricing varies].  
> Pricing model: hourly deployment-based; no per-route or per-session charges [VERIFY].

---

## Architecture patterns

### 1. Hub-and-spoke with NVA route injection
Route Server lives in the hub VNet. NVAs in the hub BGP-peer with Route Server and advertise prefixes (e.g., on-premises, default route). Spoke VNets peered with *Use Remote Route Server* automatically receive injected routes — no UDRs required in spokes.

**Key config:** NVA must advertise a **supernet** (shorter prefix than VNet address space) to influence spoke-to-spoke traffic through the NVA; Route Server will not advertise routes equal to or longer than the VNet address space.

### 2. ExpressRoute + VPN coexistence
Route Server mediates route exchange between an ER gateway, a VPN gateway, and NVAs all in the same VNet. Enable *branch-to-branch* to allow these to share routes. ER routes take precedence over VPN/NVA routes by default (configurable via routing preference).

> ⚠️ ER circuit-to-circuit transit is **not supported** through Route Server. Use [ExpressRoute Global Reach](../services/expressroute.md) instead.

### 3. Dual-homed spoke
Route Server deployed in a **spoke** VNet peers with NVAs in **two or more hub** VNets. Provides active/active or active/passive spoke connectivity. When hubs also have ER gateways: deploy a Route Server in each hub too, enable branch-to-branch, and configure NVAs with **as-override** (both Route Servers share ASN 65515 — loop prevention requires overriding the ASN on NVA advertisements).

### 4. Multi-region hub-and-spoke
Each region has a hub VNet with Route Server + NVA. NVAs maintain IPsec/VXLAN tunnels between regions. NVAs must strip ASN **65515** from the AS path when re-advertising cross-region routes (AS override / AS-path rewrite) to prevent Route Server from dropping routes containing its own ASN.

**Alternative (not recommended):** UDR-based with BGP propagation disabled on NVA subnets — works but requires manual route maintenance.

### 5. Next hop IP (NVA behind ILB)
NVAs sit behind an internal load balancer. Each NVA's BGP config sets the ILB frontend IP as the BGP next hop (`next-hop-self` to ILB frontend IP). Route Server peers individually with each NVA but programs the ILB IP as next hop. Supports active/active (throughput) and active/passive (symmetric routing) configurations.

> Cross-region load balancer is **not supported** as next hop.

### 6. Anycast routing
Identical prefix (e.g., `a.b.c.d/32`) advertised by NVAs in multiple regions via Route Server → ER/VPN → on-premises. On-premises BGP selects closest region. NVAs must implement health checking and withdraw the advertisement when the local application fails (prevents blackholing).

### 7. SD-WAN + ExpressRoute + Azure Firewall
Spoke route tables disable gateway route propagation; use a static 0.0.0.0/0 UDR pointing to Azure Firewall. Azure Firewall subnet learns on-premises routes via Route Server. SD-WAN NVAs advertise with `no-advertise` community to suppress re-injection back to on-premises via ER.

---

## Configuration essentials

### Deployment requirements

| Requirement | Detail |
|---|---|
| Dedicated subnet | Must be named exactly **`RouteServerSubnet`**; minimum **/26** |
| Public IP | **Standard SKU** required (Standard v2 is NOT supported) |
| One per VNet | Only one Route Server allowed per virtual network |
| NVA location | Must be in the **same VNet** or a **directly peered VNet**; on-premises NVA peering is not supported |
| NVA BGP | Must support **multi-hop eBGP**; NVA ASN must differ from **65515** |
| NVA dual-peering | Each NVA instance must establish BGP sessions with **both** Route Server IP addresses |
| VPN gateway | Must be in **active-active mode** with ASN **65515** [VERIFY] |
| IPv6 | **Not supported**; deploying Route Server in a dual-stack VNet breaks IPv6 connectivity |
| ASN format | Only **16-bit (2-byte)** ASNs supported |

### Reserved ASNs (cannot be used for NVAs)

| Category | ASNs |
|---|---|
| Azure public | 8074, 8075, 12076 |
| Azure private | 65515, 65517, 65518, 65519, 65520 |
| IANA reserved | 23456, 64496–64511, 65535–65551 |

### Branch-to-branch (route exchange with gateways)

Disabled by default. When enabled:
- NVAs learn routes from ER/VPN gateways and vice versa
- ER + VPN gateways exchange routes with each other
- Azure VPN gateway will **NOT** advertise the default route (0.0.0.0/0) learned from Route Server to on-premises peers
- P2S VPN transit is **not supported** (S2S only)

### Routing preference options

| Setting | Behavior |
|---|---|
| **ExpressRoute** (default) | ER routes preferred over VPN/NVA routes |
| **VPN** | VPN gateway and NVA routes preferred over ER routes |
| **AS Path** | Standard BGP best-path selection; shorter AS path wins |

> When ExpressRoute recovers after a failure, traffic may not automatically revert to ER. Use AS path prepending on VPN/NVA routes to make them less preferred and test failover/failback scenarios.

### Deployment timing

| Event | Duration |
|---|---|
| Route Server initial creation | 30–60 minutes [VERIFY] |
| Adding/removing Route Server from VNet with existing gateways | ~10 min downtime on gateway connectivity |
| Capacity scale-out | Up to 25 minutes |

### RBAC

| Role | Scope |
|---|---|
| **Network Contributor** (built-in) | Sufficient for all Route Server operations |
| Custom role minimum | `Microsoft.Network/publicIPAddresses/join/action` + `Microsoft.Network/virtualNetworks/subnets/join/action` on `virtualHubs/ipConfigurations` |

---

## Monitoring and troubleshooting

### Azure Monitor metrics

Use time granularity of **5 minutes or greater**. Classic metrics are deprecated — use Azure Monitor only.

| Metric | Unit | Aggregation | Description | Exportable |
|---|---|---|---|---|
| BGP Peer Status | Count | Maximum | 1 = session up, 0 = session down | Yes |
| Count of Routes Advertised to Peer | Count | Maximum | Routes sent from Route Server to NVA | Yes |
| Count of Routes Learned from Peer | Count | Maximum | Routes received from NVA | Yes |
| Routing Infrastructure Units | Count | Maximum | Current RIU capacity | No |
| Spoke VM Utilization | Percent | Maximum | Deployed VMs as % of RIU capacity | No |

> ⚠️ The metric **"Data Processed by the Virtual Hub Router"** appears in Route Server monitoring but does **not** apply to Route Server — ignore it.

Use **Apply Splitting → BgpPeerIp** dimension to isolate per-NVA route counts and BGP status.

### Recommended alerts

| Alert | Condition |
|---|---|
| BGP session down | BGP Peer Status (max) = 0 |
| Route count anomaly | Routes Learned from Peer deviates significantly from baseline |
| Capacity pressure | Spoke VM Utilization approaching 100% |

### Diagnostic commands (PowerShell)

