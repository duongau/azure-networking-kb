# Azure ExpressRoute

> **Compiled:** 2026-04-10 | **Source articles:** 21 | **Status:** current

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
| **ExpressRoute Metro** | Single circuit with links in two distinct peering locations within the same city for higher site-level resiliency; 21 metro locations available [VERIFY for latest list] |
| **Global Reach** | Link two ExpressRoute circuits privately to route on-premises-to-on-premises traffic over Microsoft's backbone |
| **BGP dynamic routing** | Microsoft AS 12076; supports 16-bit and 32-bit AS numbers |
| **FastPath** | Bypass the ER gateway — on-premises traffic goes directly to VMs, improving latency and throughput |
| **MACsec encryption** | Layer 2 encryption on ExpressRoute Direct physical links (BYOK from Azure Key Vault) |
| **IPsec over private peering** | Layer 3 end-to-end encryption using VPN Gateway over ER private peering (not supported on ErGwScale) |
| **QoS support** | DSCP marking preservation for Microsoft Teams/Skype (Microsoft peering only) |
| **M365 access** | Requires Microsoft peering + Premium add-on |
| **Traffic Collector** | Flow telemetry at 1:4096 sampling; up to 300,000 flows/min; no customer data stored |
| **BFD** | Bidirectional Forwarding Detection on private peering reduces failure detection from ~3 min → <1 sec |
| **Resiliency Insights** | Portal feature on ExpressRoute VNet gateway that scores control-plane resiliency 0–100; factors: route resiliency, zone-redundant gateway, advisor recommendations, resiliency validation recency; private peering only |
| **Resiliency Validation** | Simulates circuit failover from portal; temporarily disconnects gateway from target circuit; validates HA/DR; requires 2 circuits in distinct peering locations; not supported for Virtual WAN or Metro |
| **Customer-controlled maintenance** | Schedule maintenance windows for ExpressRoute VNet gateways; configure start date, time, and daily duration |
| **Circuit migration** | Guided process to migrate production traffic from one circuit to another with minimal disruption; applies to L2 provider and ExpressRoute Direct |

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

| Gateway SKU | Max ER circuit connections | FastPath | VPN coexistence | Notes |
|---|---|---|---|---|
| **Standard / ERGw1Az** | 4 | ❌ | ✅ | — |
| **High Performance / ERGw2Az** | 8 | ❌ | ✅ | — |
| **Ultra Performance / ErGw3Az** | 16 | ✅ | ✅ | — |
| **ErGwScale** | 4 (1 SU) / 8 (2 SU) / 16 (10+ SU) | ✅ (≥10 scale units) | ✅ | Autoscales 1–40 scale units; up to 40 Gbps; IPsec over ER **not** supported |

> **Note:** Max circuits from the same peering location to the same VNet is always 4, regardless of gateway SKU.

> **Gateway performance figures** are in `[!INCLUDE]` directives not available in raw articles — see `expressroute-about-virtual-network-gateways.md` section `#aggthroughput` for current values. **[VERIFY]**

### ErGwScale performance reference

| Scale units | Aggregate bandwidth | Packets/sec | Connections/sec | Max VM connections |
|---|---|---|---|---|
| 1 | 1 Gbps | 100,000 | 7,000 | 2,000 |
| 10 | 10 Gbps | 1,000,000 | 70,000 | 20,000 |
| 20 | 20 Gbps | 2,000,000 | 140,000 | 30,000 [VERIFY] |
| 40 | 40 Gbps | 8,000,000 | 280,000 | 50,000 [VERIFY] |

**ErGwScale upgrade/migration paths:**
- From **ErGw1Az / ErGw2Az / ErGw3Az**: direct in-place upgrade via portal or PowerShell; no downtime; up to 2 hours.
- From **Standard / High Performance / Ultra Performance**: must use the gateway migration tool (`gateway-migration.md`).

**ErGwScale limitations:** IPsec over ExpressRoute not supported; Basic public IP SKU not supported; autoscaling requires minimum scale unit ≥ 2 (or set min = max for fixed).

**ErGwScale region gaps (not available):** Belgium Central, Japan East, Qatar Central, Southeast Asia, West Europe, West India, West US 2, South Central US, East US 2. [VERIFY for latest]

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
| **Dual circuits, different peering locations** | Maximum resiliency | Protects against full site/location outage; Microsoft's recommended architecture; enables Resiliency Validation |
| **ExpressRoute Metro** | Multi-site within city | Single circuit with two physical link sets at two locations in same metro — simpler than dual circuits; scores 10% in Resiliency Insights route score |
| **VPN Gateway as backup** | Fallback to internet | S2S VPN over internet as warm standby; requires Route Server for BGP integration |
| **Zone-redundant gateway (ErGw*Az SKUs)** | AZ-level gateway HA | Deploys gateway instances across availability zones; contributes 8–10% to Resiliency Insights score |

**Active-active recommendation:** During maintenance, Microsoft uses AS path prepend to drain traffic to the healthy link. If you've configured active-passive via your own prepend, ensure the passive path can actually handle traffic when Microsoft drains to it — a common gap in HA testing.

**BFD:** Configure Bidirectional Forwarding Detection on private peering to reduce failure detection time from ~3 minutes (BGP hold timer) to <1 second.

### ExpressRoute Metro locations (as of 2026-04-07)

| Metro location | Two peering sites | Local Azure region | ER Direct |
|---|---|---|---|
| Amsterdam Metro | Equinix AM5 / Digital Realty AMS8 | West Europe | ✅ |
| Atlanta Metro | Equinix AT1 / Digital Realty ATL14 | — | ✅ |
| Brussels Metro | Digital Realty BR4 / LCL Brussels North | Belgium Central | — |
| Chicago Metro | Equinix CH1 / CoreSite CH1 | North Central US | ✅ |
| Dallas Metro | Equinix DA6 / Digital Realty DFW10 | — | ✅ |
| Dublin Metro | Equinix DB3 / Digital Realty DUB02 | North Europe | ✅ |
| Frankfurt Metro | Digital Realty FRA11 / Equinix FR7 | Germany West Central | ✅ |
| Jakarta Metro | NeutraDC HDC / NTT GDC | Indonesia Central | ✅ |
| Madrid Metro | Equinix MD2 / Digital Realty MAD1 | Spain Central | ✅ |
| Milan Metro | Irideos Milan / Data4Italy Milan | Italy North | ✅ |
| Mumbai Metro | TATA LVSB / Nxtra Data | West India | ✅ |
| New York Metro | Equinix NY5 / 165 Halsey Street | — | ✅ |
| Oslo Metro | DigiPlex Ulven / Bulk Data IX | Norway East | ✅ |
| Silicon Valley Metro | Equinix SV10 / CoreSite SV7 | West US | ✅ |
| Singapore Metro | Global Switch Tai Seng / Equinix SG1 | Southeast Asia | ✅ |
| Stockholm Metro | Equinix SK1 / Digital Realty STO6 | Sweden Central | ✅ |
| Taipei Metro | Chief Telecom / Chunghwa Telecom | Taiwan North | ✅ |
| Toronto Metro | Cologix TOR1 / Allied King West | Canada Central | ✅ |
| Vienna Metro | Digital Realty VIE1 / NTT GDC | Austria East | ✅ |
| Washington DC Metro | Equinix DC6 / CoreSite VA3 | East US / East US 2 | ✅ |
| Zurich Metro | Digital Realty ZUR2 / Equinix ZH5 | Switzerland North | ✅ |

> Portal naming convention: City + City2 denote the two peering sites (e.g., Amsterdam and Amsterdam2 = Amsterdam Metro).

## Resiliency Insights and Validation

These two portal-based features (under the Monitoring section of ExpressRoute VNet gateways) work together to measure and prove resiliency. Both support **private peering only** — not Microsoft peering or VPN.

### Resiliency Insights — score formula

The resiliency index is a 0–100 score computed as:

```
Final score = (Route score × Validation multiplier) + Zone redundancy score + Advisor score
```

| Factor | Max contribution | Detail |
|---|---|---|
| **Route resiliency** | 20% base | Dual sites (distinct locations): 20%; Metro: 10%; Single site: 5%; Zero if MSEE-PE link failure present |
| **Zone-redundant gateway** | 10% | ErGw*Az zonal: 8%; zone-redundant: 10%; ErGwScale >4 SU: 8%; >4+ SU: 10%; Standard/HP/Ultra: 0–2% |
| **Advisor recommendations** | 10% | Full 10% if no outstanding recommendations; already factors out gateway/multi-site recommendations |
| **Validation multiplier** | ×1 – ×4 | Tests within 30 days: ×4; 31–60 days: ×3; 61–90 days: ×2; >90 days: ×1; only one site tested: half multiplier |

**Access requirement:** Contributor-level authorization on the gateway resource. Refreshes automatically every hour.

### Resiliency Validation — circuit failover simulation

Temporarily disconnects the gateway from a target circuit to validate that traffic fails over to the redundant circuit.

**Prerequisites:**
- ExpressRoute gateway connected to circuits in **at least two distinct peering locations**
- Not supported for Virtual WAN ExpressRoute gateways or ExpressRoute Metro circuits
- Contributor authorization on the gateway

**Test behavior:**
- Only the gateway under test disconnects from the target circuit; other gateways connected to that circuit remain connected
- Failover typically completes within ~15 seconds
- TCP iPerf tests (up to 500 Mbps) show no packet loss during simulation; brief BGP reconvergence may occur in real outages
- Test runs indefinitely until you select Stop; confirm success/failure when stopping
- If backup circuit exceeds 100% of bandwidth during failover, packet drops can occur — monitor Circuit QoS metrics

**Supports during failover:** FastPath (data bypasses gateway; routes withdrawn from affected circuit; failover connection maintains FastPath); Private Link (connectivity maintained via redundant circuit).

**Manual failover alternative** (for multi-site redundant circuits):
Disable BGP private peering on one circuit via portal (deselect Enable IPv4/IPv6 Peering checkbox on the circuit's peering page) to force failover to the redundant circuit. Re-enable after validation.

## Encryption

| Method | Layer | Scope | Requirement |
|---|---|---|---|
| **None (default)** | — | ExpressRoute does NOT encrypt traffic by default | — |
| **MACsec** | L2 (MAC layer) | ExpressRoute Direct only (not provider circuits) | BYOK from Azure Key Vault; GCM-AES-128/256/XPN-128/XPN-256 |
| **IPsec** | L3 (IP layer) | Over ER private peering using VPN Gateway | Can combine with MACsec for defense-in-depth; **not supported with ErGwScale gateway** |

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

## Key operational guidance

- **Deploy active-active, never active-passive** — passive path may carry stale routes and fail under Microsoft maintenance prepend events
- **BFD on private peering** — reduces failure detection from ~3 min to <1 sec; configure on customer edge routers
- **Attach route filters immediately after circuit creation** (Microsoft peering) — no prefixes are advertised without one
- **Never advertise 0.0.0.0/0 over private peering** unless you also have service endpoints for Azure PaaS — or M365 traffic will hairpin on-premises
- **Roll MACsec keys one link at a time** — a key mismatch causes complete connectivity loss with no fallback
- **Use Resiliency Insights** to baseline your current resiliency score and identify gaps; re-run Resiliency Validation at least every 30 days to maintain the maximum score multiplier
- **Schedule customer-controlled maintenance windows** for ExpressRoute VNet gateways via the Azure portal or PowerShell; specify start date, daily time, and duration — upgrades occur within the window only when available; takes effect on the configured start date
- **Circuit migration**: For L2 provider or ExpressRoute Direct circuits, follow the 5-step migration process: (1) deploy new circuit in isolation, (2) block production traffic on new circuit via route-map/policy, (3) validate end-to-end on test VNet, (4) switch production traffic, (5) decommission old circuit; use BGP route-maps (Cisco) or export/import policies (Junos) to block/permit advertisements
- **FastPath fallback is automatic** — when IP limits are exceeded or FastPath unavailable, traffic falls back through the ER gateway silently; monitor FastPath route counts
- **ECMP only across 4 circuits max** — you can link 16 circuits to one VNet, but only 4 participate in load balancing; the rest are failover capacity
- **ErGwScale autoscale takes up to 30 minutes** — pre-provision with a fixed minimum for predictable performance; do not rely on autoscale to absorb sudden traffic spikes

## Related services

- [VPN Gateway](../services/vpn-gateway.md) — alternative/complementary hybrid connectivity; lower cost, lower bandwidth; can coexist with ER on same VNet; can be used as warm standby over internet when ER fails
- [Virtual Network](../services/virtual-network.md) — ER private peering terminates at VNet via ExpressRoute VNet gateway; VNet peering extends reachability from ER to spoke VNets
- [Azure Firewall](../services/azure-firewall.md) — can inspect on-premises traffic coming in over ER; deploy in hub VNet with UDR on GatewaySubnet; Azure Firewall in spoke VNets not supported with FastPath
- [Private Link](../services/private-link.md) — private endpoints reachable over ER private peering; throughput may be reduced by ~50% for PE resources via ER gateway; FastPath for Private Link available on Direct circuits (limited GA)
- [DDoS Protection](../services/ddos-protection.md) — ER private peering uses private IPs not subject to volumetric internet DDoS; Microsoft peering public IPs may benefit from DDoS protection
- [Azure DNS](../services/dns.md) — on-premises DNS resolution of Azure private DNS zones over ER requires DNS Private Resolver or conditional forwarders in the hub VNet; DNS Private Resolver in spoke VNets not supported with FastPath
- [Network Watcher](../services/network-watcher.md) — Connection Monitor supports monitoring ER private peering and Microsoft peering health
- [Azure Bastion](../services/bastion.md) — for Premium private-only Bastion deployments, ExpressRoute private peering is the user access path

## Compile notes

1. **VNet and Global Reach limits table** (`expressroute-faqs.md#limits`) references `[!INCLUDE [ExpressRoute limits](../../includes/expressroute-limits.md)]` — the include file is not in raw articles. All VNet connection counts marked `[VERIFY]`.
2. **Gateway performance table** (`expressroute-about-virtual-network-gateways.md#aggthroughput`) also in an include file — marked `[VERIFY]`. ErGwScale performance table sourced from `scalable-gateway.md` (2025-11-06).
3. **ExpressRoute Direct FAQ** (`expressroute-faqs.md#expressRouteDirect`) also in include file — Direct-specific limits (circuits per port, etc.) are not fully captured here. `[VERIFY]`
4. **Global Reach FAQ** (`expressroute-faqs.md#globalreach`) also in include file — limits on Global Reach connections per circuit not captured. `[VERIFY]`
5. **400 Gbps ExpressRoute Direct** is referenced in both `expressroute-introduction.md` and `expressroute-erdirect-about.md`. Both agree — not a conflict.
6. **Resiliency Validation not supported for Metro** — noted in `resiliency-validation.md`. This is a capability gap for Metro users who want simulation testing.
7. **IPsec not supported on ErGwScale** — explicitly stated in `scalable-gateway.md`; new limitation vs. prior ErGwScale coverage in old wiki.
8. **ErGwScale not available in 9 regions** — listed in `scalable-gateway.md`; may change over time, marked `[VERIFY]`.

## Source articles

- [Azure ExpressRoute overview](../../raw/articles/expressroute/expressroute-introduction.md) — updated 2026-03-03
- [ExpressRoute circuits and peering](../../raw/articles/expressroute/expressroute-circuit-peerings.md)
- [ExpressRoute connectivity models](../../raw/articles/expressroute/expressroute-connectivity-models.md)
- [About ExpressRoute Direct](../../raw/articles/expressroute/expressroute-erdirect-about.md)
- [About ExpressRoute virtual network gateways](../../raw/articles/expressroute/expressroute-about-virtual-network-gateways.md)
- [ExpressRoute FAQ](../../raw/articles/expressroute/expressroute-faqs.md)
- [ExpressRoute routing requirements](../../raw/articles/expressroute/expressroute-routing.md)
- [About ExpressRoute Global Reach](../../raw/articles/expressroute/expressroute-global-reach.md)
- [About ExpressRoute Metro](../../raw/articles/expressroute/metro.md) — updated 2026-04-07
- [Azure ExpressRoute FastPath](../../raw/articles/expressroute/about-fastpath.md)
- [About encryption for Azure ExpressRoute](../../raw/articles/expressroute/expressroute-about-encryption.md)
- [Designing for high availability with Azure ExpressRoute](../../raw/articles/expressroute/designing-for-high-availability-with-expressroute.md)
- [ExpressRoute NAT requirements](../../raw/articles/expressroute/expressroute-nat.md)
- [ExpressRoute prerequisites](../../raw/articles/expressroute/expressroute-prerequisites.md)
- [ExpressRoute QoS requirements](../../raw/articles/expressroute/expressroute-qos.md)
- [Resiliency Insights for ExpressRoute VNet gateway](../../raw/articles/expressroute/resiliency-insights.md) — **new** 2025-11-04
- [Azure ExpressRoute Gateway Resiliency Validation](../../raw/articles/expressroute/resiliency-validation.md) — **new** 2025-11-04
- [Evaluate the resiliency of multi-site redundant ExpressRoute circuits](../../raw/articles/expressroute/evaluate-circuit-resiliency.md) — **new** 2026-03-12
- [About ExpressRoute scalable gateway (ErGwScale)](../../raw/articles/expressroute/scalable-gateway.md) — **new** 2025-11-06
- [Migrate to a new ExpressRoute circuit](../../raw/articles/expressroute/circuit-migration.md) — **new** 2025-01-31
- [Configure customer-controlled maintenance for ExpressRoute gateways](../../raw/articles/expressroute/customer-controlled-gateway-maintenance.md) — **new** 2025-03-11
```

---

## ✅ RECOMPILE 2 — Azure Load Balancer

**File:** `wiki/services/load-balancer.md`

```markdown