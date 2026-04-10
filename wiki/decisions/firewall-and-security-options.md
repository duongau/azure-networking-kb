# Network Security: Decision Guide

> **Compiled:** 2026-04-10 | **Sources:** wiki/services/ pages (azure-firewall, web-application-firewall, ddos-protection, firewall-manager) + raw/articles/networking/security/ (4 articles) | **Status:** ✅ current

---

## The defense-in-depth stack

Each layer stops a distinct threat class. Deploy multiple layers — none is sufficient alone.

```
┌─────────────────────────────────────────────────────────────────────────┐
│  LAYER 1 — EDGE / VOLUMETRIC                                            │
│  Azure DDoS Protection (Network or IP Protection)                       │
│  Stops: L3/L4 volumetric floods (UDP amplification, TCP SYN, etc.)      │
│  Does NOT stop: L7 HTTP floods, SQLi, XSS, east-west lateral movement   │
├─────────────────────────────────────────────────────────────────────────┤
│  LAYER 2 — PERIMETER / NORTH-SOUTH + EAST-WEST                         │
│  Azure Firewall (Standard / Premium) OR third-party NVA                 │
│  Stops: L3–L7 egress, lateral movement, DNS exfiltration,               │
│         C2 callbacks (ThreatIntel), TLS-hidden malware (Premium IDPS),  │
│         unauthorized outbound FQDNs/URLs                                │
│  Does NOT stop: inbound L7 app attacks (WAF's job), volumetric DDoS     │
├─────────────────────────────────────────────────────────────────────────┤
│  LAYER 3 — APPLICATION / L7 INBOUND                                     │
│  WAF on App Gateway (regional) or WAF on Front Door (global edge)       │
│  Stops: OWASP Top 10 (SQLi, XSS, LFI, RFI, etc.), malicious bots,      │
│         L7 HTTP floods (HTTP DDoS Ruleset), rate abuse                  │
│  Does NOT stop: volumetric L3/L4, east-west, non-HTTP protocols         │
├─────────────────────────────────────────────────────────────────────────┤
│  LAYER 4 — SUBNET / NIC                                                 │
│  NSG (Network Security Group) + ASG (Application Security Group)        │
│  Stops: unauthorized L3/L4 flows between subnets or NICs;               │
│         micro-segmentation within a VNet                                │
│  Does NOT stop: L7 attacks, volumetric, FQDN-based filtering            │
├─────────────────────────────────────────────────────────────────────────┤
│  LAYER 5 — SERVICE ACCESS                                               │
│  Private Endpoints (Private Link)                                        │
│  Stops: public internet exposure of PaaS services; removes surface area │
│  Does NOT stop: threats from within the VNet itself (still need NSG)    │
└─────────────────────────────────────────────────────────────────────────┘
```

> **NSG vs ASG distinction:** An **NSG** is the actual policy object (allow/deny rules on ports, protocols, IPs) applied to a subnet or NIC. An **ASG** is a logical tag that groups VMs so they can be used as source/destination in NSG rules *without* enumerating IPs — both live at L3/L4 and are complementary, not competing.

---

## Quick-pick matrix

✅ = Covers this natively | ⚠️ = Partial / with caveats | ❌ = Not in scope

| Threat / Requirement | DDoS Protection | Azure Firewall Standard | Azure Firewall Premium | WAF (App Gateway) | WAF (Front Door) | NSG |
|---|---|---|---|---|---|---|
| **Volumetric DDoS (L3/L4)** | ✅ Always-on adaptive mitigation | ❌ Not designed for absorption | ❌ Not designed for absorption | ⚠️ HTTP DDoS Ruleset (L7 only, preview) | ⚠️ HTTP DDoS Ruleset (L7 only, limited preview) | ❌ |
| **L7 app attacks / OWASP Top 10** | ❌ L3/L4 only | ❌ No managed OWASP rules | ❌ No managed OWASP rules | ✅ DRS 2.1/2.2, CRS 3.2 | ✅ DRS 2.1/2.2 | ❌ |
| **East-west lateral movement** | ❌ | ✅ Route spoke-to-spoke through hub firewall | ✅ + IDPS inline | ❌ Inbound-only, regional | ❌ Edge-only | ✅ NSG between subnets/NICs |
| **DNS exfiltration** | ❌ | ✅ DNS proxy + FQDN network rules | ✅ DNS proxy + FQDN + IDPS DNS category | ❌ | ❌ | ❌ |
| **TLS inspection (outbound)** | ❌ | ❌ | ✅ Forward proxy, requires intermediate CA | ❌ (App GW does TLS termination, not inspection of egress) | ❌ | ❌ |
| **URL path filtering** | ❌ | ⚠️ FQDN-level (no path) | ✅ Full URL path (requires TLS inspection for HTTPS) | ✅ Custom rules + managed rules on URI path | ✅ Custom rules + managed rules on URI path | ❌ |
| **Bot protection** | ❌ | ❌ | ❌ | ✅ Bot Manager 1.0/1.1 (Bad/Good/Unknown) | ✅ Bot Manager 1.0/1.1 + JS Challenge + CAPTCHA | ❌ |
| **Zero Trust posture enforcement** | ⚠️ Reduces attack surface | ✅ Explicit egress allow-listing + ThreatIntel | ✅ IDPS + TLS + ThreatIntel + deny-by-default | ✅ Prevention mode + managed rules | ✅ Prevention mode + managed rules | ✅ Deny-by-default with explicit allows |
| **IDPS (signature-based IDS/IPS)** | ❌ | ❌ | ✅ 67,000+ signatures, Alert or Alert+Deny | ❌ | ❌ | ❌ |
| **Threat Intelligence feed blocking** | ❌ | ✅ Alert+Deny (Microsoft Cyber Security) | ✅ Alert+Deny (processed before all rules) | ⚠️ Via Bot Manager reputation | ⚠️ Via Bot Manager reputation | ❌ |
| **Rate limiting** | ❌ | ❌ | ❌ | ✅ Sliding window (1 or 5 min) on App GW WAF v2 | ✅ Fixed window (1 or 5 min) | ❌ |
| **Geo-blocking** | ❌ | ⚠️ Via IP Groups (no country code; manual CIDR lists) | ⚠️ Same as Standard | ✅ Geo-match custom rules | ✅ Geo-match custom rules | ❌ |
| **Multi-region / global coverage** | ✅ Per-VNet plan covers all regions | ❌ Per-region deployment | ❌ Per-region deployment | ❌ Regional | ✅ Global anycast edge PoPs | ❌ Per-VNet |

---

## Service summaries

### Azure DDoS Protection

| Attribute | Details |
|---|---|
| **Protects against** | Volumetric floods (UDP amplification, TCP SYN flood, reflection attacks); protocol attacks (L3/L4 only) |
| **OSI layer** | L3 / L4 |
| **What it does NOT protect** | L7 HTTP floods, SQLi, XSS; Virtual WAN resources; NAT Gateway public IPs; PaaS outside VNet integration |
| **SKUs** | Infrastructure Protection (free, no telemetry, no adaptive tuning); DDoS IP Protection (per-IP, no DRR/cost protection); DDoS Network Protection (per-VNet plan, DRR + cost protection + WAF discount) |
| **Detection-to-mitigation** | 30–60 seconds [VERIFY] |
| **Telemetry** | Azure Monitor metrics, attack analytics, 30-day retention [VERIFY]; Sentinel integration |

### Azure Firewall

| Attribute | Details |
|---|---|
| **Protects against** | Unauthorized north-south egress, east-west lateral movement, DNS exfiltration, C2 callbacks, TLS-hidden threats (Premium), signature-matched exploits (Premium IDPS) |
| **OSI layer** | L3–L7 (network rules = L3/L4; application rules = L7 HTTP/HTTPS/MSSQL) |
| **What it does NOT protect** | Inbound L7 application attacks (use WAF), volumetric DDoS absorption |
| **Rule processing order** | ThreatIntel → DNAT → Network → Application → Infrastructure allowlist → Implicit deny-all |
| **SKUs** | Basic (250 Mbps, no autoscale, alert-only ThreatIntel [VERIFY]); Standard (30 Gbps, autoscale, DNS proxy, web categories [VERIFY]); Premium (100 Gbps, IDPS, TLS inspection, URL filtering [VERIFY]) |
| **IDPS impact** | Alert+Deny mode caps effective throughput at **10 Gbps** [VERIFY]; single TCP flow max **300 Mbps with IDPS Alert+Deny** [VERIFY] |

### Web Application Firewall (WAF)

| Attribute | Details |
|---|---|
| **Protects against** | OWASP Top 10 (SQLi, XSS, LFI, RFI, protocol attacks), malicious bots, L7 rate abuse, HTTP DDoS (preview) |
| **OSI layer** | L7 (HTTP/HTTPS only) |
| **What it does NOT protect** | Non-HTTP protocols, east-west traffic, volumetric L3/L4 |
| **Deployment modes** | App Gateway WAF_v2 (regional, per-site/per-URI policies); Front Door Premium (global edge, per-domain policies); App Gateway for Containers (Kubernetes-native) |
| **Rule evaluation order** | HTTP DDoS Ruleset → Custom rules → Managed rule sets (DRS/CRS/Bot Manager) |
| **Modes** | Detection (log only) or Prevention (log + block); **Zero Trust requires Prevention mode** |

### Azure Firewall Manager

| Attribute | Details |
|---|---|
| **Protects against** | Control-plane drift; inconsistent policy across firewalls |
| **OSI layer** | Control plane only — manages Azure Firewall instances, not traffic |
| **Core value** | Single policy governs N firewalls across regions/subscriptions; hierarchical parent-child policies; secured virtual hub automation |
| **Architecture modes** | Hub Virtual Network (customer UDRs required); Secured Virtual Hub (automated BGP-based routing via Virtual WAN) |
| **Also manages** | WAF policies (Front Door + App Gateway), DDoS Protection plans |

### NSG + ASG

| Attribute | Details |
|---|---|
| **Protects against** | Unauthorized L3/L4 flows at subnet or NIC level; provides micro-segmentation within VNet |
| **OSI layer** | L3 / L4 |
| **NSG** | Policy object with inbound/outbound rules (allow/deny on port, protocol, source/destination IP or ASG); applied to subnet or NIC |
| **ASG** | Logical grouping of VM NICs; used as source/destination in NSG rules instead of explicit IPs; simplifies rule management at scale |
| **What it does NOT do** | FQDN filtering, deep packet inspection, L7 awareness, threat intelligence |
| **Cost** | Free (no per-byte charges unlike Azure Firewall) |

---

## Decision flowchart

```
START: What are you protecting?
│
├─► Public-facing web application (HTTP/HTTPS)?
│   ├─► Global, multi-region traffic?  ──► WAF on Front Door Premium
│   └─► Single-region, VNet-deployed?  ──► WAF on App Gateway (WAF_v2)
│       └─► Also need TLS termination + load balancing? ──► App Gateway + WAF_v2 (combined)
│
├─► Outbound / egress traffic from VMs or workloads?
│   ├─► Need TLS inspection, IDPS, URL filtering?  ──► Azure Firewall Premium
│   ├─► Need DNS proxy, web categories, threat intel? ──► Azure Firewall Standard
│   └─► Budget-constrained, SMB?  ──► Azure Firewall Basic
│
├─► East-west traffic between VNet spokes?
│   ├─► Hub-spoke with centralized inspection? ──► Azure Firewall (Standard or Premium) via UDRs
│   └─► Simple port-based allow/deny, no FQDN? ──► NSG (cheaper, zero data cost)
│
├─► Protecting against volumetric DDoS (L3/L4)?
│   ├─► <10 public IPs, no DRR needed? ──► DDoS IP Protection
│   └─► 10+ public IPs, enterprise, need DRR + cost protection? ──► DDoS Network Protection
│
├─► Managing firewalls across multiple subscriptions/regions?
│   └─► Azure Firewall Manager (hierarchical policies, secured virtual hub or hub VNet)
│
├─► Micro-segmenting workloads within a VNet at low cost?
│   └─► NSG with ASGs (group VMs logically, no IP management)
│
└─► Zero Trust posture for all of the above?
    └─► Layer all: DDoS Network Protection + Azure Firewall Premium + WAF (App GW or Front Door)
                   + NSGs + Private Endpoints (to eliminate public PaaS surface)
```

---

## Head-to-head comparisons

### Azure Firewall Standard vs Premium

| Feature | Standard | Premium |
|---|---|---|
| **IDPS** | ❌ | ✅ 67,000+ signatures, 50+ categories, 20–40 new rules/day |
| **IDPS mode** | N/A | Alert (passive, log only) or Alert+Deny (inline block) |
| **IDPS Alert+Deny throughput impact** | N/A | Max **10 Gbps** aggregate [VERIFY]; single TCP flow max **300 Mbps** [VERIFY] |
| **TLS inspection** | ❌ | ✅ Outbound + east-west forward proxy; requires intermediate CA cert |
| **Inbound TLS inspection** | ❌ | ❌ (use App Gateway WAF for inbound) |
| **URL filtering (full path)** | ❌ | ✅ Full URL path (e.g. `example.com/path/page`); requires TLS inspection for HTTPS |
| **Web categories** | ✅ FQDN-level (e.g., block gambling.com) | ✅ Full URL-level (block gambling.com/specific-page) |
| **Threat Intelligence** | ✅ Alert or Alert+Deny | ✅ Alert or Alert+Deny (same feed, processed first) |
| **DNS proxy** | ✅ | ✅ |
| **Max throughput** | 30 Gbps [VERIFY] | 100 Gbps [VERIFY] (10 Gbps effective with IDPS Alert+Deny) [VERIFY] |
| **Fat flow max** | 1 Gbps | 10 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY] |
| **PCI DSS compliance** | ❌ | ✅ [VERIFY] |
| **Relative cost** | Lower | Higher (~2× Standard for compute; IDPS incurs additional charges) |
| **When to choose** | Enterprise egress filtering, threat intel, DNS proxy — no regulatory deep inspection requirement | Regulated workloads (PCI DSS, HIPAA), payment processing, encrypted traffic inspection, signature-based IPS required |

---

### WAF on App Gateway vs WAF on Front Door

| Feature | WAF on App Gateway (WAF_v2) | WAF on Front Door Premium |
|---|---|---|
| **Scope** | Regional (single Azure region) | Global anycast edge (all Front Door PoPs) |
| **Underlying delivery resource** | Application Gateway (L7 load balancer + TLS termination) | Azure Front Door (global CDN + anycast) |
| **Traffic handled** | HTTP/HTTPS only; VNet-integrated | HTTP/HTTPS only; internet-facing, non-VNet |
| **Supported managed rule sets** | CRS 3.0 / 3.1 / 3.2, DRS 2.0 / 2.1 / 2.2, Bot Manager 1.0 / 1.1 | DRS 2.0 / 2.1 / 2.2, Bot Manager 1.0 / 1.1 |
| **CRS support** | ✅ CRS 3.2 (legacy OWASP); CRS 3.0/3.1 EOL **2027-02-26** | ❌ DRS only |
| **DRS (Default Rule Set)** | ✅ DRS 2.1/2.2 (current recommended) | ✅ DRS 2.1/2.2 (current recommended) |
| **Anomaly scoring** | ✅ (default for CRS / DRS); block threshold ≥ 5 | ✅ Same threshold |
| **Bot Manager** | ✅ 1.0 / 1.1 (3-tier: Bad/Good/Unknown) | ✅ 1.0 / 1.1 |
| **JS Challenge** | ✅ Preview | ✅ Front Door Premium + Bot Manager 1.x |
| **CAPTCHA** | ❌ | ✅ Front Door only; usage-based charges [VERIFY] |
| **HTTP DDoS Ruleset** | ✅ Preview (24 h learning period) | ✅ Limited preview (24–36 h learning period) |
| **Rate limiting** | ✅ Sliding window, 1 or 5 min; group by ClientAddr / GeoLocation / XFF | ✅ Fixed window, 1 or 5 min |
| **Per-site / per-URI WAF policy** | ✅ (WAF_v2 only) | ✅ Per-domain policy |
| **Custom rules max** | 100 per policy [VERIFY] | 100 per policy [VERIFY] |
| **DDoS Network Protection WAF discount** | ✅ Billed at Standard_v2 rate when VNet has Network Protection | ❌ Not applicable |
| **Cost model** | Hourly gateway fee + capacity units (CU) | Usage-based (requests + data transfer) |
| **When to choose** | Regional app behind VNet; need VNet integration; existing App Gateway deployment; per-URI WAF granularity | Global app delivered via Front Door; need global edge WAF; multiple origin regions; CAPTCHA challenges; CDN caching + WAF combined |

---

### Azure Firewall vs Third-Party NVA

| Feature | Azure Firewall (Standard/Premium) | Third-Party NVA (Azure Marketplace) |
|---|---|---|
| **Management model** | Fully managed PaaS; no VMs to patch | Customer-managed VMs (BYO license + config) |
| **High availability** | Built-in; multi-zone with AZ deployment; no extra HA config | Customer-configured (Active-Passive or Active-Active; load balancer required) |
| **Autoscaling** | Native autoscale (scale-out at 60% avg throughput/CPU) | Manual VMSS scaling or custom autoscale; takes minutes |
| **IDPS** | ✅ Premium: 67,000+ Microsoft-sourced signatures | Varies; typically richer signature libraries (Check Point, Palo Alto, Fortinet) |
| **TLS inspection** | ✅ Premium: outbound + east-west | ✅ Most enterprise NVAs; bidirectional |
| **Inbound TLS inspection** | ❌ | ✅ Supported by most NVAs |
| **Feature depth** | Deliberately bounded; FQDN/URL/IDPS/TLS/ThreatIntel | Deeper feature parity with on-prem appliances (SD-WAN, advanced DLP, sandbox, etc.) |
| **Virtual WAN integration** | Native (secured virtual hub via Firewall Manager) | Spoke only (not in hub); no automated BGP routing |
| **Firewall Manager policy** | ✅ Native hierarchical policies | ❌ Proprietary management plane |
| **Azure Monitor / Sentinel** | Native structured log schema; Sentinel workbooks | Custom connector / Syslog forwarding |
| **Latency** | Measured in ms; no packet-by-packet user control | Can be lower at line-rate with SR-IOV |
| **Support** | Microsoft Support | NVA vendor support (+ Azure platform support) |
| **Cost model** | Deployment hours + data processed | VM + NVA license + egress charges; often higher at scale |
| **When to choose Azure Firewall** | Azure-native workloads; centralized policy via Firewall Manager; Virtual WAN; no on-prem parity requirement | Regulatory mandates for specific appliance; inbound TLS inspection required; deep DLP/sandbox; existing vendor relationship with Azure Marketplace NVA |

---

## Zero Trust network pattern

Zero Trust assumes breach: every request is verified, every path is inspected, lateral movement is minimized. The five layers map directly to Zero Trust principles:

### Recommended Zero Trust stack

```
Internet
    │
    ▼
[DDoS Network Protection]          ← "Assume breach" at the edge; absorb volumetric
    │
    ▼
[WAF on Front Door Premium]        ← "Verify explicitly" for global web traffic;
    │                                 Prevention mode, DRS 2.1+, Bot Manager, JS Challenge
    ▼
[Azure Firewall Premium]           ← "Verify explicitly" for east-west + egress;
    │  (hub VNet or Virtual WAN)      ThreatIntel deny, IDPS Alert+Deny, TLS inspection,
    │                                 URL filtering; deny-all default
    ▼
[NSG + ASG]                        ← "Use least privilege access"; subnet and NIC level;
    │                                 deny-by-default; ASGs for workload grouping
    ▼
[Private Endpoints]                ← "Reduce attack surface"; PaaS accessed over private
                                      IP only; eliminates public endpoint exposure
```

### Zero Trust checklist (from source articles)

**DDoS Protection (risk: High)**
- [ ] DDoS Protection enabled for all public IPs in VNets
- [ ] Metrics enabled for DDoS-protected public IPs
- [ ] Diagnostic logging enabled for DDoS-protected public IPs

**Azure Firewall (risk: High for all)**
- [ ] All outbound VNet traffic routed through Azure Firewall (UDR or Virtual WAN routing intent)
- [ ] Threat Intelligence set to **deny mode** (not just alert)
- [ ] IDPS set to **Alert+Deny** mode (Premium only)
- [ ] Outbound TLS inspection enabled (Premium only)
- [ ] Diagnostic logging enabled (stream to Log Analytics / Sentinel)

**App Gateway WAF (risk: High for all)**
- [ ] WAF in **Prevention mode** (not Detection)
- [ ] Request body inspection enabled
- [ ] Default Rule Set (DRS 2.1+ or CRS 3.2) enabled
- [ ] Bot Manager rule set enabled
- [ ] HTTP DDoS protection rule set enabled (preview)
- [ ] Rate limiting rules configured
- [ ] JS Challenge enabled for bot-heavy workloads
- [ ] Diagnostic logging enabled

**Front Door WAF (risk: High for all)**
- [ ] WAF in **Prevention mode**
- [ ] Request body inspection enabled
- [ ] DRS 2.1+ assigned
- [ ] Bot Manager rule set assigned
- [ ] Rate limiting rules configured
- [ ] JS Challenge and CAPTCHA enabled (Front Door Premium)
- [ ] Diagnostic logging enabled

### Why all layers together

No single service implements Zero Trust alone:
- **Firewall Premium alone**: can't stop OWASP app-layer attacks in inbound HTTP; no volumetric absorption
- **WAF alone**: doesn't inspect east-west or non-HTTP; no IDPS
- **DDoS alone**: only L3/L4; HTTP floods pass through
- **NSGs alone**: no FQDN awareness, no threat intelligence, no L7 inspection
- **Private Endpoints alone**: reduces surface area but doesn't inspect traffic *within* the private path

---

## Limits & SKU summary

| Service | SKU / Tier | Key throughput limit | Key rule/policy limit | Notes |
|---|---|---|---|---|
| **DDoS Protection** | Infrastructure (free) | Platform-level only | — | No adaptive tuning, no telemetry |
| **DDoS Protection** | IP Protection | Per-IP adaptive tuning | 1 plan per IP | No DRR, no cost protection |
| **DDoS Protection** | Network Protection | Per-IP adaptive tuning | 100 public IPs per plan [VERIFY] | DRR + cost protection + WAF discount |
| **Azure Firewall** | Basic | 250 Mbps [VERIFY] | No autoscale (fixed 2 instances) | Alert-only ThreatIntel; no DNS proxy; no forced tunneling |
| **Azure Firewall** | Standard | 30 Gbps [VERIFY] | 250 public IPs [VERIFY]; SNAT 2,496 ports/PIP [VERIFY] | Autoscales; DNS proxy; web categories (FQDN-level) |
| **Azure Firewall** | Premium | 100 Gbps [VERIFY] (10 Gbps with IDPS Alert+Deny) [VERIFY] | 10,000 IDPS signature overrides [VERIFY] | TLS inspection; URL filtering; IDPS 67,000+ sigs |
| **WAF (App Gateway)** | WAF_v2 | App GW v2 max 125 RCU [VERIFY] | 100 custom rules/policy [VERIFY] | Per-site/per-URI policies; CRS + DRS; sliding-window rate limit |
| **WAF (Front Door)** | Front Door Premium | Global anycast | 100 custom rules/policy [VERIFY] | DRS only (no CRS); CAPTCHA; fixed-window rate limit |
| **Firewall Manager** | — | Control plane only | 1 parent policy → unlimited children | Free ≤1 policy association; charged per additional association [VERIFY] |
| **NSG** | — | No throughput limit | 1,000 rules per NSG [VERIFY] | Free; no data processing charges |

---

## Related pages

- [Azure Firewall](../services/azure-firewall.md) — Full capability reference, SKU details, rule processing order, DNS proxy, TLS inspection, forced tunneling
- [Web Application Firewall](../services/web-application-firewall.md) — Full WAF reference: all rule sets, custom rules, exclusions, architecture patterns, DRS/CRS versions, bot protection
- [Azure DDoS Protection](../services/ddos-protection.md) — L3/L4 DDoS tiers, SKU comparison, limits, simulation testing, inline L7 architecture
- [Azure Firewall Manager](../services/firewall-manager.md) — Centralized policy management, hierarchical policies, secured virtual hub vs hub VNet, SECaaS integration
- [Virtual WAN](../services/virtual-wan.md) — Required reading for secured virtual hub deployments
- [Private Link](../services/private-link.md) — Eliminating public surface area for PaaS services; complements defense-in-depth
- [Application Gateway](../services/application-gateway.md) — WAF host platform for regional deployments; TLS termination; L7 load balancing
- [Network Watcher](../services/network-watcher.md) — NSG flow logs, connection troubleshooting, packet capture for security investigation

---

## Source articles

| Article | Location | Notes |
|---|---|---|
| Azure Firewall wiki | `wiki/services/azure-firewall.md` | Compiled 2025-07-14; 86 source articles |
| Web Application Firewall wiki | `wiki/services/web-application-firewall.md` | Compiled 2026-04-10; 77 source articles |
| DDoS Protection wiki | `wiki/services/ddos-protection.md` | Compiled 2026-04-08; 32 source articles |
| Firewall Manager wiki | `wiki/services/firewall-manager.md` | Compiled 2026-04-10; 27 source articles |
| Azure network security overview | `raw/articles/networking/security/network-security.md` | 2025-06-24 |
| Zero Trust network security recommendations | `raw/articles/networking/security/zero-trust-network-security.md` | 2026-03-17 |
| Zero Trust — Azure Firewall | `raw/articles/networking/security/zero-trust-azure-firewall.md` | 2026-03-17 |
| Zero Trust — App Gateway WAF | `raw/articles/networking/security/zero-trust-application-gateway-waf.md` | 2026-03-17 |