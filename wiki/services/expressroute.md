# Azure ExpressRoute

> **Compiled:** 2025-01-27 | **Source articles:** 13 | **Status:** current

## What it is

Azure ExpressRoute creates private, dedicated connections between your on-premises network and the Microsoft cloud through a connectivity provider — traffic does not traverse the public Internet. Each circuit consists of two redundant physical links to two Microsoft Enterprise Edge routers (MSEEs) at an ExpressRoute peering location, providing Layer 3 BGP connectivity to either Azure virtual network resources (private peering) or Microsoft cloud services like Microsoft 365 and Azure PaaS (Microsoft peering).

## Key capabilities

| Capability | Details |
|---|---|
| **Private connectivity** | Traffic between on-premises and Azure never crosses the public Internet |
| **Two peering types** | Azure Private Peering (VNet resources via private IPs) and Microsoft Peering (M365, Azure PaaS via public IPs) |
| **Circuit bandwidth** | 50 Mbps, 100 Mbps, 200 Mbps, 500 Mbps, 1 Gbps, 2 Gbps, 5 Gbps, 10 Gbps (provider circuits); up to 400 Gbps (ExpressRoute Direct) |
| **Bandwidth is duplex** | A 200 Mbps circuit gives 200 Mbps inbound AND 200 Mbps outbound |
| **Built-in redundancy** | Every circuit has primary + secondary connections to two separate MSEEs — both should run active-active |
| **ExpressRoute Direct** | Bypass service providers; connect directly into Microsoft global network at 10/100/400 Gbps |
| **ExpressRoute Metro** | Single circuit with links in two distinct peering locations within the same city for higher site-level resiliency |
| **Global Reach** | Link two ExpressRoute circuits privately to route on-premises-to-on-premises traffic over Microsoft's backbone |
| **BGP dynamic routing** | Microsoft AS 12076; supports 16-bit and 32-bit AS numbers |
| **FastPath** | Bypass the ER gateway — on-premises traffic goes directly to VMs, improving latency and throughput |
| **MACsec encryption** | Layer 2 encryption on ExpressRoute Direct physical links (BYOK from Azure Key Vault) |
| **IPsec over private peering** | Layer 3 end-to-end encryption using VPN Gateway over ER private peering |
| **QoS support** | DSCP marking preservation for Microsoft Teams/Skype (Microsoft peering only) |
| **M365 access** | Requires Microsoft peering + Premium add-on |
| **Traffic Collector** | Flow telemetry at 1:4096 sampling; up to 300,000 flows/min; no customer data stored |
| **BFD** | Bidirectional Forwarding Detection on private peering reduces failure detection from ~3 min → <1 sec |

## When to use it

| Scenario | Reason |
|---|---|
| Consistent, predictable latency required for production workloads | No internet jitter or congestion; SLA-backed private path |
| Massive data ingestion into Azure (Storage, Cosmos DB) | High, sustained bandwidth without internet bottlenecks or egress charges (Unlimited/Local SKU) |
| Regulated industries requiring physical network isolation | ExpressRoute Direct provides dedicated ports; MACsec adds L2 encryption |
| Hybrid workloads requiring private IP connectivity to Azure VMs | Private peering extends your corporate network address space into Azure |
| Microsoft 365 connectivity requiring private path | Microsoft peering with Premium add-on |
| Site-to-site connectivity between on-premises datacenters via Microsoft backbone | Global Reach links circuits across sites |
| Compliance mandates prohibiting public Internet for cloud traffic | No Internet path at any point |
| Bandwidth > 10 Gbps | ExpressRoute Direct (100 or 400 Gbps) |

## When NOT to use it

| Anti-pattern | Alternative |
|---|---|
| **Low-traffic, cost-sensitive connectivity to Azure** | Site-to-site VPN Gateway (much lower cost, adequate for <1 Gbps workloads) |
| **Rapid/temporary connectivity needed** | VPN Gateway can be provisioned in minutes; ExpressRoute requires partner provisioning (weeks) |
| **Internet-only services (CDN, Front Door, Traffic Manager)** | These are NOT accessible via ExpressRoute — they're internet-only by design |
| **VNet-to-VNet communication** | VNet Peering is lower latency, lower cost, and explicitly recommended over using ER for VNet-to-VNet |
| **Single-VM or dev/test connectivity** | Overhead of circuit provisioning and cost isn't justified; use VPN or Bastion |
| **Branch offices needing simple connectivity** | Azure Virtual WAN with VPN is simpler and more scalable for branch scenarios |

## SKUs and tiers

### Circuit SKUs

| SKU | Scope | Billing | Key restrictions |
|---|---|---|---|
| **Local** | 1–2 Azure regions near the peering location | Data transfer included in port charge (no separate egress billing) [VERIFY] | Global Reach not available; limited to local Azure regions only |
| **Standard** | All Azure regions in the same geopolitical area | Metered or Unlimited | Up to 10 VNets per circuit (default) |
| **Premium** | All Azure regions globally (except national clouds) | Metered or Unlimited | Up to 100 VNets per circuit; required for M365; required for Global Reach across geopolitical boundaries |

**SKU upgrade/downgrade rules:**
- Standard → Premium: allowed
- Local → Standard or Premium: allowed (PowerShell/CLI only; billing must be Unlimited)
- MeteredData → UnlimitedData: allowed
- **UnlimitedData → MeteredData: NOT allowed**
- Premium → Standard (downgrade): allowed if utilization is within Standard limits

### ExpressRoute Direct port SKUs

| Port speed | Circuit SKUs available on port |
|---|---|
| **10 Gbps** | 1, 2, 5, 10 Gbps |
| **100 Gbps** | 5, 10, 40, 100 Gbps |
| **400 Gbps** | 5, 10, 40, 100, 200, 400 Gbps (limited locations; enrollment required) [VERIFY] |

### Virtual Network Gateway SKUs for ExpressRoute

| Gateway SKU | Max ER circuit connections | FastPath | VPN coexistence |
|---|---|---|---|
| **Standard / ERGw1Az** | 4 | ❌ | ✅ |
| **High Performance / ERGw2Az** | 8 | ❌ | ✅ |
| **Ultra Performance / ErGw3Az** | 16 | ✅ | ✅ |
| **ErGwScale** | 4 (1 SU) / 8 (2 SU) / 16 (10+ SU) | ✅ (≥10 scale units) | ✅ |

> **Note:** Max circuits from the same peering location to the same VNet is always 4, regardless of gateway SKU.

> **Gateway performance figures** are in `[!INCLUDE]` directives not available in raw articles — see `expressroute-about-virtual-network-gateways.md` section `#aggthroughput` for current values. **[VERIFY]**

## Service limits

| Limit | Value | Notes |
|---|---|---|
| ExpressRoute circuits per subscription | 50 (default) | Increasable via support ticket [VERIFY] |
| Circuit bandwidth options (provider) | 50 Mbps–10 Gbps | 8 tiers: 50, 100, 200, 500 Mbps, 1, 2, 5, 10 Gbps |
| Maximum MTU | 1,400 bytes | Tune VM TCP/IP settings accordingly — not the standard 1,500 |
| VNets per Standard circuit | 10 | [VERIFY] |
| VNets per Premium circuit | Up to 100 | Scaled by circuit bandwidth [VERIFY] |
| IPv4 prefixes advertised to Microsoft (private peering) | 4,000 (Standard/Local), 10,000 (Premium) | BGP session drops if exceeded |
| IPv6 prefixes advertised to Microsoft (private peering) | 100 | Additional to IPv4 limit |
| Prefixes per BGP session (Microsoft peering) | 200 | |
| IPv4 prefixes advertised from VNet to on-premises | 1,000 | Across all VNets using gateway transit |
| IPv6 prefixes advertised from VNet to on-premises | 100 | Additional to IPv4 |
| Total routes supported by ER gateway | 11,000 | Includes VNet, on-premises, peered VNet prefixes |
| Circuits linkable to same VNet (same peering location) | 4 | ECMP load balancing across all 4 |
| Circuits linkable to same VNet (different peering locations) | 16 | ECMP only across 4; remaining are available for failover |
| VNet peerings on a VNet with ER gateway | 500 | |
| BGP hold time (fixed by Microsoft) | 180 seconds | Keep-alive every 60 s; cannot change Microsoft-side |
| BGP AS used by Microsoft | AS 12076 | Reserved ASNs 65,515–65,520 for internal use |
| FastPath IP limit (Direct 100/400 Gbps) | 200,000 IPs | Per port, cumulative; excess traffic falls back to gateway |
| FastPath IP limit (Direct 10 Gbps) | 100,000 IPs | |
| FastPath IP limit (provider circuits ≤10 Gbps) | 25,000 IPs | |
| Traffic Collector max flows | 300,000 flows/min | Excess dropped; sampling rate 1:4096 |
| ExpressRoute limits table (VNets/Global Reach per Premium circuit) | In `[!INCLUDE]` file | **[VERIFY]** — see `expressroute-faqs.md#limits` |

## Connectivity models

| Model | Layer | Description |
|---|---|---|
| **CloudExchange Colocation** | L2 or L3 | Virtual cross-connection through colocation provider's Ethernet exchange |
| **Point-to-point Ethernet** | L2 | Dedicated Ethernet link from on-premises DC to Microsoft |
| **Any-to-any (IPVPN/MPLS)** | L3 | Integrate WAN; Microsoft appears as another branch on your MPLS fabric |
| **ExpressRoute Direct** | L1 | Direct fiber connection into Microsoft global network; no service provider intermediary |

## High availability and resiliency patterns

| Pattern | Resiliency level | Notes |
|---|---|---|
| **Single circuit, active-active** | Within-location redundancy | Both links to two MSEEs active; protects against single MSEE or link failure |
| **Single circuit, active-passive** | Weaker | Not recommended — passive link may advertise stale routes; on failure ALL flows must reroute (vs. ~50% in active-active) |
| **Dual circuits, different peering locations** | Maximum resiliency | Protects against full site/location outage; Microsoft's recommended architecture |
| **ExpressRoute Metro** | Multi-site within city | Single circuit with two physical link sets at two locations in same metro — simpler than dual circuits |
| **VPN Gateway as backup** | Fallback to internet | S2S VPN over internet as warm standby; requires Route Server for BGP integration |
| **Zone-redundant gateway (ErGw*Az SKUs)** | AZ-level gateway HA | Deploys gateway instances across availability zones |

**Active-active recommendation:** During maintenance, Microsoft uses AS path prepend to drain traffic to the healthy link. If you've configured active-passive via your own prepend, ensure the passive path can actually handle traffic when Microsoft drains to it — a common gap in HA testing.

**BFD:** Configure Bidirectional Forwarding Detection on private peering to reduce failure detection time from ~3 minutes (BGP hold timer) to <1 second.

## Encryption

| Method | Layer | Scope | Requirement |
|---|---|---|---|
| **None (default)** | — | ExpressRoute does NOT encrypt traffic by default | — |
| **MACsec** | L2 (MAC layer) | ExpressRoute Direct only (not provider circuits) | BYOK from Azure Key Vault; GCM-AES-128/256/XPN-128/XPN-256 |
| **IPsec** | L3 (IP layer) | Over ER private peering using VPN Gateway | Can combine with MACsec for defense-in-depth |

**Critical MACsec behavior:** If MACsec is enabled and a key mismatch occurs, connectivity is **completely lost** — traffic does NOT fall back to unencrypted. Roll key changes one link at a time during a maintenance window, migrating traffic to the second link first.

**MACsec does NOT support:** LACP (Link Aggregation Control Protocol) or MLAG (Multi-Chassis Link Aggregation).

## FastPath details

FastPath bypasses the VNet gateway for on-premises→VM traffic, reducing latency and improving throughput. The gateway still handles control plane (route exchange).

**Requirements:** Ultra Performance, ErGw3Az, or ErGwScale (≥10 scale units) gateway.

**Feature matrix:**

| Feature | ExpressRoute Direct | Provider circuit |
|---|---|---|
| FastPath to hub VNet (IPv4) | ✅ | ✅ |
| FastPath to hub VNet (IPv6) | ✅ | ❌ |
| VNet peering over FastPath | ✅ | ❌ |
| UDR over FastPath | ✅ | ❌ |
| Private Link / private endpoints | ✅ (limited GA, enrollment required) | ❌ |

**FastPath does NOT support:**
- Internal load balancers or PaaS services in **spoke** VNets (hub ILBs work)
- Azure Firewall in spoke VNets
- DNS Private Resolver in spoke VNets
- Azure NetApp Files without Standard network features
- Global VNet peering (same-region only for peering over FastPath)

## Routing requirements

| Requirement | Private peering | Microsoft peering |
|---|---|---|
| IP address type | Private or public OK | Public IPs only (must be registered in RIR/IRR against your ASN) |
| BGP subnets (IPv4) | /29 split into two /30s (primary + secondary) | /29 split into two /30s |
| BGP subnets (IPv6) | /125 split into two /126s | /125 split into two /126s |
| Dual BGP sessions | Required for SLA validity | Required |
| HSRP/VRRP | NOT supported — Microsoft relies on BGP redundancy | NOT supported |
| BGP MD5 auth | Optional | Optional |
| Default route (0.0.0.0/0) | Accepted (forces all traffic on-prem including M365 — see below) | Not accepted |
| RFC 1918 prefixes | Accepted | NOT accepted — must filter before advertising |
| Route filters | Not required | **Required** for Microsoft peering circuits provisioned after Aug 1, 2017 — no prefixes advertised without route filter |

**Critical routing gotcha — default route advertisement:** If you advertise 0.0.0.0/0 over private peering, traffic to Microsoft peering services (Azure Storage, SQL, etc.) is also forced on-premises. Add service endpoints to keep that traffic on the Azure backbone.

**Microsoft peering — route filter required:** Circuits created after August 1, 2017 advertise **no prefixes** until a route filter is attached and services are selected. This is a common "why can't I reach anything" support scenario.

## NAT requirements

| Peering | NAT requirement |
|---|---|
| **Private peering** | No NAT required; private IPs traverse the circuit |
| **Microsoft peering** | All traffic entering Microsoft network must be SNATed to public IPv4 addresses registered in RIR/IRR to your ASN |

**NAT IP pool rules:** Do NOT advertise your NAT IP pool to the Internet — doing so breaks connectivity to other Microsoft services. Use a separate public range registered in RIR/IRR.

**NAT for active-active (two options):**
- **Option 1 (independent pools per link):** Provides clean separation but a link failure makes that NAT pool unreachable — all sessions through that pool break.
- **Option 2 (shared pool before split):** No single point of failure; preferred for HA.

## QoS

DSCP markings are preserved through ER but only acted on by Microsoft for **Microsoft peering** (not private peering):

| Traffic class | DSCP value | Workload |
|---|---|---|
| Voice | EF (46) | Teams/Skype voice |
| Video/interactive | AF41 (34) | Video, VBSS |
| App sharing | AF21 (18) | App sharing |
| File transfer | AF11 (10) | File transfer |
| Default | CS0 (0) | Everything else |

Non-listed DSCP values must be rewritten to 0 before sending to Microsoft.

## Related services

- [VPN Gateway](../services/vpn-gateway.md) — alternative/complementary hybrid connectivity; lower cost, lower bandwidth; can coexist with ER on same VNet; can be used as warm standby over internet when ER fails
- [Virtual Network](../services/virtual-network.md) — ER private peering terminates at VNet via ExpressRoute VNet gateway; VNet peering extends reachability from ER to spoke VNets
- [Azure Firewall](../services/azure-firewall.md) — can inspect on-premises traffic coming in over ER; deploy in hub VNet with UDR on GatewaySubnet; Azure Firewall in spoke VNets not supported with FastPath
- [Private Link](../services/private-link.md) — private endpoints reachable over ER private peering; throughput may be reduced by ~50% for PE resources via ER gateway; FastPath for Private Link available on Direct circuits (limited GA)
- [DDoS Protection](../services/ddos-protection.md) — ER private peering uses private IPs not subject to volumetric internet DDoS; Microsoft peering public IPs may benefit from DDoS protection
- [Azure DNS](../services/dns.md) — on-premises DNS resolution of Azure private DNS zones over ER requires DNS Private Resolver or conditional forwarders in the hub VNet; DNS Private Resolver in spoke VNets not supported with FastPath
- [Network Watcher](../services/network-watcher.md) — Connection Monitor supports monitoring ER private peering and Microsoft peering health

> ⚠️ **Backlinks pending:** Load Balancer, Application Gateway, Bastion, NAT Gateway pages not yet compiled — add backlinks when those pages are written.

## Compile notes

1. **VNet and Global Reach limits table** (`expressroute-faqs.md#limits`) references `[!INCLUDE [ExpressRoute limits](../../includes/expressroute-limits.md)]` — the include file is not in raw articles. All VNet connection counts marked `[VERIFY]`.
2. **Gateway performance table** (`expressroute-about-virtual-network-gateways.md#aggthroughput`) also in an include file — marked `[VERIFY]`.
3. **ExpressRoute Direct FAQ** (`expressroute-faqs.md#expressRouteDirect`) also in an include file — Direct-specific limits (circuits per port, etc.) are not fully captured here. `[VERIFY]`
4. **Global Reach FAQ** (`expressroute-faqs.md#globalreach`) also in include file — limits on Global Reach connections per circuit not captured. `[VERIFY]`
5. **400 Gbps ExpressRoute Direct** is referenced in both `expressroute-introduction.md` (dual 10/100/400 Gbps) and `expressroute-erdirect-about.md` (400-Gbps, limited locations, enrollment required). Both sources agree — not a conflict.
6. **Private endpoint throughput via ER gateway:** Described as "may be reduced by half" — language is approximate, not a hard limit. [VERIFY exact degradation]

## Source articles

- [Azure ExpressRoute overview](../../raw/articles/expressroute/expressroute-introduction.md)
- [ExpressRoute circuits and peering](../../raw/articles/expressroute/expressroute-circuit-peerings.md)
- [ExpressRoute connectivity models](../../raw/articles/expressroute/expressroute-connectivity-models.md)
- [About ExpressRoute Direct](../../raw/articles/expressroute/expressroute-erdirect-about.md)
- [About ExpressRoute virtual network gateways](../../raw/articles/expressroute/expressroute-about-virtual-network-gateways.md)
- [ExpressRoute FAQ](../../raw/articles/expressroute/expressroute-faqs.md)
- [ExpressRoute routing requirements](../../raw/articles/expressroute/expressroute-routing.md)
- [About ExpressRoute Global Reach](../../raw/articles/expressroute/expressroute-global-reach.md)
- [About ExpressRoute Metro](../../raw/articles/expressroute/metro.md)
- [Azure ExpressRoute FastPath](../../raw/articles/expressroute/about-fastpath.md)
- [About encryption for Azure ExpressRoute](../../raw/articles/expressroute/expressroute-about-encryption.md)
- [Designing for high availability with Azure ExpressRoute](../../raw/articles/expressroute/designing-for-high-availability-with-expressroute.md)
- [ExpressRoute NAT requirements](../../raw/articles/expressroute/expressroute-nat.md)
- [ExpressRoute prerequisites](../../raw/articles/expressroute/expressroute-prerequisites.md)
- [ExpressRoute QoS requirements](../../raw/articles/expressroute/expressroute-qos.md)

---

## What I flagged

**4 `[VERIFY]` items requiring include-file resolution:**
1. VNet connections per Standard/Premium circuit (from `expressroute-limits.md` include)
2. Global Reach connections per circuit (same include)
3. Gateway throughput per SKU (from `expressroute-gateway-performance-include.md`)
4. ExpressRoute Direct-specific limits — circuits per port, etc. (from `expressroute-direct-faq-include.md`)

**Non-obvious behaviors surfaced (for team awareness):**
- **Route filter required for new Microsoft peering circuits (Aug 2017+):** Zero prefixes advertised without an explicit route filter attachment. Most common Day-1 "nothing works" issue.
- **Default route (0.0.0.0/0) over private peering hijacks Microsoft peering traffic:** If you force-tunnel on-premises and also use Microsoft peering, you need service endpoints to keep Azure service traffic local.
- **MACsec key mismatch = hard loss of connectivity, no fallback:** No graceful degradation to unencrypted. Roll keys one link at a time.
- **Active-passive is explicitly an anti-pattern:** Passive path may have stale routes; Microsoft may prepend into the "active" path during maintenance, sending all traffic to the passive path that can't handle it.
- **ECMP only across 4 circuits max:** You can connect 16 circuits to one VNet, but only 4 participate in load balancing — the rest are pure failover capacity.
- **FastPath fallback is automatic:** When IP limits are exceeded or FastPath is unavailable, traffic silently falls back through the ER gateway. Set Azure Monitor alerts on FastPath route count approaching threshold.

**Remaining compilation queue:** Load Balancer → Application Gateway → Private Link → Bastion → DDoS Protection → Network Watcher. Then `wiki/index.md` needs updating for all 5 compiled services.
