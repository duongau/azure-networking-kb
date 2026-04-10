# Hub-Spoke Networking

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

## What it is

Hub-spoke is the dominant multi-VNet topology in Azure. A single **hub virtual network** holds shared services — connectivity gateways, a centralized firewall or NVA, DNS infrastructure, and management tooling. Multiple **spoke virtual networks**, each containing a distinct workload, connect to the hub via VNet peering. Traffic that must cross workload boundaries — between spokes, to on-premises, or to the internet — is funneled through the hub, where it can be inspected and logged in one place.

Three properties define why the pattern exists: **(1) transit routing** — peering is non-transitive, so the hub is the only path between spokes without adding spoke-to-spoke peerings; **(2) centralized security** — one firewall instance enforces policy for all workloads rather than duplicating it per VNet; **(3) cost sharing** — expensive resources (VPN/ExpressRoute gateways, Azure Bastion, DNS resolvers) are deployed once in the hub and reused by every spoke via gateway transit and peering, eliminating per-spoke duplication.

---

## Hub-spoke vs alternatives

| Topology | Routing complexity | Scale ceiling | Managed by | Cost model | Best for |
|---|---|---|---|---|---|
| **Hub-spoke (DIY)** | Medium — UDRs required for spoke-to-spoke and egress; BGP propagation must be disabled on spoke route tables | 500 peerings/hub VNet (default); 1,000 with AVNM [VERIFY] | Customer | Peering charges per GB + Firewall/NVA + gateway hourly | Single- or multi-region enterprises needing full routing control and audit trail |
| **Azure Virtual WAN** | Low — hub router handles transitive routing automatically; no UDR management | 500 VNet connections/hub; up to 50,000 spoke VMs at max RIUs [VERIFY] | Microsoft | Hub hourly fee ($0.25/hr Standard [VERIFY]) + data processing fees + gateway scale units | Large branch estates, SD-WAN termination, multi-region, or when you want Microsoft to manage hub routing infrastructure |
| **Full-mesh VNet peering** | High — N×(N−1)/2 peerings; manual UDRs per pair; no central inspection point | Collapses operationally beyond ~10 VNets | Customer | N² peering charges (both directions per GB) | ≤5 VNets requiring direct, low-latency paths with no centralized security requirement |
| **Flat single VNet** | None — all resources in one address space and one routing domain | Limited to a single VNet's address space; no workload isolation | Customer | VNet itself is free; no peering costs | Smallest proof-of-concept workloads with no isolation or growth requirement |

> **Decision shortcut:** Start with hub-spoke. Migrate to Virtual WAN when you need multi-region transitive routing, SD-WAN branch termination at scale, or you have outgrown DIY hub management and want Microsoft to own the hub routing plane.

---

## Hub components

The hub VNet hosts shared services. None of these components are mandatory — compose the hub to match your requirements and budget. Components must be placed in specifically named and sized subnets.

| Component | Subnet name (exact — required by Azure) | Min subnet size | Role in hub |
|---|---|---|---|
| **Azure Firewall / NVA** | `AzureFirewallSubnet` | /26 | Centralized L3–L7 inspection; enforces N-S egress and E-W lateral traffic policies for all spokes |
| **Firewall Management NIC** (Basic SKU only) | `AzureFirewallManagementSubnet` | /26 | Separates Firewall control-plane traffic from customer data traffic; **required** for Azure Firewall Basic SKU |
| **VPN Gateway** | `GatewaySubnet` | /27 | IPsec/IKEv2 site-to-site tunnels to on-premises branches; enables gateway transit for spoke VNets |
| **ExpressRoute Gateway** | `GatewaySubnet` | /27 | Private dedicated fiber connectivity to on-premises; shares `GatewaySubnet` with VPN Gateway |
| **Azure Bastion** | `AzureBastionSubnet` | /26 | Browser-based RDP/SSH to VMs in any peered spoke; one Bastion instance serves all spokes — no public IPs on VMs required |
| **Azure Route Server** | `RouteServerSubnet` | /26 | BGP route exchange between NVAs and Azure SDN; eliminates manual UDR management when using third-party NVAs or SD-WAN appliances |
| **DNS Private Resolver** | Inbound endpoint subnet + outbound endpoint subnet | /28 each | Hybrid DNS resolution: on-premises clients can resolve Azure Private DNS zones; Azure workloads can resolve on-premises DNS names |
| **Shared services** | Custom subnets | Workload-sized | Active Directory / Entra Domain Services, monitoring agents, centralized private endpoints for PaaS shared services |

> 💡 **Reserve all hub subnets at VNet creation time — even if you don't deploy the service yet.** Adding an `AzureFirewallSubnet` later to an already-peered hub VNet requires no downtime, but failing to reserve the address range forces disruptive address-space surgery when the day comes.

### UDR requirement: forcing traffic through the hub firewall

A default route alone (`0.0.0.0/0` → Firewall private IP) is **not sufficient** to route all spoke traffic through the firewall. Azure uses longest-prefix-match routing: peering-learned routes for specific spoke prefixes (e.g., `10.2.0.0/16` for Spoke-B) are more specific than `/0` and take precedence over the default route, sending traffic directly to the peered VNet and **bypassing the firewall entirely**.

To enforce hub inspection for all traffic flows, add **explicit UDR entries for every other spoke's prefix** pointing to the Firewall private IP on every spoke's subnets:

```
Spoke-A subnet route table:
  10.2.0.0/16 → Azure Firewall private IP   ← covers Spoke-B
  10.3.0.0/16 → Azure Firewall private IP   ← covers Spoke-C
  0.0.0.0/0   → Azure Firewall private IP   ← covers internet egress

Spoke-B subnet route table:
  10.1.0.0/16 → Azure Firewall private IP   ← covers Spoke-A
  10.3.0.0/16 → Azure Firewall private IP   ← covers Spoke-C
  0.0.0.0/0   → Azure Firewall private IP   ← covers internet egress
```

Additionally, **disable BGP route propagation** on spoke subnet route tables. Without this, on-premises routes learned by the hub VPN/ExpressRoute gateway are injected directly into spoke effective routes — bypassing the firewall for hybrid traffic destined to on-premises.

---

## Spoke design

### VNet structure

Each spoke is an independent VNet scoped to a single workload team or environment. Standard subnet layout:

| Subnet | Purpose | Sizing guidance |
|---|---|---|
| **Ingress / frontend** | Application Gateway v2 + WAF, or public-facing load balancer | /24 minimum for App Gateway v2 (supports up to 125 autoscale instances; dedicated subnet required) |
| **Backend / workload** | VMs, AKS, App Service Environment VNet integration | Size for workload; create as **private subnet** (`defaultOutboundAccess = false`) — required behavior for new VNets post-March 31, 2026 [VERIFY] |
| **Data** | SQL MI, Cosmos DB, Redis Cache — private endpoints or subnet delegation | /28–/24 depending on service; may require subnet delegation |
| **Auxiliary** | Monitoring agents, jump VMs | Optional; share with backend if small |

### CIDR planning — do this before day one

| VNet | Example CIDR | Notes |
|---|---|---|
| Hub | `10.0.0.0/24` | Small; contains only shared services subnets |
| Spoke — workload 1 | `10.1.0.0/16` | Large enough for App Gateway /24 + multiple workload subnets |
| Spoke — workload 2 | `10.2.0.0/16` | Reserve this range now even if Spoke-2 doesn't exist yet |
| Spoke — workload N | `10.N.0.0/16` | Continue pattern; never reuse or overlap |

VNet peering fails immediately if any CIDR blocks overlap. **Plan the entire address space before deploying anything.** CIDR ranges cannot be changed on live peered VNets without re-deployment.

### Peering configuration

Peering is bidirectional — you must create a peering link on both the hub side and the spoke side. VNet peering is **non-transitive**: spokes peered to the same hub cannot communicate directly; all cross-spoke traffic must route through the hub.

| Setting | Hub → Spoke peering | Spoke → Hub peering |
|---|---|---|
| Allow virtual network access | ✅ Enabled | ✅ Enabled |
| Allow forwarded traffic | ✅ Enabled | ✅ Enabled (required for NVA/Firewall forwarding) |
| Allow gateway transit | ✅ Enabled (only if hub has a gateway) | ❌ Disabled |
| Use remote gateways | ❌ Disabled | ✅ Enabled (only if hub has a gateway) |

> ⚠️ **Peering is not free.** Data transferred across VNet peering links is charged per GB in both directions. In high-bandwidth hub-spoke environments — where all spoke egress routes through the hub — peering costs accumulate quickly. [VERIFY current peering pricing per region and per peering type (local vs. global)]

### Enabling spoke-to-spoke traffic via hub firewall

1. Add UDR entries on Spoke-A's subnets for each other spoke's CIDR → Firewall private IP.
2. Add matching entries on every other spoke for Spoke-A's CIDR → Firewall private IP.
3. Create Azure Firewall **network rules** (or application rules for HTTP/S) permitting the required cross-spoke flows.
4. Firewall logs every allowed and denied connection — this is the inspection and audit trail.

---

## Routing: the critical piece

### How Azure route selection works

Azure uses **longest-prefix-match** across all route sources in a subnet's effective route table. Priority when prefixes are the same length: UDR > BGP gateway routes > system routes. For different prefix lengths, the longer (more specific) prefix always wins regardless of source.

| Route source | Added by | Overridable? |
|---|---|---|
| System default routes | Azure automatically | Yes — UDR with same or shorter prefix |
| Peering-learned routes | VNet peering | Yes — UDR with same or longer prefix [VERIFY: confirm UDR precedence over peering] |
| BGP gateway routes | VPN/ExpressRoute gateway | Yes — UDR; or disable BGP propagation on route table |
| UDRs | Customer-defined | Only by a longer-prefix UDR |

### Enforcing hub inspection with UDRs

| Route entry | Next hop | Applied to | Effect |
|---|---|---|---|
| `0.0.0.0/0` | Azure Firewall private IP | All spoke subnets | Forces internet egress through Firewall |
| `10.X.0.0/16` (per spoke) | Azure Firewall private IP | All **other** spoke subnets | Forces E-W spoke-to-spoke through Firewall |
| `10.0.0.0/8` (RFC 1918 summary) | Azure Firewall private IP | Spoke subnets (alternative approach) | Covers all RFC 1918 ranges; simpler but only works if BGP propagation is **disabled** so peering routes don't override it |
| (BGP propagation disabled) | — | Spoke subnet route table setting | Prevents gateway-learned on-premises routes from injecting directly into spoke, bypassing Firewall |

### Dynamic routing with Azure Route Server

For NVA-based hub designs (SD-WAN, third-party NGFWs) that need dynamic route propagation instead of static UDRs:

1. Deploy Azure Route Server in hub (`RouteServerSubnet`, minimum /26, exact name required).
2. Configure eBGP sessions between the NVA and **both** Route Server peer IPs (two instances — both must receive advertisements for HA to work).
3. NVA advertises prefixes (on-premises routes, summary routes, default route) to Route Server.
4. Route Server programs NVA-learned routes into the hub VNet SDN and into peered spoke VNets configured with **Use Remote Route Server** on their peering.
5. No manual UDR updates needed when on-premises prefixes change.

**Critical NVA advertising rule:** To attract spoke-to-spoke traffic through the NVA, the NVA must advertise a **supernet** (shorter prefix than the spoke VNet address space) covering all spoke CIDRs. Route Server will not re-advertise a route that is equal to or longer than the VNet's own address prefix back into peered spokes.

> ⚠️ Route Server is **control-plane only** — it exchanges BGP routes but does not forward any data traffic. All data still flows through the NVA or Firewall.

### Routing approach comparison

| Approach | Mechanism | Operational overhead | Scale | Best for |
|---|---|---|---|---|
| **Static UDRs** | Manual route table entries per subnet | O(N²) — grows with every new spoke | Limited; error-prone at scale | Simple topologies; Azure Firewall only; ≤10 spokes |
| **BGP via Route Server** | NVA BGP-peers with Route Server; routes auto-programmed | Low — route changes propagate automatically | Good for dynamic prefix changes | NVA-heavy designs; dynamic on-premises prefix management |
| **AVNM Routing Configs** | AVNM manages and deploys route tables declaratively | Low — policy-driven; up to 1,000 UDRs/table [VERIFY] | High — centralized across subscriptions | Large fleets; enterprises managing hub-spoke at scale |
| **Virtual WAN hub router** | Microsoft-managed; fully automatic transitive routing | None from customer | Highest — 50,000 spoke VMs, 50 Gbps [VERIFY] | Microsoft-managed topology; multi-region; SD-WAN |

---

## Scaling: when hub-spoke breaks down

| Limit | DIY hub-spoke | With AVNM | Virtual WAN |
|---|---|---|---|
| Spoke VNets per hub | 500 peerings/VNet [VERIFY] | 1,000 spoke VNets per hub config [VERIFY] | 500 VNet connections/hub [VERIFY] |
| Route table entries | 400 UDRs/table [VERIFY] | 1,000 UDRs/table [VERIFY] | Managed by hub router |
| UDR maintenance burden | O(N²) entries for spoke-to-spoke | Policy-driven; automated | None |
| Transitive routing (spoke-to-spoke) | ❌ Manual UDRs + Firewall rules required | ❌ Peering non-transitive; optional direct connectivity via connected groups | ✅ Hub router handles automatically |
| Multi-region hub-to-hub transit | ❌ Manual — Global VNet peering + UDRs + NVA tunnels | Manual peering management | ✅ All Standard hubs auto-meshed over Microsoft backbone |
| Max routes per hub | No hub-level limit; limited per route table | 1,000 per table [VERIFY] | 10,000 routes total per hub [VERIFY] |

### The UDR sprawl problem

As spoke count grows, UDR management becomes the operational limiting factor — usually before the peering count limit is reached. Each new spoke added to an existing topology requires:

- 1 new VNet peering to hub
- 1 new UDR entry for the spoke's CIDR on **every existing spoke's** subnet route tables
- N−1 UDR entries on the new spoke's subnets (one per existing spoke)
- New Azure Firewall rules for each allowed cross-spoke flow

At ~30–50 spokes without automation, this creates hundreds of route table entries requiring coordinated updates every time a spoke is added, resized, or removed. Use Azure Virtual Network Manager routing configurations to automate at this scale.

### When to split into multiple hubs

| Trigger | Recommended action |
|---|---|
| Approaching 500 VNet peerings on hub VNet | Add a second hub; use Global VNet peering or a transit VNet to connect hubs |
| Single hub Firewall throughput is a bottleneck | Firewall Standard max ~30 Gbps [VERIFY]; add second hub or upgrade to Firewall Premium (~100 Gbps [VERIFY]) |
| Compliance requires full network isolation between BUs | Separate hubs per regulated environment; no cross-hub peering |
| Regional BCDR | Deploy a second hub in a DR region; mirror spoke peerings; use BGP/UDRs to prefer primary hub |

### Transition path to Virtual WAN

Microsoft provides a migration guide (`migrate-from-hub-spoke-topology.md` in raw articles). Pre-migration checklist:

| Constraint | Action required before migration |
|---|---|
| Spoke VNets cannot have a VPN Gateway or Route Server | Disconnect and delete gateways/Route Server from spoke VNets |
| One VNet can connect to only one Virtual WAN hub | Resolve any dual-hub spoke designs before migrating |
| Virtual WAN hub address space is immutable after creation | Plan hub CIDR carefully; minimum /24 general; /22 if deploying Azure Firewall |
| Existing BGP ASNs must not conflict with Azure reserved ASNs | Verify NVA and on-premises ASNs don't use 8074, 8075, 12076, or 65515–65520 |

---

## Managing at scale: Azure Virtual Network Manager

[Azure Virtual Network Manager (AVNM)](../services/virtual-network-manager.md) transforms hub-spoke management from imperative (manual IaC per peering) to declarative (define desired topology; AVNM converges to it and maintains it). It operates across subscriptions and tenants from a single control plane.

### What AVNM automates

| Task | Without AVNM | With AVNM |
|---|---|---|
| Create and maintain peerings | Manual per VNet pair; IaC required for scale | Hub-and-spoke connectivity configuration deployed to network groups |
| Add/remove spokes | Manual peering create/delete on both sides | Update network group membership; peerings update automatically |
| Spoke-to-spoke direct connectivity | Requires additional peering between every spoke pair | Optional per-spoke-group connected group (bypasses hub hop; no Firewall inspection) |
| Use hub gateway for all spokes | Manual `AllowGatewayTransit` + `UseRemoteGateways` per peering | `useHubGateway: true` in connectivity config; fails gracefully if no gateway exists |
| Prevent unauthorized peering changes | Not enforceable without Policy | `peeringEnforcement: Enforced` prevents deletion or modification outside AVNM |
| Org-wide security rules across all spokes | NSG per subnet, no org-level enforcement | Security admin rules evaluated **before** NSGs; Allow, Always Allow, Deny actions |
| Route table management | Manual; up to 400 UDRs/table [VERIFY] | Routing configurations; up to 1,000 UDRs/table [VERIFY]; Azure Firewall supported as next-hop |
| IP address management | Manual CIDR spreadsheets | IPAM with hierarchical pools (up to 7 layers deep); auto-allocates non-overlapping CIDRs |
| Dynamic spoke membership | Script-based VNet discovery | Azure Policy with `addToNetworkGroup` effect — VNets auto-join when policy conditions match |

### Key AVNM limits for hub-spoke

| Limit | Value |
|---|---|
| Spoke VNets per hub in connectivity config | 1,000 [VERIFY] |
| Connected group size (spoke-to-spoke direct) | 250 default (soft limit); 1,000 on request; 5,000 preview [VERIFY] |
| UDRs per AVNM-managed route table | 1,000 [VERIFY] |
| Time for connectivity config to take effect after deployment commit | ~15–20 minutes |
| Network group membership update — static/manual | Immediate |
| Network group membership update — policy-based (<1,000 subscriptions) | Minutes after policy evaluation |

> ⚠️ AVNM configurations **do not take effect until explicitly deployed** to one or more regions. Creating a connectivity configuration or security admin configuration has **zero runtime impact** until you commit a deployment. This is intentional — it prevents accidental topology changes during authoring.

---

## Secure hub-spoke pattern

Full reference architecture for a production-grade, inspection-enabled hub-spoke network:

```
Internet
   │  (HTTP/HTTPS)
   ▼
[Application Gateway WAF_v2]  ← in spoke, dedicated /24 subnet
   │  (Layer 7 inspection, WAF rules, TLS termination)
   ▼
[Workload backend: VMs / AKS / App Service]
   │  (spoke subnets: UDR 0.0.0.0/0 + per-spoke CIDRs → Firewall)
   │
   ▼ via UDR
[Hub VNet]
   ├── Azure Firewall (AzureFirewallSubnet /26)
   │       ├── App rules:     FQDN-based egress (*.microsoft.com, update endpoints)
   │       ├── Network rules: spoke-to-spoke, spoke-to-onprem allowed flows
   │       ├── DNAT rules:    optional inbound to spoke resources
   │       └── Threat Intel:  alert+deny on known malicious IPs/FQDNs
   │
   ├── VPN Gateway / ExpressRoute Gateway (GatewaySubnet /27)
   │       └── Gateway transit → spokes use this gateway for on-prem connectivity
   │
   ├── Azure Bastion (AzureBastionSubnet /26)
   │       └── Browser-based RDP/SSH to VMs in any peered spoke
   │
   ├── Azure Route Server (RouteServerSubnet /26)  [optional: NVA designs]
   │       └── BGP route injection from NVA into hub + spoke VNets
   │
   └── DNS Private Resolver / Custom DNS
           └── Hybrid name resolution for Private DNS zones ↔ on-premises
   │
   │  (VNet peering: AllowGatewayTransit on hub / UseRemoteGateways on spoke)
   ├──────────────────────────────────┐
   ▼                                  ▼
[Spoke VNet A — Workload 1]    [Spoke VNet B — Workload 2]
   UDR: 10.2.0.0/16 → Firewall    UDR: 10.1.0.0/16 → Firewall
   UDR: 0.0.0.0/0   → Firewall    UDR: 0.0.0.0/0   → Firewall
   BGP propagation: Disabled       BGP propagation: Disabled
   │
   │  (IPsec / ExpressRoute private peering)
   ▼
On-premises network
```

### Traffic inspection matrix

| Flow | Path | Where inspected |
|---|---|---|
| **N-S inbound** (internet → workload) | Internet → App Gateway WAF (spoke) → backend subnet | WAF (L7, OWASP CRS); NSG on workload subnet (L4) |
| **N-S outbound** (workload → internet) | Spoke subnet → UDR → Firewall → internet | Azure Firewall network + app rules; Threat Intelligence; optional TLS inspection (Premium) |
| **E-W** (spoke-to-spoke) | Spoke-A subnet → UDR → Firewall → Spoke-B | Azure Firewall network rules; Premium IDPS inline |
| **Hybrid outbound** (spoke → on-prem) | Spoke → UDR → Firewall → Hub gateway → on-prem | Azure Firewall network rules; BGP propagation disabled on spokes |
| **Hybrid inbound** (on-prem → spoke) | On-prem → Hub gateway → Hub → Firewall → Spoke (via DNAT or routing) | Azure Firewall DNAT + network rules |
| **Management** (admin → spoke VM) | Admin browser → Azure Bastion (hub) → peering → spoke VM NIC | Bastion NSG; no public IP exposure on VM; Entra ID auth + MFA optional |

### DDoS protection placement

Link the DDoS Protection plan to **both** hub and spoke VNets before creating any public IPs. DDoS infrastructure protection (free, always-on at Azure platform level) is not a substitute — it has higher mitigation thresholds than most workloads can absorb and provides no per-resource telemetry, alerting, rapid response support, or cost protection guarantees. [VERIFY: DDoS Network Protection covers up to 100 public IPs per plan; IP Protection is per-IP]

> ⚠️ Azure DDoS Protection plans cannot protect public IPs attached to NAT Gateway. If DDoS coverage for outbound IPs is required, use Azure Firewall (with DDoS-protected public IPs) for egress instead of NAT Gateway.

---

## Common gotchas

### 1. Spoke-to-spoke traffic is NOT automatic
VNet peering is non-transitive by design. Two spoke VNets connected to the same hub have **no direct path to each other** and cannot communicate without an explicit routing mechanism. First-time hub-spoke implementers reliably discover this when they deploy a second spoke and wonder why it cannot ping the first. Fix: add UDRs on each spoke for the other spoke's CIDR pointing to the hub Firewall, then create Firewall rules permitting the required flows.

### 2. `0.0.0.0/0` alone does not force spoke-to-spoke through the firewall
A UDR for `0.0.0.0/0` → Firewall handles internet-bound egress. It does NOT intercept spoke-to-spoke traffic. Any more-specific route in the effective route table — including peering-learned routes for other spoke prefixes (e.g., `10.2.0.0/16`) — takes precedence over `/0` via longest-prefix-match. You must add **explicit UDR entries for every other spoke's CIDR prefix** pointing to the Firewall private IP on every spoke's subnets. Alternatively, use a summary RFC 1918 route (`10.0.0.0/8` → Firewall) **combined with disabling BGP route propagation** on the spoke route table to prevent more-specific routes from overriding it.

### 3. VNet peering data transfer is not free
Peering traffic is billed per GB in both directions. In a hub-spoke design where all spoke egress (internet + spoke-to-spoke) is routed through the hub, every byte from every workload crosses at least one peering link — and is billed twice (once outbound from spoke, once inbound to hub). For data-intensive workloads this is a significant and often underestimated operating cost. [VERIFY current peering pricing; local vs. global peering rates differ]

### 4. Hub VNet address space must not overlap with anything, forever
The hub's CIDR must not conflict with any spoke VNet, any other hub, any on-premises network reachable via gateway, and any future VNet you might ever peer or connect. VNet peering fails immediately on address overlap, with no graceful fallback. Reserve hub address ranges from day one using a well-structured IP plan (e.g., `10.0.0.0/24` hub, `10.N.0.0/16` per spoke), and document reserved-but-not-yet-deployed spoke ranges so future teams don't inadvertently claim them.

### 5. Gateway transit requires correctly configured settings on both peering sides
Gateway transit is a two-sided, interdependent setting. The hub-side peering must have **Allow gateway transit** enabled; the spoke-side peering must have **Use remote gateways** enabled. If either side is misconfigured, spoke VNets silently fail to inherit on-premises routes — gateway BGP routes are simply not propagated to the spoke, causing blackholes for hybrid traffic. The error is not obvious in the portal. Additionally, if using AVNM with `useHubGateway: true`, the hub VNet must have a deployed gateway — AVNM peering creation from spoke to hub will fail if no gateway exists.

### 6. Address space exhaustion when scaling spoke count
Azure allows additional address prefixes to be added to an existing VNet — but you cannot shrink or remove CIDRs that are in use. Plan hub and spoke VNet CIDRs generously from the start. Specific sizing guidance from source articles:
- Simple hub (Bastion + optional Firewall Basic): `/24` is sufficient
- General hub (Firewall Standard/Premium + Gateway + Bastion): `/23` recommended
- Virtual WAN hub with Azure Firewall: `/22` minimum (immutable after creation)
- Per spoke: `/16` provides room for Application Gateway `/24`, workload subnets, and future expansion without re-addressing

### 7. BGP route propagation on spoke route tables must be disabled when Firewall handles routing
By default, spoke subnet route tables have BGP route propagation **enabled**. This means on-premises routes learned by the hub VPN/ExpressRoute gateway (e.g., `192.168.1.0/24` for an on-premises network) are automatically injected into spoke effective routes with a direct path — bypassing the Azure Firewall entirely for traffic destined to those on-premises prefixes. When Firewall is responsible for inspecting hybrid traffic, disable BGP route propagation on spoke subnet route tables and use explicit UDRs (including entries for on-premises CIDRs pointing to Firewall) to control all traffic paths deterministically.

---

## Related pages

- [Azure Virtual Network](../services/virtual-network.md) — VNet peering mechanics, UDR fundamentals, NSG processing, address space planning rules, and the March 2026 private-subnet default change
- [Azure Virtual WAN](../services/virtual-wan.md) — Microsoft-managed hub-spoke alternative; architecture details, scaling limits, migration path from DIY hub-spoke (`migrate-from-hub-spoke-topology.md`)
- [Azure Virtual Network Manager](../services/virtual-network-manager.md) — Automates hub-spoke connectivity configs, security admin rules, UDR management, and IPAM at enterprise scale
- [Azure Firewall](../services/azure-firewall.md) — Centralized inspection engine for the hub; SKU selection (Basic/Standard/Premium), rule processing order, DNS proxy, TLS inspection, and forced tunneling
- [Azure Route Server](../services/route-server.md) — BGP-based dynamic route injection from NVAs into hub and spoke VNets; eliminates static UDR management in NVA-based hub designs

---

## Source articles

| Article | Location | Date |
|---|---|---|
| Azure Virtual Network (compiled wiki) | `wiki/services/virtual-network.md` | 2025-07-31 |
| Azure Virtual WAN (compiled wiki) | `wiki/services/virtual-wan.md` | 2026-04-10 |
| Azure Virtual Network Manager (compiled wiki) | `wiki/services/virtual-network-manager.md` | 2026-04-10 |
| Azure Firewall (compiled wiki) | `wiki/services/azure-firewall.md` | 2025-07-14 |
| Azure Route Server (compiled wiki) | `wiki/services/route-server.md` | 2026-04-10 |
| Design a secure hub-spoke network for regional web applications | `raw/articles/networking/cross-service-scenarios/design-secure-hub-spoke-network.md` | 2026-03-24 |
| Azure network foundation services overview | `raw/articles/networking/foundations/network-foundations-overview.md` | 2025-07-26 |