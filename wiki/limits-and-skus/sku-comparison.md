# Azure Networking: SKU Comparison & Service Limits

> **Compiled:** 2025-07-15 | **Type:** Reference | **Source pages:** 12 | **Status:** ✅ current

## How to use this page

Quick reference for SKU selection and limit planning. All numeric limits extracted from compiled wiki pages — values tagged `[VERIFY]` require cross-check against Microsoft's authoritative source before use in architecture decisions. For full limits, see [Azure subscription and service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits).

---

## Connectivity services

### VPN Gateway SKUs

| SKU | Generation | Max S2S tunnels | Max P2S (SSTP / IKEv2) | Aggregate throughput | BGP | Zone-redundant | Notes |
|---|---|---|---|---|---|---|---|
| **Basic** | Legacy/Gen1 | 10 (route-based) / 1 (policy-based) | 128 SSTP / not supported | see docs | ❌ | ❌ | Dev/test only; no RADIUS, no IKEv2 P2S, no active-active, no IPv6; PowerShell/CLI only |
| **VpnGw1** | Gen1/Gen2 [VERIFY] | 30 [VERIFY] | 128 SSTP / 250 IKEv2 | see docs [VERIFY] | ✅ | ❌ | Entry production |
| **VpnGw1AZ** | Gen1/Gen2 [VERIFY] | 30 [VERIFY] | 128 SSTP / 250 IKEv2 | see docs [VERIFY] | ✅ | ✅ | Zone-redundant variant of VpnGw1 |
| **VpnGw2 / VpnGw2AZ** | Gen1/Gen2 [VERIFY] | 30 [VERIFY] | see docs [VERIFY] | see docs [VERIFY] | ✅ | ✅ (AZ) | Min SKU for NAT (overlapping address spaces) |
| **VpnGw3 / VpnGw3AZ** | Gen1/Gen2 [VERIFY] | 30 [VERIFY] | see docs [VERIFY] | see docs [VERIFY] | ✅ | ✅ (AZ) | Higher throughput |
| **VpnGw4 / VpnGw4AZ** | Gen2 | 100 [VERIFY] | see docs [VERIFY] | see docs [VERIFY] | ✅ | ✅ (AZ) | Large enterprise |
| **VpnGw5 / VpnGw5AZ** | Gen2 | 100 [VERIFY] | see docs [VERIFY] | see docs [VERIFY] | ✅ | ✅ (AZ) | Highest performance |

> ⚠️ **Legacy SKUs retiring March 31, 2026:** Standard (100 Mbps, 10 tunnels → migrate to VpnGw1AZ) and High Performance (200 Mbps, 30 tunnels → migrate to VpnGw2AZ).

> ⚠️ Per-SKU throughput figures live in include files not directly readable from raw articles. Check [About VPN Gateway SKUs](https://learn.microsoft.com/azure/vpn-gateway/about-gateway-skus) for current values. All throughput cells marked `see docs` until verified.

**Key VPN Gateway service limits**

| Limit | Value | Notes |
|---|---|---|
| Max S2S tunnels per gateway | 100 [VERIFY] | Use Virtual WAN if >100 needed |
| Basic SKU — route-based tunnels | 10 | — |
| Basic SKU — policy-based tunnels | 1 | — |
| P2S connections — VpnGw1 SSTP | 128 | Independent from IKEv2 count |
| P2S connections — VpnGw1 IKEv2 | 250 | Independent from SSTP count |
| P2S connections — higher SKUs | see docs [VERIFY] | See `about-gateway-skus.md` |
| Gateway subnet minimum size | /27 (all SKUs except Basic) | Basic accepts /29; recommend /27+ for growth |
| Active-standby failover — planned | 10–15 seconds | S2S and VNet-to-VNet only |
| Active-standby failover — unplanned | 1–3 minutes | — |
| VPN gateways per VNet | 1 VPN + 1 ER gateway | Each VNet supports at most one of each |
| Public IP SKU required | Standard, Static | Basic public IPs retiring end of June 2026 |
| NAT support | VpnGw2–5 and AZ variants | S2S only; not VNet-to-VNet or P2S |
| Gateway creation time | ~45 minutes | Varies by SKU |

---

### ExpressRoute Circuit SKUs

| SKU | Regional scope | Data billing | Max VNets linked | Global Reach | Microsoft peering (M365) | IPv4 routes (private peering) | Premium required? |
|---|---|---|---|---|---|---|---|
| **Local** | 1–2 Azure regions near peering location | Included in port charge (no egress billing) [VERIFY] | see docs | ❌ | ❌ | 4,000 [VERIFY] | No |
| **Standard** | All regions in same geopolitical area | Metered or Unlimited | 10 [VERIFY] | Within same geopolitical area | ❌ | 4,000 [VERIFY] | No |
| **Premium** | All Azure regions globally | Metered or Unlimited | Up to 100 [VERIFY] | Across geopolitical boundaries | ✅ | 10,000 [VERIFY] | Yes |

**SKU upgrade/downgrade rules:** Standard→Premium ✅ | Local→Standard/Premium ✅ (CLI/PS; Unlimited billing required) | MeteredData→Unlimited ✅ | **Unlimited→Metered ❌ not allowed** | Premium→Standard ✅ if within Standard limits.

**ExpressRoute Direct port speeds:** 10 Gbps, 100 Gbps, 400 Gbps (limited locations; enrollment required [VERIFY]).

---

### ExpressRoute Gateway SKUs

| Gateway SKU | Max ER circuits linked | FastPath support | Zone-redundant | VPN coexistence |
|---|---|---|---|---|
| **Standard / ERGw1Az** | 4 | ❌ | ✅ (Az variant) | ✅ |
| **High Performance / ERGw2Az** | 8 | ❌ | ✅ (Az variant) | ✅ |
| **Ultra Performance / ErGw3Az** | 16 | ✅ | ✅ (Az variant) | ✅ |
| **ErGwScale** | 4 (1 SU) / 8 (2 SU) / 16 (10+ SU) | ✅ (≥10 scale units) | ✅ | ✅ |

> Max circuits from the **same** peering location to the same VNet is always **4**, regardless of gateway SKU.
> Gateway throughput figures live in include files — check `expressroute-about-virtual-network-gateways.md` for current values [VERIFY].

**Key ExpressRoute service limits**

| Limit | Value | Notes |
|---|---|---|
| ER circuits per subscription (default) | 50 [VERIFY] | Increasable via support ticket |
| Circuit bandwidth options (provider) | 50 Mbps – 10 Gbps | 8 tiers |
| Maximum MTU | 1,400 bytes | Tune TCP/IP settings on VMs |
| VNets per Standard circuit | 10 [VERIFY] | — |
| VNets per Premium circuit | Up to 100 [VERIFY] | Scaled by circuit bandwidth |
| IPv4 routes to Microsoft (private peering) | 4,000 (Standard/Local) / 10,000 (Premium) | BGP session drops if exceeded |
| IPv6 routes to Microsoft (private peering) | 100 | Additional to IPv4 |
| Routes per BGP session (Microsoft peering) | 200 | — |
| IPv4 prefixes advertised from VNet to on-prem | 1,000 | Across all VNets using gateway transit |
| Total routes supported by ER gateway | 11,000 | Includes VNet, on-prem, peered VNet prefixes |
| Circuits to same VNet (same peering location) | 4 | ECMP across all 4 |
| Circuits to same VNet (different locations) | 16 | ECMP over 4; remainder for failover |
| VNet peerings on VNet with ER gateway | 500 | — |
| BGP hold time (Microsoft-side) | 180 seconds | Keep-alive every 60 s; cannot change |
| FastPath IP limit (provider circuits ≤10 Gbps) | 25,000 IPs | Excess falls back to gateway |
| FastPath IP limit (Direct 10 Gbps) | 100,000 IPs | — |
| FastPath IP limit (Direct 100/400 Gbps) | 200,000 IPs | — |

---

## Load balancing services

### Azure Load Balancer SKUs

| SKU | HA ports | Outbound rules | Zone-redundant | Cross-region (Global) | SLA | NSG required | NVA chaining | Retirement |
|---|---|---|---|---|---|---|---|---|
| **Basic** | ❌ | ❌ | ❌ | ❌ | None | ❌ (open by default) | ❌ | **Retired Sept 30, 2025** |
| **Standard** | ✅ (internal only) | ✅ | ✅ | Via Global tier | 99.99% [VERIFY] | ✅ (closed by default) | Via Gateway LB | — |
| **Gateway** | ✅ (HA ports only) | ❌ | ❌ | ❌ | see docs | N/A (private only) | ✅ (primary use case) | — |
| **Standard — Global tier** | ❌ | ❌ | N/A (anycast) | ✅ | see docs | ✅ | ❌ | — |

**Key Load Balancer service limits**

| Limit | Value | Notes |
|---|---|---|
| SNAT ports per public frontend IP | 64,000 [VERIFY] | Blocks of 8 ports consumed per rule |
| Default SNAT ports — pool 1–50 VMs | 1,024 per VM [VERIFY] | Capped regardless of additional frontend IPs |
| Default SNAT ports — pool 51–100 VMs | 512 per VM [VERIFY] | — |
| Default SNAT ports — pool 101–200 VMs | 256 per VM [VERIFY] | — |
| Default SNAT ports — pool 201–400 VMs | 128 per VM [VERIFY] | — |
| SNAT idle timeout | 4–120 minutes | Configurable via outbound rules |
| Standard LB SLA | 99.99% [VERIFY] | Requires ≥2 healthy backend instances |
| Health probe source IP | 168.63.129.16 | Allow in NSGs and host firewall |
| Health probe default interval | 5 seconds | — |
| Gateway LB tunnel interfaces per backend pool | 2 | External (untrusted in) + internal (trusted out) |
| Global LB health check to regional LBs | Every 5 seconds | — |

---

### Application Gateway SKUs

| SKU | WAF | Autoscale | Max instances | Max listeners | Max routing rules | Max backend pools | Max backends/pool | Zone-redundant | SLA |
|---|---|---|---|---|---|---|---|---|---|
| **Basic** *(preview)* | ❌ | ❌ | 5 [VERIFY] | 5 [VERIFY] | 5 [VERIFY] | 5 [VERIFY] | 5 [VERIFY] | ❌ | 99.9% [VERIFY] |
| **Standard_v2** | ❌ | ✅ (0–125) | 125 [VERIFY] | 100 [VERIFY] | 400 [VERIFY] | 100 [VERIFY] | 1,200 [VERIFY] | ✅ | 99.95% [VERIFY] |
| **WAF_v2** | ✅ OWASP CRS 3.1/3.0/2.2.9 | ✅ (0–125) | 125 [VERIFY] | 100 [VERIFY] | 400 [VERIFY] | 100 [VERIFY] | 1,200 [VERIFY] | ✅ | 99.95% [VERIFY] |

> ⚠️ **V1 (Standard and WAF) retired April 28, 2026.** No new V1 deployments since September 1, 2024. Migrate to v2 immediately.

**Key Application Gateway service limits**

| Limit | Value | Notes |
|---|---|---|
| Max instances (autoscale) | 125 [VERIFY] | 0 minimum = no reserved capacity; scale-out 3–5 min |
| Scale-in drain timeout | 5 minutes | Existing connections allowed to complete |
| Recommended subnet size (v2) | /24 | Ensures room for 125 instances + frontend IPs + Azure-reserved IPs |
| NSG inbound port range required (v2) | 65200–65535 | Not required for private-only deployment |
| Max trusted client CA chains per SSL profile | 100 [VERIFY] | mTLS strict mode |
| Max trusted client CA chains per gateway | 200 [VERIFY] | mTLS strict mode |
| Persistent connections per capacity unit | 2,500 [VERIFY] | v2 billing unit |
| Throughput per capacity unit | 2.22 Mbps (1 GB/hr) [VERIFY] | v2 billing unit |
| Min CUs per instance | 10 [VERIFY] | — |
| Max hostnames per multi-site listener | 5 [VERIFY] | — |
| TLS minimum version | TLS 1.2 | TLS 1.0/1.1 support ended August 31, 2025 [VERIFY] |

---

### Azure Front Door SKUs

| SKU | WAF custom rules | WAF managed rules (OWASP DRS) | Bot protection | Private Link origins | Base fee [VERIFY] | Retirement |
|---|---|---|---|---|---|---|
| **Standard** | ✅ | ❌ | ❌ | ❌ | ~$35/month/profile | — |
| **Premium** | ✅ | ✅ (DRS 2.1+) | ✅ | ✅ | ~$330/month/profile | — |
| **Classic** ⚠️ | ✅ | ✅ (DRS 1.1 only) | ✅ | ❌ | $0 base + per-routing-rule/hr | **Retiring March 31, 2027** |

> ⚠️ **Classic milestones:** No new Classic profiles since April 1, 2025. No new domain onboarding since August 15, 2025. Full retirement March 31, 2027.

**Key Front Door service limits**

| Limit | Value | Notes |
|---|---|---|
| Composite route limit per profile | 5,000 | Sum of (domains × paths) + (domains × rule overrides) |
| Origin priority range | 1–5 | Lower = higher priority |
| Origin weight range | 1–1,000 | Default 50 |
| Cache TTL maximum | 366 days | Governed by Cache-Control / Expires headers |
| Object chunking size | 8 MB | Requires origin to support byte-range requests |
| Private Link RPS limit | 7,200 RPS per regional cluster per profile [VERIFY] | Exceeding returns HTTP 429 |
| Custom domains (free tier) | First 100/month | Standard and Premium only |
| TLS minimum version | TLS 1.2 | TLS 1.0/1.1 not supported |
| Certificate auto-rotation | 45 days before expiry (Standard/Premium) [VERIFY] | Classic: 90 days; Classic managed certs no longer issued after Aug 15, 2025 |

---

### Traffic Manager

Traffic Manager has **no SKU tiers** — consumption-based billing (DNS queries, health probes, RUM, Traffic View).

| Limit | Value | Notes |
|---|---|---|
| DNS TTL minimum | 0 seconds [VERIFY] | All queries reach TM name servers |
| DNS TTL maximum | 2,147,483,647 seconds [VERIFY] | RFC-1035 maximum |
| Default DNS TTL | 300 seconds | Configurable per profile |
| Probe interval (standard) | 30 seconds [VERIFY] | Default |
| Probe interval (fast) | 10 seconds [VERIFY] | Additional billing applies |
| Tolerated failures before degraded | 0–9, default 3 [VERIFY] | — |
| Priority values range | 1–1,000 [VERIFY] | No duplicates allowed |
| Weighted values range | 1–1,000 [VERIFY] | Default 1 |
| Custom health-check headers | Up to 8 header:value pairs [VERIFY] | Per profile or endpoint |
| Expected status code ranges | Up to 8 ranges [VERIFY] | HTTP/HTTPS monitoring only |
| Web App endpoints per region per profile | 1 [VERIFY] | Workaround: use External endpoint type |
| Traffic View data window | Last 7 days | Updated every 48 h |

---

## Firewall & security

### Azure Firewall SKUs

| SKU | Target use case | Max throughput | Fat flow | Threat Intelligence | IDPS | TLS Inspection | URL Filtering | Forced Tunneling | Autoscale | Zone-redundant |
|---|---|---|---|---|---|---|---|---|---|---|
| **Basic** | SMB / essential protection | 250 Mbps [VERIFY] | N/A | Alert only | ❌ | ❌ | ❌ | ❌ | ❌ (fixed 2 instances) | ✅ |
| **Standard** | Enterprise L3–L7, centralized egress | 30 Gbps [VERIFY] | 1 Gbps | Alert + Deny | ❌ | ❌ | FQDN-level | ✅ | ✅ | ✅ |
| **Premium** | Regulated / deep inspection | 100 Gbps [VERIFY] | 10 Gbps | Alert + Deny | ✅ | ✅ (outbound + E-W) | Full URL path | ✅ | ✅ | ✅ |

> **Performance notes:** Initial out-of-the-box throughput (before autoscale): Standard ~3 Gbps, Premium ~18 Gbps [VERIFY]. IDPS in Alert+Deny mode reduces Premium effective throughput to **10 Gbps** for single-flow inspection [VERIFY]. Premium single TCP connection max: 9 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY].

**Key Azure Firewall service limits**

| Limit | Value | Notes |
|---|---|---|
| Max public IP addresses per firewall | 250 [VERIFY] | Basic supports fewer |
| SNAT ports per public IP | 2,496 [VERIFY] | Add PIPs or NAT Gateway to scale |
| Rule priority range | 100–65,000 | Lower number = higher priority |
| Max custom DNS servers | 15 [VERIFY] | Configured per firewall or policy |
| IDPS customizable signature overrides | Up to 10,000 [VERIFY] | Alert / Alert+Deny / Disabled per signature |
| IDPS signature library | 67,000+ signatures, 50+ categories | 20–40 new rules/day |
| Parallel IP Group updates | 20 at a time [VERIFY] | Per firewall policy or classic firewall |
| DNS cache TTL (positive) | Up to 1 hour | — |
| DNS cache TTL (negative) | Up to 30 minutes | — |
| Autoscale scale-out trigger | Avg throughput/CPU ≥60% or connections ≥80% | — |
| Autoscale scale-in trigger | Avg throughput, CPU, and connections <20% | — |
| TLS: exempt web categories | 4 (Education, Finance, Government, Health) | Not decrypted even in Premium |

---

### WAF on Application Gateway vs. Front Door

| Feature | App Gateway WAF_v2 | Front Door Standard | Front Door Premium | Front Door Classic |
|---|---|---|---|---|
| OWASP managed rule sets | CRS 3.1, 3.0, 2.2.9 | ❌ | DRS 2.1+ | DRS 1.1 only |
| Custom match rules | ✅ | ✅ | ✅ | ✅ |
| Custom rate limit rules | ✅ | ✅ | ✅ | ✅ |
| Bot protection | ✅ (custom rules) | ❌ (no managed bot rules) | ✅ (bot manager) | ✅ |
| Geo-filtering | ✅ | ✅ | ✅ | ✅ |
| Exclusion lists | ✅ | ✅ | ✅ | ✅ |
| Per-listener / per-path scope | ✅ | ❌ (per-profile) | ❌ (per-profile) | ❌ |
| Detection / Prevention modes | ✅ | ✅ | ✅ | ✅ |

---

### DDoS Protection tiers

| Tier | Scope | Cost model | Adaptive tuning | DDoS Rapid Response (DRR) | Cost protection | WAF discount | SLA-backed mitigation |
|---|---|---|---|---|---|---|---|
| **Infrastructure Protection** (free) | All Azure public IPs globally | Included, no charge | ❌ Basic only | ❌ | ❌ | ❌ | ❌ |
| **DDoS IP Protection** | Per public IP resource | Per-IP per month [VERIFY] | ✅ | ❌ | ❌ | ❌ | ✅ |
| **DDoS Network Protection** | Per VNet (plan covers all IPs in linked VNets) | Fixed monthly plan | ✅ | ✅ | ✅ | ✅ (App GW WAF billed at Standard_v2 rate) | ✅ |

> **Pricing breakeven:** IP Protection is more cost-effective for <10 public IPs; Network Protection becomes more cost-effective at ~10+ IPs [VERIFY].

**Key DDoS service limits**

| Limit | Value | Notes |
|---|---|---|
| Public IPs included per Network Protection plan | 100 [VERIFY] | Additional IPs incur overage charges |
| DDoS protection plans per tenant (recommended) | 1 | One plan links to VNets across all subscriptions/regions |
| Attack detection-to-mitigation time | 30–60 seconds [VERIFY] | Varies by attack type |
| Attack metric data retention | 30 days [VERIFY] | Via Azure Monitor |
| Mitigation policies per protected IP | 3 (TCP SYN, TCP, UDP) | Auto-tuned via ML |

> **Unsupported:** Virtual WAN resources, PaaS multitenant services outside VNet integration, public IPs on NAT Gateway, Classic/RDFE VMs.

---

## Network & access

### NAT Gateway SKUs

| Feature | **StandardV2** ✨ | **Standard** |
|---|---|---|
| Zone support | Zone-redundant (all AZs) | Zonal (single AZ only) |
| IPv6 | ✅ IPv4 + IPv6 | ❌ IPv4 only |
| Max bandwidth | 100 Gbps | 50 Gbps |
| Per-connection bandwidth | 1 Gbps | — |
| Packets per second | 10M total / 100K per connection | 5M |
| Max public IPs | 16 IPv4 + 16 IPv6 | 16 IPv4 |
| IP prefix support | /28 IPv4, /124 IPv6 | /28 IPv4 only |
| Flow logs | ✅ | ❌ |
| BYOIP (custom IP prefixes) | ❌ | ✅ |
| AKS managed NAT Gateway | ❌ (user-assigned only) | ✅ |

> **Recommendation:** Use **StandardV2** for all new deployments — zone-redundant by default, higher throughput, IPv6 support.

**Key NAT Gateway service limits**

| Limit | Value | Notes |
|---|---|---|
| Public IPs per NAT Gateway | 16 IPv4 (Standard) / 16 IPv4 + 16 IPv6 (V2) | — |
| Subnets per NAT Gateway | 800 | Share one gateway across entire VNet |
| SNAT ports per public IP | 64,512 | — |
| Max SNAT ports total | ~1,032,192 (16 IPs × 64,512) | — |
| Connections per IP per destination | 50,000 | — |
| Total concurrent connections | 2,000,000 | — |
| Idle TCP timeout | 4–120 minutes (default 4 min) | UDP: fixed 4 min |
| VNets per NAT Gateway | 1 | — |

---

### Private Link

Private Link has **no SKU tiers** — flat GA service. Relevant limits:

| Limit | Value | Notes |
|---|---|---|
| Private endpoints per VNet (standard) | 1,000 [VERIFY] | — |
| Private endpoints per VNet (High Scale, opt-in) | 5,000 [VERIFY] | One-time connection reset on enable/disable |
| Private endpoints across peered VNets (standard) | 4,000 [VERIFY] | Exceeding silently degrades connection health |
| Private endpoints across peered VNets (High Scale) | 20,000 [VERIFY] | — |
| NAT IP addresses per Private Link Service | 8 [VERIFY] | Each NAT IP adds more TCP port capacity |
| ASG members per NSG on PE subnet | 50 [VERIFY] | Exceeding 50 causes connection failures |
| PLS idle timeout | ~300 seconds (5 minutes) [VERIFY] | Implement TCP keepalives <300 s |
| PLS: backing Load Balancer SKU required | Standard only | Basic LB not supported |
| PLS: IPv6 support | ❌ IPv4 only | — |

**PaaS tier requirements for Private Endpoint support (selected services)**

| PaaS Service | Minimum tier required |
|---|---|
| Azure Container Registry | Premium tier [VERIFY] |
| Azure Service Bus | Premium tier [VERIFY] |
| Azure SignalR | Standard tier or above [VERIFY] |
| Azure Storage | GPv2 account only (not GPv1) [VERIFY] |
| Azure App Service | Basic, Standard, Premium v2/v3, Isolated v2, or Functions Premium [VERIFY] |

---

### Virtual WAN SKUs

| SKU | Connection types supported | Hub mesh (inter-hub) | VNet-to-VNet transit | ExpressRoute | P2S (User VPN) | NVA in hub | Routing Intent | Hub base fee |
|---|---|---|---|---|---|---|---|---|
| **Basic** | Site-to-site VPN only | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | $0.00/hr |
| **Standard** | S2S VPN, P2S VPN, ExpressRoute, VNet | ✅ Full mesh (automatic) | ✅ | ✅ | ✅ | ✅ | ✅ | $0.25/hr per hub [VERIFY] |

> Basic → Standard upgrade is **one-way**; cannot revert to Basic.

**Virtual WAN gateway scale units (Standard SKU)**

| Gateway type | 1 scale unit | Max scale units | Max throughput per hub | Notes |
|---|---|---|---|---|
| **S2S VPN** | 500 Mbps [VERIFY] | see docs | 20 Gbps [VERIFY] | Active-active dual-instance; up to 1,000 connections (2,000 IPsec tunnels) per hub |
| **ExpressRoute** | 2 Gbps [VERIFY] | 10 | 20 Gbps [VERIFY] | Max 4 circuits from same peering location, 8 from different |
| **User VPN (P2S)** | 500 Mbps / 500 users | 200 | 100 Gbps / 100,000 users [VERIFY] | Scale ≥40 requires multi-CIDR client address pool |

**Virtual WAN hub router (Routing Infrastructure Units)**

| RIUs | Router throughput | Max spoke VMs |
|---|---|---|
| 2 (default) | 3 Gbps | 2,000 |
| 3 | 3 Gbps | 3,000 |
| 4–50 | 1 Gbps per RIU | 1,000 per RIU |
| **50 (max)** | **50 Gbps** | **50,000** |

> Max routes: **10,000** regardless of RIU count. Single TCP flow hard-limited to **1.5 Gbps** [VERIFY]. Hub scaling takes up to 25 minutes.

> ⚠️ **[CONFLICT]** S2S pricing: source article shows $0.261/hr per scale unit in one section and $0.361/hr in another. Verify against current Azure pricing page before publishing.

---

## VNet and general limits

| Limit | Value | Notes |
|---|---|---|
| VNets per subscription per region | 1,000 [VERIFY] | Soft limit; can request increase |
| Subnets per VNet | 3,000 [VERIFY] | — |
| IPv4 subnet size | /29 (min) to /2 (max) | Azure reserves 5 IPs per subnet (first 4 + last 1) |
| IPv6 subnet size | Exactly /64 | Fixed; required for IPv6 dual-stack |
| Reserved IPs per subnet | 5 | First 4 addresses + last address |
| VNet peerings per VNet (default) | 500 [VERIFY] | — |
| VNet peerings per VNet (VNet Manager) | 1,000 [VERIFY] | — |
| NSG rules per NSG | 1,000 [VERIFY] | — |
| NSG rule priority range | 100–4,096 | Lower number = higher priority |
| Route tables (UDRs) per subscription per region | 200 [VERIFY] | — |
| Routes per route table (default) | 400 [VERIFY] | — |
| Routes per route table (VNet Manager) | 1,000 [VERIFY] | — |
| UDRs with service tag as prefix per table | 25 [VERIFY] | — |
| DNS servers per VNet | 20 [VERIFY] | — |
| Address spaces per VNet | see docs | Not stated in source articles |

---

## Retiring / deprecated SKUs

| SKU / Feature | Retirement date | Migration path |
|---|---|---|
| **Basic public IP** | September 30, 2025 | Upgrade to Standard public IP |
| **Basic Load Balancer** | September 30, 2025 | Migrate to Standard Load Balancer |
| **Application Gateway V1** (Standard + WAF v1) | April 28, 2026 | Migrate to Standard_v2 or WAF_v2 |
| **VPN Gateway Standard SKU** (legacy) | March 31, 2026 | Migrate to VpnGw1AZ |
| **VPN Gateway High Performance SKU** (legacy) | March 31, 2026 | Migrate to VpnGw2AZ |
| **Default outbound access for VMs** (new VNets) | March 31, 2026 | Use NAT Gateway (recommended), Standard LB outbound rules, or Azure Firewall |
| **Azure Front Door Classic** | March 31, 2027 | Zero-downtime migration tool available |
| **ExpressRoute public peering** | Already retired | Use Microsoft peering for M365/PaaS |
| **VPN Gateway Basic SKU** | Not announced — but limited; not recommended for production | Replace with VpnGw1 or higher for any production use |
| **TLS 1.0/1.1 — Application Gateway** | August 31, 2025 | Enforce TLS 1.2+ on clients |
| **TLS 1.0/1.1 — Traffic Manager** | February 28, 2025 | Enforce TLS 1.2+ on clients |
| **DHE cipher suites — Azure Front Door** | April 1, 2026 [VERIFY] | Remove TLS_DHE_RSA_WITH_AES_* dependencies |
| **Traffic View in Sovereign clouds** | March 15, 2025 | Use public cloud only |

---

## Related pages

- [Virtual Network](../services/virtual-network.md) — VNet fundamentals, subnets, NSGs, UDRs, peering
- [VPN Gateway](../services/vpn-gateway.md) — S2S, P2S, VNet-to-VNet encrypted connectivity
- [ExpressRoute](../services/expressroute.md) — Private dedicated connectivity, circuit SKUs, gateway SKUs
- [Azure Firewall](../services/azure-firewall.md) — Stateful NGFW with IDPS, TLS inspection, threat intelligence
- [Application Gateway](../services/application-gateway.md) — Regional L7 reverse proxy, WAF, TLS offload
- [Azure Load Balancer](../services/load-balancer.md) — Regional L4 pass-through load balancer
- [NAT Gateway](../services/nat-gateway.md) — Managed scalable outbound SNAT
- [Azure Front Door](../services/front-door.md) — Global CDN + WAF + anycast edge delivery
- [Traffic Manager](../services/traffic-manager.md) — DNS-based global traffic routing
- [Virtual WAN](../services/virtual-wan.md) — Managed global transit hub-and-spoke
- [DDoS Protection](../services/ddos-protection.md) — L3/L4 volumetric attack mitigation
- [Private Link](../services/private-link.md) — Private endpoints and Private Link Service
- [Azure subscription and service limits (Microsoft Docs)](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits) — Authoritative limits reference