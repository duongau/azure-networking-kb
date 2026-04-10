# Hybrid Connectivity

> **Compiled:** 2025-07-14 | **Type:** Concept | **Status:** ✅ current

Hybrid connectivity covers how on-premises networks, branch offices, and remote users establish
private or encrypted paths to Azure virtual networks and Microsoft cloud services. Three managed
services dominate this space: **VPN Gateway** (IPsec over internet), **ExpressRoute** (private
dedicated circuits), and **Virtual WAN** (managed global hub-and-spoke). **Azure Route Server**
is the BGP glue that binds NVAs into this picture.

---

## Connectivity options at a glance

| Option | SLA | Max bandwidth | Latency | Encryption | Setup time | Typical cost tier |
|---|---|---|---|---|---|---|
| **VPN Gateway S2S** | 99.9% [VERIFY] | ~10 Gbps (VpnGw5AZ) [VERIFY] | Variable — crosses public internet | ✅ IPsec/IKE always on | Hours (gateway) + VPN device config | $ |
| **ExpressRoute (provider circuit)** | 99.95% [VERIFY] | 50 Mbps – 10 Gbps | Low, consistent, no internet jitter | ❌ Not encrypted by default | Weeks (provider provisioning) | $$$ |
| **ExpressRoute Direct** | 99.95% [VERIFY] | 10 / 100 / 400 Gbps | Lowest — direct into Microsoft network | ❌ MACsec optional (Direct only) | Weeks–months | $$$$ |
| **Virtual WAN (S2S VPN)** | 99.95% [VERIFY] | 20 Gbps per hub [VERIFY] | Variable — crosses public internet | ✅ IPsec/IKE always on | Hours–days; SD-WAN partner automation | $$ |
| **Virtual WAN (ExpressRoute)** | 99.95% [VERIFY] | 20 Gbps per hub (10 scale units) [VERIFY] | Low, consistent | ❌ Not encrypted by default | Weeks | $$$ |
| **Point-to-Site VPN (standalone)** | 99.9% [VERIFY] | Aggregate per SKU [VERIFY]; VpnGw1: 128 SSTP + 250 IKEv2 | Variable — crosses public internet | ✅ TLS (OpenVPN/SSTP) or IKEv2 | Minutes per client | $ |
| **Virtual WAN P2S** | 99.95% [VERIFY] | Up to 100 Gbps / 100,000 users (200 scale units) [VERIFY] | Variable — crosses public internet | ✅ TLS or IKEv2 | Minutes per client | $$ |

> All SLA, throughput, and pricing figures are **[VERIFY]** — check current Azure documentation and pricing pages before architectural commitments.

---

## BGP: the glue

BGP is the dynamic routing protocol that makes hybrid connectivity production-grade. Without BGP,
every prefix change requires manual UDR updates. With BGP, Azure and on-premises devices exchange
reachability automatically.

### Route exchange between on-premises and Azure

- Azure VPN Gateway, ExpressRoute gateways, and Virtual WAN hubs all use BGP as the control plane
- Azure uses ASN **65515** for VPN Gateway (default) and Route Server; Microsoft uses **AS 12076** for ExpressRoute
- On-premises routers exchange prefixes bidirectionally: Azure VNet prefixes flow to on-prem; on-prem prefixes flow into Azure routing tables
- **BGP hold time** for ExpressRoute is **180 seconds** (keepalive every 60 s) — fixed by Microsoft, cannot be changed on the Microsoft side

### AS path and route filtering

- **AS path prepending** is the standard tool for traffic engineering: prepend your ASN multiple times on a path to make it less preferred, forcing traffic to the shorter-path alternative
- **Route filters** are mandatory on ExpressRoute Microsoft peering circuits created after August 1, 2017 — zero prefixes are advertised until a route filter is attached and service communities are selected
- **Prefix limits matter:** ExpressRoute private peering limits are 4,000 IPv4 prefixes (Standard/Local) and 10,000 IPv4 prefixes (Premium); advertising beyond these limits drops the BGP session

### BGP communities for ExpressRoute

ExpressRoute uses BGP communities to indicate route scope. This matters for Local vs. Standard vs. Premium circuit decisions:

| Community type | Meaning | Circuit SKU that honors it |
|---|---|---|
| **Local** community | Prefixes within 1–2 Azure regions near the peering location | Local SKU routes only; no global reach |
| **Regional** (geopolitical) | Prefixes within a geopolitical boundary (e.g., all of North America) | Standard SKU |
| **Global** | All Azure regions worldwide | Premium SKU required |
| **Microsoft service** communities | M365, Azure PaaS grouped by service | Microsoft peering; require route filter selection |

### Route Server for NVA-to-Azure BGP

When a third-party NVA (firewall, SD-WAN CPE, route reflector) needs to participate in Azure routing without manual UDRs, **Azure Route Server** acts as a BGP route reflector inside the VNet:

- NVAs establish eBGP sessions with Route Server's two peer IPs (both required for HA)
- Route Server programs NVA-advertised routes into the VNet SDN — no UDRs needed in spoke VNets using *Use Remote Route Server*
- **Branch-to-branch** (disabled by default): when enabled, Route Server mediates route exchange between NVAs, VPN gateways, and ExpressRoute gateways in the same VNet
- Route Server is **control plane only** — it does not forward data traffic
- Default routing preference (configurable): **ExpressRoute > VPN/NVA > AS Path**

---

## ExpressRoute deep concepts

### Circuit → Peering → Connection model

```
On-premises ──── Provider / Direct ──── ExpressRoute Circuit
                                              │
                                   ┌──────────┴──────────┐
                              Private Peering       Microsoft Peering
                              (Azure VNets)         (M365, Azure PaaS)
                                    │
                             ER VNet Gateway
                                    │
                               Azure VNet
```

- **Circuit**: The logical object representing the physical cross-connect leased from a provider (or ExpressRoute Direct port). Has a bandwidth SKU and a circuit SKU (Local/Standard/Premium).
- **Peering**: The BGP configuration on the circuit — either Private Peering (RFC 1918 private IPs, VNet-bound) or Microsoft Peering (public IPs, Microsoft cloud services). Public peering is deprecated.
- **Connection**: Links the circuit's private peering to a specific ExpressRoute Virtual Network Gateway in a VNet.

### Private peering vs. Microsoft peering

| Attribute | Private peering | Microsoft peering |
|---|---|---|
| Traffic destination | Azure VMs, internal load balancers, private endpoints | Azure PaaS (Storage, SQL), Microsoft 365 |
| IP addressing | Private IPs from your own space | Public IPs registered in RIR/IRR to your ASN |
| NAT required | ❌ No | ✅ Yes — SNAT to registered public IPs |
| Route filter required | ❌ No | ✅ Yes (circuits after Aug 1, 2017) |
| Default route accepted | ✅ Yes (but hijacks Microsoft peering traffic — see Gotchas) | ❌ No |
| RFC 1918 prefixes to Microsoft | ✅ Accepted | ❌ Must filter before advertising |
| QoS (DSCP) | Preserved but not acted on | Preserved and honored by Microsoft |

### ExpressRoute Global Reach

Global Reach links **two ExpressRoute circuits** privately so on-premises sites can communicate with each other across the Microsoft backbone — without traffic touching the public internet or traversing a customer-managed transit VNet.

- Requires **Premium** SKU when circuits span geopolitical boundaries; Standard within same geopolitical area [VERIFY]
- ER circuit-to-circuit transit through **Route Server is not supported** — Global Reach is the correct path
- Useful pattern: two datacenters connected to Azure via separate ER circuits can route between each other at ER bandwidth without building a dedicated WAN link

### FastPath: bypass the gateway for throughput

By default, on-premises→VM traffic routes through the ExpressRoute VNet gateway, adding a hop and limiting throughput. **FastPath** removes the gateway from the data path for qualifying traffic:

- **Requires:** Ultra Performance, ErGw3Az, or ErGwScale (≥10 scale units) gateway SKU
- The gateway still handles **control plane** (BGP); FastPath is data plane only
- **FastPath does NOT work for:** spoke VNet ILBs/PaaS, Azure Firewall in spoke VNets, DNS Private Resolver in spoke VNets, Azure NetApp Files (without Standard network features), global VNet peering

| FastPath capability | ExpressRoute Direct | Provider circuit (≤10 Gbps) |
|---|---|---|
| FastPath to hub VNet (IPv4) | ✅ | ✅ |
| FastPath to hub VNet (IPv6) | ✅ | ❌ |
| VNet peering over FastPath | ✅ | ❌ |
| UDR over FastPath | ✅ | ❌ |
| Private Link (limited GA) | ✅ (enrollment required) | ❌ |

**FastPath IP limits (data plane)** — excess traffic falls back through gateway silently:

| Circuit type | FastPath IP limit |
|---|---|
| Direct 100 Gbps / 400 Gbps | 200,000 IPs [VERIFY] |
| Direct 10 Gbps | 100,000 IPs [VERIFY] |
| Provider circuits ≤10 Gbps | 25,000 IPs [VERIFY] |

### Bidirectional Forwarding Detection (BFD)

BFD is a lightweight protocol that enables sub-second failure detection on ExpressRoute private peering:

- Without BFD: failure detection relies on BGP hold timer — **~3 minutes** before path is declared down
- With BFD enabled: failure detection **<1 second**
- BFD must be configured on both the customer edge (CE) router and is supported by Microsoft on all MSEE routers
- Critical for ER+VPN coexistence patterns where fast ER failure detection triggers VPN failover

### Circuit SKUs: Local, Standard, Premium

| SKU | Geographic scope | Billing model | VNets per circuit | Notable restrictions |
|---|---|---|---|---|
| **Local** | 1–2 Azure regions near the peering location | Port charge includes data transfer (no separate egress) [VERIFY] | Same as Standard [VERIFY] | No Global Reach; regions restricted to local area only |
| **Standard** | All Azure regions in same geopolitical area | Metered or Unlimited | Up to 10 [VERIFY] | — |
| **Premium** | All Azure regions globally (excl. national clouds) | Metered or Unlimited | Up to 100 [VERIFY] | Required for M365; required for Global Reach across geopolitical boundaries |

**SKU change rules:**
- Standard → Premium: ✅ allowed
- Local → Standard/Premium: ✅ allowed (PowerShell/CLI only; billing must be Unlimited)
- MeteredData → UnlimitedData: ✅ allowed
- **UnlimitedData → MeteredData: ❌ NOT allowed** — irreversible billing change
- Premium → Standard: ✅ allowed if utilization is within Standard limits

### Connectivity models (Layer 2 vs. Layer 3 handoff)

| Model | Layer | Description |
|---|---|---|
| CloudExchange Colocation | L2 or L3 | Virtual cross-connection through colocation provider's Ethernet exchange |
| Point-to-point Ethernet | L2 | Dedicated Ethernet link from on-premises DC to Microsoft |
| Any-to-any (IPVPN/MPLS) | L3 | Microsoft appears as another branch on your MPLS WAN fabric |
| ExpressRoute Direct | L1 | Direct fiber connection into Microsoft global network; no service provider intermediary |

---

## VPN Gateway deep concepts

### IKEv1 vs. IKEv2

| Attribute | IKEv1 | IKEv2 |
|---|---|---|
| Support | All SKUs except Basic | All SKUs except Basic |
| Stability | May experience reconnects during Main Mode rekeys | More stable; recommended for new deployments |
| P2S support | ❌ Not available for P2S | ✅ Supported for P2S (Windows, macOS, iOS) |
| Recommendation | Legacy device compatibility only | Prefer for all new S2S |

### Active-active vs. active-passive

| Mode | Azure instances | Failover behavior | Requirement |
|---|---|---|---|
| **Active-passive** (default) | 2 VMs; only 1 forwards traffic | Planned: 10–15 sec; Unplanned: 1–3 min | 1 public IP |
| **Active-active** | Both VMs forward simultaneously | Near-zero interruption (in-flight flows may reset) | Route-based VPN + 2× Standard SKU static public IPs |

Active-active requires BGP to function correctly — each gateway instance has its own BGP peer IP, and the on-premises device builds a tunnel to each instance.

### VPN Gateway SKUs

| SKU | Zone redundant | Notes |
|---|---|---|
| **Basic** | ❌ | Dev/test only — no RADIUS, no IKEv2 P2S, no IPv6, no active-active, 10 tunnels max (route-based) |
| **VpnGw1AZ** | ✅ | Entry production; 128 SSTP + 250 IKEv2 P2S connections |
| **VpnGw2AZ** | ✅ | Minimum for NAT (overlapping address spaces) |
| **VpnGw3AZ** | ✅ | Higher throughput |
| **VpnGw4AZ** | ✅ | Large enterprise; up to 100 S2S tunnels [VERIFY] |
| **VpnGw5AZ** | ✅ | Maximum performance; up to 100 S2S tunnels [VERIFY] |

> ⚠️ Non-AZ SKUs (VpnGw1–5 without AZ) are **blocked for new creation** from November 1, 2025 and retire September 16, 2026. Use AZ variants for all new deployments.
> Legacy Standard/High Performance SKUs retire **March 31, 2026**.

Exact per-SKU aggregate throughput (Mbps/Gbps) and full P2S connection counts are in include files not fully captured here — **[VERIFY]** against [About gateway SKUs](../../raw/articles/vpn-gateway/about-gateway-skus.md).

### BGP over VPN

- Optional on route-based gateways; enables dynamic prefix updates and multi-tunnel failover
- Azure VPN Gateway default ASN: **65515** [VERIFY]
- APIPA addresses (169.254.x.x) supported as BGP peer IPs on active-active gateways (GA Jan 2022)
- APIPA is **not supported** with NAT rules on the same gateway
- Required for: multiple on-premises VPN devices in HA, dual-redundancy (4-tunnel full mesh), transit routing

### Point-to-site: protocol and client support matrix

| Protocol | Auth options | OS clients | Notes |
|---|---|---|---|
| **OpenVPN (TLS 1.2/1.3)** | Certificate, Entra ID, RADIUS | Windows, macOS, Linux, iOS, Android | Most flexible; Entra ID requires Azure VPN Client |
| **SSTP** | Certificate, RADIUS | **Windows only** | Traverses most firewalls (TCP 443) |
| **IKEv2** | Certificate, RADIUS | Windows, macOS, iOS | Native OS VPN client; no additional client install needed |

P2S connection limits (VpnGw1): **128 SSTP** and **250 IKEv2** connections (limits are independent per protocol). Higher SKUs support more — **[VERIFY]** full table in SKU documentation.

### NAT rules for overlapping address spaces

When two on-premises sites (or on-premises + VNet) have identical RFC 1918 ranges, VPN Gateway NAT rules resolve the conflict:

- Supported SKUs: **VpnGw2–5 / VpnGw2AZ–5AZ** only
- S2S cross-premises connections only — not VNet-to-VNet, not P2S
- **Static NAT**: fixed 1:1 prefix mapping (both sides same size); bidirectional
- **Dynamic NAT (NAPT)**: port-based; unidirectional (initiated from internal side only)
- BGP peer IPs must **not** be inside a dynamic NAT pre-NAT range (create a separate static rule for the BGP peering address)
- Enable **BGP Route Translation** to auto-advertise post-NAT ranges via BGP

---

## Coexistence: ExpressRoute + VPN Gateway

It is valid and common to deploy **both** an ExpressRoute gateway and a VPN gateway in the same VNet. This is the canonical pattern for production hybrid connectivity with redundancy.

### How coexistence is configured

- The `GatewaySubnet` hosts both gateway resource types (gateway type `ExpressRoute` + gateway type `Vpn`)
- GatewaySubnet must be **/27 or larger** for standalone; plan **/26 or larger** when both gateways coexist (more IPs consumed)
- Both gateways share the subnet but are independent resources with their own public IPs
- BGP is required on the VPN gateway for coexistence to work correctly for failover routing
- Route Server with *branch-to-branch* enabled can mediate route exchange between the two gateways and NVAs

### Failover behavior

| Scenario | Without BFD | With BFD |
|---|---|---|
| ER link failure detection | ~3 minutes (BGP hold timer: 180 s) | **<1 second** |
| VPN takes over after ER failure | After ER BGP session drops + BGP reconvergence | Near-immediate after BFD detects link down |
| ER recovery — traffic revert to ER | **May not revert automatically** | **May not revert automatically** |

> **Critical:** When ER recovers, traffic does not necessarily switch back. Route Server defaults to preferring ER, but the control-plane reconvergence takes time. Use **AS path prepending on VPN routes** (make them less preferred when ER is healthy) and **test failback** explicitly — do not assume it works.

### Cost implications

- You pay the hourly compute rate for **both gateways simultaneously** — ER gateway + VPN gateway charges stack
- Data egress charges apply on the VPN path (internet rates)
- ER data charges depend on circuit billing model (Unlimited = flat; Metered = per-GB)
- Active-active on the VPN gateway adds one extra Standard SKU public IP charge

---

## Virtual WAN for branch-heavy deployments

### When Virtual WAN beats hub-spoke + VPN Gateway

| Criterion | Custom hub-spoke + VPN Gateway | Virtual WAN |
|---|---|---|
| Branch count | ≤100 S2S tunnels per gateway | 1,000 connections (2,000 tunnels) per hub |
| Operations overhead | Customer manages routing, UDRs, peerings | Microsoft manages hub, routing, gateway scaling |
| SD-WAN partner integration | Manual; customer builds | 30+ certified partners with zero-touch provisioning |
| Multi-region transit | Customer manages inter-region NVA tunnels | Automatic hub-to-hub full mesh on Microsoft backbone |
| P2S at scale | Single gateway; limited P2S user count per SKU | Up to 100,000 users per hub (200 scale units) [VERIFY] |
| ER + VPN + P2S in same hub | Requires separate gateways per VNet | Single hub supports all three simultaneously |

### SD-WAN partner integrations

Virtual WAN supports 30+ certified SD-WAN and NGFW partners including Barracuda CloudGen WAN, Check Point, Cisco Catalyst SD-WAN, Fortinet FortiGate, Palo Alto Networks, VMware SD-WAN (Velocloud), Versa Networks, and others. Partners expose Azure APIs so branch device configuration (tunnel endpoints, IKE keys, BGP ASNs) is automatically provisioned — no manual template editing.

Each partner NVA in the hub runs in `n+1` provisioned instances; 1 NVA Infrastructure Unit ≈ 500 Mbps throughput.

### Routing Intent: what it does and when to use it

**Routing Intent** is a Virtual WAN hub-level policy that forces **all internet-bound or all private traffic** through a designated next-hop security appliance (Azure Firewall, supported NVA, or SaaS security) in the hub.

| Routing policy | Effect |
|---|---|
| **Internet Traffic Routing Policy** | All internet-bound traffic (0.0.0.0/0) from all branches and spoke VNets routes through the hub firewall |
| **Private Traffic Routing Policy** | All branch-to-VNet, VNet-to-VNet, and inter-hub private traffic routes through the hub firewall |

**When to use it:**
- You need centralized inspection of east-west (branch-to-VNet, VNet-to-VNet) traffic without building UDR-heavy custom route tables in every spoke
- You need consistent internet egress control across all branches and VNets in a region
- You have a Secure Virtual Hub (Azure Firewall or NVA deployed inside the hub)

**Key constraints:**
- Hub address space must be **/22 or larger** when Azure Firewall is deployed in the hub
- Azure Firewall AZ configuration is **set at creation** — cannot be modified on existing Firewall; delete and redeploy to change
- Default route (0.0.0.0/0) does **not** propagate across hub-to-hub links — each hub must independently have a security appliance and Routing Intent enabled
- Maximum 600 directly-connected VNet address spaces per Routing Intent hub

---

## Common patterns

### Pattern 1: Simple S2S VPN to a single VNet

**Use when:** Small/medium workloads; cost-sensitive; ER provisioning time is not acceptable; bandwidth <1 Gbps.

```
On-premises VPN device
   │  (IPsec/IKE over internet)
   ▼
VPN Gateway (GatewaySubnet /27+)
   └── Azure VNet (workload subnets)
```

- Local Network Gateway object represents on-premises device (public IP + address prefixes or BGP ASN)
- Enable BGP for dynamic route updates and active-active for zero-interruption failover
- Active-active requires two public IPs on the gateway and BGP on both ends

### Pattern 2: Hub-spoke with centralized VPN/ER Gateway

**Use when:** Multiple spoke VNets; want to centralize ingress inspection; need gateway transit routing.

```
On-premises
   │
   ├── (ER or VPN) ──► Hub VNet (GatewaySubnet + AzureFirewallSubnet)
   │                       │         │         │
   │                 Spoke VNet A  Spoke VNet B  Spoke VNet C
   │                 (peered, Use Remote Gateway)
```

- Hub VNet hosts both the VPN/ER gateway and Azure Firewall
- Spoke VNets use "Use Remote Gateways" peering option to route hybrid traffic through hub gateway
- UDRs on GatewaySubnet and spoke subnets force traffic through Azure Firewall for inspection
- Route Server in hub can replace UDRs when NVAs advertise routes dynamically

### Pattern 3: ExpressRoute + VPN Gateway failover coexistence

**Use when:** Production workloads requiring maximum resiliency; ER is primary path; VPN is encrypted warm standby.

```
On-premises ──────── ER Circuit ──────► ER Gateway ┐
     │                                              ├── GatewaySubnet ── Azure VNet
     └─────── IPsec over internet ──► VPN Gateway ┘
```

- Both gateways in same GatewaySubnet (/26+ recommended)
- BGP with AS path prepending: VPN routes have longer AS path → ER preferred when healthy
- BFD on ER private peering: <1s failure detection triggers BGP reconvergence to VPN path
- Test failback explicitly — ER recovery does not auto-revert traffic without BGP policy
- Cost: both gateway hourly rates stack continuously

### Pattern 4: Virtual WAN for 50+ branches

**Use when:** Many branches (>20–50), SD-WAN infrastructure, global multi-region, want Microsoft-managed transit.

```
Branch 1 (SD-WAN CPE) ──┐
Branch 2 (IPsec VPN)  ──┤
Branch N               ──┤──► Virtual Hub (Region A) ──── Spoke VNets
Remote users (P2S)    ──┤         │
ER Circuit            ──┘    Hub-to-hub mesh
                              │
                         Virtual Hub (Region B) ──── Spoke VNets
```

- SD-WAN partner zero-touch provisioning automates branch device and Azure config
- Hub-to-hub transit is automatic on Microsoft backbone (Standard SKU)
- Routing Intent + Azure Firewall in hub for centralized traffic inspection
- Hub routing preference controls ER vs. VPN path selection per hub

### Pattern 5: Remote access P2S + Azure Bastion together

**Use when:** Remote workers need application-level VPN access AND IT staff need VM-level console access; defense in depth.

```
Remote user ──── P2S (OpenVPN/IKEv2) ──► VPN Gateway ──── Azure VNet
                                                               │
IT admin ──────── HTTPS ──────────────► Azure Bastion ────── VMs
```

- P2S provides network-layer access to Azure workloads over the VPN; user authenticates with Entra ID + Conditional Access (OpenVPN only) or certificates
- Azure Bastion provides **browser-based RDP/SSH** to VMs without exposing public IPs — no VPN client needed for console access
- The two complement each other: P2S for application connectivity; Bastion for operational VM management
- P2S client pool size: plan carefully — VpnGw1 handles 128 SSTP + 250 IKEv2; scale up SKU or use Virtual WAN P2S for larger workforces

---

## Gotchas

### 1. GatewaySubnet naming and sizing

The subnet hosting VPN and/or ExpressRoute gateways **must be named exactly `GatewaySubnet`** — Azure rejects deployment otherwise. Size requirements:

| Scenario | Minimum size | Recommended |
|---|---|---|
| Basic SKU only | /29 | /27 |
| Any non-Basic VPN gateway | /27 | /26 |
| ER + VPN coexistence | /27 | **/26 or larger** |

No other resources (VMs, NVAs, other subnets) may be placed in GatewaySubnet.

### 2. BGP ASN conflicts

Azure reserves ASNs that cannot be used by customer VPN devices or NVAs:

| Category | Reserved ASNs |
|---|---|
| Azure public | 8074, 8075, 12076 |
| Azure private (Route Server / VPN GW) | 65515, 65517, 65518, 65519, 65520 |
| IANA reserved | 23456, 64496–64511, 65535–65551 |

Also: Route Server only supports **16-bit (2-byte) ASNs** — 4-byte ASNs are not supported for peered NVAs.

Common mistake: assigning ASN 65515 to an on-premises BGP router. BGP loop prevention will drop all routes Azure advertises back from that ASN.

### 3. ExpressRoute peering location ≠ Azure region

An ExpressRoute **peering location** (e.g., "Chicago" Equinix) is a physical Exchange Point, **not** an Azure region (e.g., East US). You connect to a peering location based on where your on-premises network or colocation facility is located — not based on which Azure region you want to reach. From that peering location, your circuit's SKU (Local/Standard/Premium) determines which Azure regions are reachable.

Common mistake: assuming the "nearest" peering location corresponds to the nearest Azure region with minimal latency. Some peering locations are far from the region's actual datacenter. **Validate latency before committing to a circuit.**

### 4. BFD required for sub-second ER failover

Without BFD configured on the customer CE router, ExpressRoute failure detection depends on the BGP hold timer: **180 seconds** — three minutes of connectivity loss before the VPN failover path is taken. This is frequently acceptable only on paper; production teams are surprised by three-minute outages.

BFD must be configured on the **customer CE router** side. Microsoft MSEEs support BFD on all ER private peering sessions. If the CE device does not support BFD, the 3-minute timer applies.

### 5. P2S client pool size limits

P2S connections are bounded by both the gateway SKU and by the address pool size assigned to clients:

- VpnGw1: **128 SSTP connections** + **250 IKEv2 connections** (these limits are independent per protocol, not combined)
- Higher SKU limits are defined in include files — **[VERIFY]**
- Virtual WAN P2S: scales to 100,000 users (200 scale units) but requires multi-CIDR pool planning at scale ≥40 scale units
- P2S client pool is **split across gateway instances** — each instance gets a sub-range; this is by design and causes each instance to advertise different routes to clients (normal behavior, not a bug)

### 6. ExpressRoute does NOT encrypt traffic by default

This surprises teams coming from VPN. ER is a **private** path (no public internet), but it is **not encrypted**. Compliance regimes requiring encryption in transit must add:
- **IPsec over ER private peering** (using VPN Gateway, adds encryption overhead and complexity)
- **MACsec** — Layer 2 encryption available on **ExpressRoute Direct only** (not provider circuits); BYOK from Azure Key Vault

**Critical MACsec behavior:** If MACsec is enabled and a key mismatch occurs, connectivity is **completely lost** — traffic does NOT fall back to unencrypted. Roll key changes one link at a time during a maintenance window.

### 7. Default route (0.0.0.0/0) over ER private peering hijacks Microsoft peering traffic

If you advertise 0.0.0.0/0 over ExpressRoute private peering (e.g., to force internet traffic back on-premises), that default route is also applied to traffic destined for Microsoft peering services (Azure Storage, Azure SQL, etc.). This forces Microsoft service traffic on-premises too — often unintended. **Fix:** Add service endpoints to VNets for the relevant Azure services to keep that traffic on the Azure backbone regardless of the default route.

---

## Related pages

- [VPN Gateway](../services/vpn-gateway.md) — full service wiki: SKUs, BGP, P2S, NAT, active-active, coexistence
- [ExpressRoute](../services/expressroute.md) — full service wiki: circuit model, FastPath, Global Reach, MACsec, limits
- [Virtual WAN](../services/virtual-wan.md) — full service wiki: hub routing, Routing Intent, SD-WAN partners, limits
- [Route Server](../services/route-server.md) — BGP route reflector for NVA integration; branch-to-branch; routing preference

---

## Source articles

| Article | Type |
|---|---|
| [What is hybrid connectivity?](../../raw/articles/networking/hybrid-connectivity/hybrid-connectivity.md) | Raw — overview article |
| [VPN Gateway wiki](../services/vpn-gateway.md) | Compiled wiki — 107 source articles |
| [ExpressRoute wiki](../services/expressroute.md) | Compiled wiki — 13 source articles |
| [Virtual WAN wiki](../services/virtual-wan.md) | Compiled wiki — 133 source articles |
| [Route Server wiki](../services/route-server.md) | Compiled wiki — 21 source articles |