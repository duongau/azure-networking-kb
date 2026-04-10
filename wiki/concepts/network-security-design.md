# Network Security Design in Azure

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

---

## Defense-in-depth model

Azure network security is structured as a layered stack. Each layer is independent — a failure or bypass at one layer is contained by the layers below it. Design every workload with at least three layers active.

```
┌─────────────────────────────────────────────────────────┐
│  Layer 1 — EDGE                                         │
│  DDoS Protection (Network or IP)                        │
│  Absorbs volumetric L3/L4 attacks before they saturate  │
│  your public IPs. Always-on, adaptive ML tuning.        │
├─────────────────────────────────────────────────────────┤
│  Layer 2 — PERIMETER                                    │
│  Azure Firewall (Standard / Premium) or NVA             │
│  Stateful L3–L7 inspection. North-south (internet)      │
│  and east-west (spoke-to-spoke) enforcement.            │
│  FQDN filtering, threat intel, TLS inspection (Premium).│
├─────────────────────────────────────────────────────────┤
│  Layer 3 — APPLICATION                                  │
│  Web Application Firewall (App Gateway WAF / FD WAF)    │
│  OWASP/L7 attack filtering for HTTP/S workloads.        │
│  SQLi, XSS, bot protection, rate limiting, geo-block.   │
├─────────────────────────────────────────────────────────┤
│  Layer 4 — NETWORK                                      │
│  NSGs + ASGs                                            │
│  Stateful L4 allow-listing per subnet and NIC.          │
│  Last line of defense inside the VNet perimeter.        │
├─────────────────────────────────────────────────────────┤
│  Layer 5 — SERVICE ACCESS                               │
│  Private Endpoints (Private Link)                       │
│  PaaS resources served over private IPs only.           │
│  Eliminates public internet exposure of data plane.     │
└─────────────────────────────────────────────────────────┘
```

| Layer | Primary service | Attack surface addressed |
|---|---|---|
| Edge | DDoS Protection | Volumetric floods (UDP, SYN, TCP, ICMP) |
| Perimeter | Azure Firewall / NVA | Unauthorized L3–L7 connections, C&C callbacks, lateral movement |
| Application | WAF (App Gateway / Front Door) | OWASP Top 10, SQLi, XSS, bots, L7 DDoS |
| Network | NSG + ASG | Unauthorized port/protocol access within VNet |
| Service access | Private Endpoints | Public internet exposure of PaaS data planes |

> **Key principle:** Each layer must be explicitly configured — none are on by default for a new VNet. DDoS infrastructure protection (free tier) is the sole automatic control.

---

## NSGs and ASGs

### Network Security Groups (NSGs)

NSGs are **stateful Layer-4 ACLs** applied at subnet level, NIC level, or both. They define allow/deny rules evaluated by priority order.

| Property | Details |
|---|---|
| Statefulness | Fully stateful — return traffic is automatically allowed for established connections |
| Rule priority range | 100–4,096 (lower number = higher priority; first match wins) [VERIFY] |
| Default rules | 3 built-in rules at priority 65000–65500; cannot be removed but can be overridden |
| Default rule — `AllowVnetInBound` | Allows **all** traffic between addresses in the VNet address space and connected VNets |
| Default rule — `AllowAzureLoadBalancerInBound` | Allows Azure LB health probe traffic |
| Default rule — `DenyAllInBound` | Denies all other inbound traffic |
| Augmented rules | A single rule can specify multiple source/destination IP prefixes or port ranges — reducing total rule count |
| Effective rules | When NSG applied to both subnet and NIC: inbound = subnet NSG first, then NIC NSG; outbound = NIC NSG first, then subnet NSG |

**Best practice:** Apply NSGs at the subnet level for consistency. Use per-NIC NSGs only when VMs in the same subnet have meaningfully different access requirements. Per-NIC NSGs create troubleshooting complexity.

### Application Security Groups (ASGs)

ASGs replace IP-based NSG rules with **logical group memberships**. Instead of `Source: 10.0.1.0/24`, you write `Source: AsgWeb`.

| Property | Details |
|---|---|
| Membership | Assign a VM NIC to one or more ASGs |
| Cross-VNet restriction | All NICs in an ASG must reside in the same VNet |
| Rule reference | ASGs referenced as source or destination in NSG rules |
| Advantage over IP rules | Scales with fleet changes — add/remove VMs without editing NSG rule IPs |
| Limit | 50 ASG members per NSG on a PE subnet [VERIFY] — exceeding this silently causes connection failures |

**Example pattern:** `AsgWeb → AsgApp on port 8080 Allow`, `AsgApp → AsgDb on port 1433 Allow`. No IP management required.

### Service Tags

Microsoft-managed named groups of Azure service IP ranges. Use in NSG rules instead of hardcoding IP prefixes.

| Tag | Covers |
|---|---|
| `VirtualNetwork` | All VNet address space + connected networks |
| `AzureLoadBalancer` | Azure health probe source IPs |
| `Internet` | All public IP addresses outside VNet space |
| `AzureCloud` | All Azure datacenter IPs (region-scoped variants available, e.g., `AzureCloud.WestEurope`) |
| `Storage` | Azure Storage public IPs (region-scoped variants available) |
| `Sql` | Azure SQL public IPs |
| `AzureMonitor` | Azure Monitor + Log Analytics + App Insights public IPs |
| `AppService` | App Service outbound IPs |

Azure updates service tag IP lists automatically — no operator intervention required.

### NSG Flow Logs and Traffic Analytics

| Feature | Details |
|---|---|
| **NSG flow logs v2** | Per-flow records: 5-tuple, action, bytes, packets; written to Azure Storage |
| **Traffic Analytics** | Processes flow logs; visualizes top talkers, open ports, geo-traffic, malicious flows in Log Analytics / Sentinel |
| **VNet flow logs** | Newer alternative to NSG flow logs; captures all flows at VNet level without per-NSG configuration; preferred for new deployments |
| Retention | Configurable up to 90 days in storage; use Log Analytics for long-term retention |

---

## Azure Firewall placement patterns

### Pattern 1: Centralized hub firewall (recommended)

Deploy a single Azure Firewall in the hub VNet. All east-west (spoke-to-spoke) and north-south (internet ingress/egress) traffic is routed through it via UDRs on spoke subnets.

```
  On-premises ──► Hub VNet (Azure Firewall) ◄──► Spoke A
                         │                 ◄──► Spoke B
                    Internet                ◄──► Spoke C
```

- **UDR required:** Each spoke subnet needs a route table with `0.0.0.0/0 → Azure Firewall private IP` for internet egress, and RFC 1918 routes pointing to Firewall for east-west traffic.
- **Benefit:** Single policy enforcement point; centralized logging; Firewall Manager for multi-subscription governance.
- **Scale:** Standard Firewall autoscales to 30 Gbps aggregate throughput [VERIFY]; Premium to 100 Gbps [VERIFY].

### Pattern 2: Hub in Azure Virtual WAN (Secured Virtual Hub)

Azure Firewall deployed directly into a Virtual WAN hub (Secured Virtual Hub). Routing Intent automates the UDR configuration across all connected branches and spokes.

- Use Routing Intent for centralized internet breakout **and** private traffic inspection through the Firewall.
- Eliminates manual UDR management for branch offices.
- Best for large-scale, multi-region topologies.

### Pattern 3: Internet breakout — centralized vs. local

| Model | Description | Trade-offs |
|---|---|---|
| **Centralized (hub)** | All internet traffic hairpins through hub Firewall | Single inspection point; all egress logs aggregated; adds latency for spokes far from hub |
| **Local breakout (VWAN with Routing Intent)** | Spokes break out to internet locally; Firewall in each VWAN hub region | Lower latency; requires Firewall in each region; higher cost |

### Pattern 4: Forced tunneling through on-premises NVA

Route all Azure internet-bound traffic to an on-premises or third-party NVA rather than directly to the internet.

- **Requirement:** Firewall must be deployed with `--enable-forced-tunnel` flag and a **management NIC** (separate interface for Firewall control plane).
- **DNAT incompatibility:** DNAT rules are not supported when forced tunneling is enabled (asymmetric routing). Exception: firewalls with a Management NIC.
- **SNAT behavior:** Configure `0.0.0.0/0` as a private SNAT range to prevent the Firewall from SNATing internet-bound traffic to its own IP before handing off.

### Firewall rule processing order (reference)

1. Threat Intelligence (all SKUs) — before all other rules
2. DNAT rules
3. Network rules
4. Application rules (HTTP/HTTPS/MSSQL)
5. Infrastructure rule collection (built-in Azure platform FQDNs)
6. Implicit deny-all

---

## WAF deployment patterns

### Pattern 1: WAF on Application Gateway (regional, private + public)

| Property | Details |
|---|---|
| Scope | Regional — inspects traffic entering a specific region |
| Exposure | Public-facing or internal (private frontend IP supported) |
| SKU required | Application Gateway WAF_v2 (recommended); WAF_v1 is legacy, avoid for new deployments |
| Rule sets | DRS 2.x (recommended), CRS 3.2, Bot Manager 1.0/1.1, HTTP DDoS Ruleset (preview) |
| Best for | Regional web applications, private internal APIs, workloads where traffic must not leave the region for inspection |

### Pattern 2: WAF on Azure Front Door (global edge)

| Property | Details |
|---|---|
| Scope | Global — inspects traffic at Microsoft's edge PoPs before it enters any Azure region |
| Exposure | Public only (Front Door is a public service) |
| SKU required | Front Door Premium (full WAF: DRS, Bot Manager, JS Challenge, CAPTCHA); Standard = custom rules only |
| Rule sets | DRS 2.x, Bot Manager 1.1, HTTP DDoS Ruleset (limited preview) |
| Best for | Globally distributed applications, global DDoS + bot filtering before traffic hits any origin, latency-sensitive content |

### Pattern 3: WAF on CDN (legacy — do not use for new deployments)

Azure CDN WAF preview has closed to new customers. Migrate existing deployments to Azure Front Door WAF.

### Pattern 4: Layered WAF — Front Door (global) + App Gateway (regional)

The most defense-in-depth L7 pattern for public web applications:

```
Internet ──► Front Door WAF (global L7 filter + CDN) ──► App Gateway WAF (regional L7 filter) ──► Backend
```

- Front Door WAF handles global volumetric threats, bot mitigation, and geo-blocking at the edge.
- App Gateway WAF provides regional inspection with per-site or per-URI WAF policies for fine-grained control.
- Private Link origin on Front Door ensures App Gateway is reachable only from Front Door, not directly from the internet.

> **Important:** WAF in **Detection mode** logs but does **not** block. Always switch to **Prevention mode** for production workloads. Detection mode is only appropriate for initial tuning/baselining.

### WAF anomaly scoring (DRS / CRS rule sets)

| Severity | Anomaly score |
|---|---|
| Critical | 5 |
| Error | 4 |
| Warning | 3 |
| Notice | 2 |

Block threshold: cumulative score ≥ 5. A single Critical match blocks the request.

---

## Zero Trust network principles

The Zero Trust model assumes no network or device is inherently trusted. Every connection is verified based on identity, data, and context.

### Three core principles, applied to Azure networking

| Principle | What it means | Azure implementation |
|---|---|---|
| **Verify explicitly** | Authenticate and authorize every connection; never assume trust based on network location | Microsoft Entra Conditional Access integration; identity-based firewall policies; mutual TLS for service-to-service |
| **Use least privilege** | Grant only the minimum access required; limit blast radius | NSG + ASG allow-listing (deny by default); Private Endpoints (instance-scoped, not service-scoped); Firewall application rules (FQDN, not IP range) |
| **Assume breach** | Segment the network so a compromised resource cannot reach everything else; monitor and log all flows | Micro-segmentation via NSGs/ASGs; Firewall east-west inspection; VNet flow logs; NSG flow logs + Traffic Analytics; Sentinel SIEM integration |

### Applied controls mapping

| Zero Trust control | Azure mechanism | Layer |
|---|---|---|
| Micro-segmentation | NSGs with per-ASG rules; separate VNets per workload tier | Network |
| Eliminate public PaaS exposure | Private Endpoints; disable public access on storage accounts, SQL, Key Vault | Service access |
| East-west traffic inspection | Azure Firewall (Standard/Premium) with UDRs forcing spoke-to-spoke traffic through hub Firewall | Perimeter |
| Outbound TLS decryption | Azure Firewall Premium TLS inspection + IDPS | Perimeter |
| Identity-based access | Microsoft Entra Conditional Access; Azure AD-joined devices; RBAC on network resources | Identity |
| Continuous monitoring | DDoS diagnostics; Firewall logs to Sentinel; NSG flow logs + Traffic Analytics; WAF diagnostics | Monitoring |

### Zero Trust hardening checklist — per service (from official Zero Trust recommendations, updated 2026-03-17)

An automated assessment of these controls is available via the [Zero Trust Assessment](/security/zero-trust/assessment) tool, which evaluates your Azure environment's configuration programmatically across these checks.

#### Azure DDoS Protection

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| DDoS Protection enabled for all public IPs in VNets | High | Low | Low |
| Metrics enabled for DDoS-protected public IPs | Medium | Low | Low |
| Diagnostic logging enabled for DDoS-protected public IPs | Medium | Low | Low |

> Without DDoS Protection, public IPs for Application Gateways, Load Balancers, Azure Firewalls, Bastion, VPN Gateways, and VMs remain exposed to attacks that can exhaust bandwidth and cause cascading outages.

#### Azure Firewall

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| Outbound VNet traffic routed through Azure Firewall | High | Low | Medium |
| Threat Intelligence enabled in Deny mode | High | Low | Low |
| IDPS inspection enabled in Deny mode *(Premium only)* | High | Low | Low |
| Outbound TLS inspection enabled *(Premium only)* | High | Low | Low |
| Diagnostic logging enabled | High | Low | Low |

> **Threat Intelligence:** Requires Standard or Premium; Basic supports Alert mode only.
> **IDPS:** Signature-based L3–L7 detection; applies to inbound, spoke-to-spoke, and outbound traffic including on-premises traffic over VPN/ER; signatures continuously updated by Microsoft.
> **TLS inspection:** Requires a CA certificate stored in Azure Key Vault; decrypts, inspects, and re-encrypts; enables IDPS to see encrypted payloads.
> **SNAT note:** For high-traffic workloads at risk of SNAT port exhaustion, deploy NAT Gateway on the AzureFirewallSubnet — NAT Gateway provides 64,512 SNAT ports per public IP vs. Azure Firewall's 2,496 SNAT ports per public IP per instance.

#### Application Gateway WAF

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| WAF enabled in Prevention mode | High | Low | Low |
| Request body inspection enabled | High | Low | Low |
| Default rule set (DRS/CRS) enabled | High | Low | Low |
| Bot protection rule set enabled | High | Low | Low |
| HTTP DDoS protection rule set enabled | High | Low | Low |
| Rate limiting configured | High | Low | Medium |
| JavaScript challenge enabled | Medium | Low | Low |
| Diagnostic logging enabled | High | Low | Low |

> **Request body inspection:** When disabled, attackers can embed SQLi/XSS/command injection in POST/PUT/PATCH bodies, bypassing all rule evaluation.
> **HTTP DDoS rule set:** Distinct from DDoS Network/IP Protection; detects HTTP flood and Slowloris attacks at the application layer.
> **JavaScript challenge:** Proves request originates from a real browser; blocks credential-stuffing bots and scrapers without user-visible friction.

#### Azure Front Door WAF

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| WAF enabled in Prevention mode | High | Low | Low |
| Request body inspection enabled | High | Low | Low |
| Default rule set assigned | High | Low | Low |
| Bot protection rule set enabled | High | Low | Low |
| Rate limiting configured | High | Low | Medium |
| JavaScript challenge enabled | Medium | Low | Low |
| CAPTCHA challenge enabled | Medium | Low | Low |
| Diagnostic logging enabled | High | Low | Low |

> **CAPTCHA challenge (Front Door only):** Presents interactive challenge for requests that JavaScript challenge cannot fully classify; blocks sophisticated bots that can execute JavaScript.

---

## DDoS Protection tiers

### Tier comparison

| Tier | Scope | Pricing model | Adaptive tuning | DRR | Cost protection | WAF discount |
|---|---|---|---|---|---|---|
| **Infrastructure Protection** (free) | All Azure public IPs globally | Included, no cost | No | No | No | No |
| **DDoS IP Protection** | Per public IP resource | Per-IP per month [VERIFY] | Yes | No | No | No |
| **DDoS Network Protection** | Per VNet (plan covers all IPs in linked VNets, up to 100 IPs included) [VERIFY] | Fixed monthly plan fee [VERIFY] | Yes | Yes | Yes | Yes (App GW WAF billed at Standard_v2 rate) |

### When to upgrade from the free tier

| Trigger | Recommended tier |
|---|---|
| Any public-facing app that needs SLA-backed protection and telemetry | IP Protection (minimum) |
| < 10 public IPs, no DRR or cost protection required | **DDoS IP Protection** (lower total cost) |
| ≥ 10 public IPs, enterprise scale, regulated workload, or DRR needed | **DDoS Network Protection** |
| Application Gateway WAF deployed in same VNet | **DDoS Network Protection** (WAF discount offsets plan cost) |
| Hub-and-spoke topology | Enable Network Protection on hub VNet; all public IPs (Firewall, Bastion, VPN GW) are covered |

### What DDoS Protection does NOT cover

- **Azure Virtual WAN resources** — not supported
- **PaaS multitenant services outside VNet** — protection only applies to VNet-deployed public IPs
- **Public IPs attached to NAT Gateway** — explicitly unsupported
- **L7 attacks** (HTTP floods, Slowloris, SQLi) — not in scope; use WAF for L7 protection
- **VPN Gateway adaptive tuning** — protection applies but ML-based per-IP tuning is not available for this resource type

### Detection and mitigation

| Metric | Value |
|---|---|
| Monitoring | Always-on, 24/7 |
| Detection-to-mitigation time | 30–60 seconds [VERIFY] |
| Mitigation policies per IP | 3 (TCP SYN, TCP, UDP) — auto-tuned per protected IP via ML |
| Attack analytics | 5-minute increment reports during attack; full summary post-attack |
| SIEM integration | Stream to Sentinel, Splunk, Azure Storage, Event Hubs |

---

## Common security patterns

### Pattern A: Public web application (full defense-in-depth)

**Target:** Internet-facing regional web app; regulated workload or high-value target.

```
Internet
  │
  ▼
DDoS Network Protection (on VNet)
  │
  ▼
Azure Front Door WAF Premium (global L7 filter, bot, geo-block)
  │   [Private Link origin — App GW not reachable directly from internet]
  ▼
Application Gateway WAF_v2 (regional L7 filter, per-URI policies)
  │
  ▼
App Service / AKS (NSG-protected subnet)
  │
  ▼
Azure SQL / Storage via Private Endpoints (no public access)
```

**Controls active:** DDoS (L3/L4) + FD WAF (global L7) + App GW WAF (regional L7) + NSG (subnet) + Private Endpoints (PaaS).

---

### Pattern B: Internal application (no internet exposure)

**Target:** Internal LOB app accessed only by employees or trusted services.

```
Spoke VNet (App tier — NSG: allow only from known ASGs)
  │
  ▼ [East-west via UDR to hub Firewall]
Hub VNet (Azure Firewall Standard/Premium)
  │
  ▼
Spoke VNet (Data tier — NSG: allow only AsgApp on 1433)
  │
  ▼
Azure SQL / Storage via Private Endpoints
```

**Controls active:** NSG + ASG (per-tier) + Firewall (east-west inspection) + Private Endpoints (PaaS) + no public IPs on any tier.

---

### Pattern C: Branch connectivity with internet control

**Target:** Branch offices connecting to Azure via VPN or ExpressRoute with centralized internet egress.

```
Branch Office ──VPN/ER──► Hub VNet (Azure Firewall Standard)
                                 │
                         Internet egress (Firewall FQDN rules)
                                 │
                         Spoke VNets (UDR: 0.0.0.0/0 → Firewall)
```

**Controls active:** Firewall (N-S internet inspection + E-W) + Threat Intelligence (Deny mode) + forced tunneling for on-premises internet traffic.

---

### Pattern D: Zero Trust hub-spoke

**Target:** Enterprise multi-subscription environment; Zero Trust posture; regulated.

```
Management subscription:
  Azure Firewall Premium (hub) — IDPS Deny, TLS inspection, Threat Intel Deny
  DDoS Network Protection (hub VNet)
  Azure Firewall Manager — centralized policy across subscriptions

Workload subscriptions (spokes):
  NSGs with ASG-based rules (deny VNet-to-VNet default overridden)
  Private Endpoints for all PaaS (Storage, SQL, Key Vault, Service Bus)
  WAF on App Gateway (Prevention mode, DRS 2.x + Bot Manager)
  Conditional Access on all admin access paths
  VNet flow logs → Log Analytics → Sentinel
```

**Controls active:** All five layers active. Firewall Premium with IDPS enforces east-west Zero Trust. Private Endpoints eliminate all PaaS public data-plane exposure. Sentinel SIEM correlates across all layers.

---

### Pattern E: AKS workload isolation

**Target:** Kubernetes workloads on AKS with network segmentation.

- AKS cluster in dedicated subnet; NSG on subnet restricts inbound to Application Gateway or Internal Load Balancer only.
- Azure CNI: pods get VNet IPs; NSG rules can reference pod CIDRs or ASGs.
- Azure Network Policy or Calico for pod-to-pod micro-segmentation within cluster.
- Egress: UDR on AKS subnet `0.0.0.0/0 → Azure Firewall`; Firewall FQDN rules control what cluster nodes/pods can reach.
- PaaS access: Private Endpoints for ACR, Key Vault, Storage — AKS pulls images and secrets over private IPs.

---

## Gotchas

| Gotcha | Detail | Fix |
|---|---|---|
| **NSG default allows all VNet-to-VNet traffic** | `AllowVnetInBound` at priority 65000 permits any traffic between addresses in the same or peered VNet address space by default. East-west attacks are not blocked without an explicit override. | Add `Deny` rules at priority < 65000 for traffic that shouldn't flow between tiers; or use Firewall for E-W enforcement with UDRs. |
| **WAF Detection mode does not block** | A WAF in Detection mode logs suspicious requests but allows them all through. It provides zero active protection. | Always set WAF to **Prevention mode** in production. Use Detection mode only during initial tuning. |
| **Firewall SNAT to RFC 1918 destinations** | By default, Azure Firewall does NOT SNAT traffic destined for RFC 1918 (`10.x`, `172.16-31.x`, `192.168.x`) or RFC 6598 (`100.64/10`) ranges. If you route east-west traffic through the Firewall and the destination is on-premises (RFC 1918), return traffic may bypass the Firewall and cause asymmetric routing. | Configure the Firewall's private SNAT range to include on-premises subnets, or ensure return traffic is also routed through the Firewall via UDRs. |
| **DDoS Protection does not cover PaaS service IPs directly** | DDoS Network/IP Protection applies only to public IPs in your VNet. Azure PaaS multitenant service IPs (e.g., storage.windows.net) are not covered by your plan. | Use Private Endpoints to eliminate the public IP attack surface for PaaS entirely; that's the more effective control. |
| **Private Endpoints do not stop data exfiltration at the application layer** | A Private Endpoint prevents network-level public internet access to a PaaS resource. It does not prevent an application running inside the VNet from exfiltrating data through allowed L7 flows. | Combine Private Endpoints with Firewall L7 inspection (FQDN/URL filtering, TLS inspection on Premium) and data classification controls. |
| **DNS shadow zones break Firewall management connectivity** | Creating a Private DNS Zone that matches a Microsoft-owned domain (e.g., `*.blob.core.windows.net`, `azure.com`) can intercept Firewall control-plane DNS queries and break Firewall management. | Never create Private DNS Zones that shadow Microsoft-managed FQDNs. Use the recommended `privatelink.*` zone names only. |
| **Firewall autoscale takes 5–7 minutes** | Autoscale trigger fires at ≥60% throughput/CPU or ≥80% connections. New instances take 5–7 minutes to warm up — sustained bursts can saturate the Firewall before scale-out completes. | Pre-warm by provisioning with Minimum instances; for predictable traffic spikes, use scheduled autoscale if available or size the baseline higher. |
| **VNet encryption incompatibilities** | Enabling VNet encryption on a VNet that contains Azure Firewall, Application Gateway, ExpressRoute Gateway, DNS Private Resolver, or Private Link Service is unsupported and will break connectivity. | Segment: deploy encryption-sensitive VMs into dedicated VNets or subnets that do not contain the incompatible services. |
| **Default outbound access retiring March 2026** | New VNets using post-March-2026 API versions will default to private subnets. VMs with no explicit outbound method lose internet egress silently. | Explicitly configure NAT Gateway (recommended), Standard LB outbound rules, or Azure Firewall for all new workloads. |

---

## Related pages

- [Azure Firewall](../services/azure-firewall.md) — Stateful L3–L7 managed firewall; hub-perimeter layer; IDPS, TLS inspection, threat intel
- [Web Application Firewall (WAF)](../services/web-application-firewall.md) — OWASP L7 filtering on App Gateway and Front Door; application layer
- [DDoS Protection](../services/ddos-protection.md) — L3/L4 volumetric attack mitigation; edge layer
- [Private Link](../services/private-link.md) — Private Endpoints for PaaS; service-access layer; eliminates public data-plane exposure
- [Virtual Network](../services/virtual-network.md) — NSGs, ASGs, UDRs, service tags; network layer; foundational VNet primitive

---

## Source articles

| Source | Type | Notes |
|---|---|---|
| `wiki/services/azure-firewall.md` | Compiled wiki | SKU details, rule processing, placement patterns, SNAT behavior |
| `wiki/services/web-application-firewall.md` | Compiled wiki | WAF modes, rule sets, deployment patterns, anomaly scoring |
| `wiki/services/ddos-protection.md` | Compiled wiki | Tier comparison, detection metrics, coverage gaps |
| `wiki/services/private-link.md` | Compiled wiki | Private Endpoint capabilities, DNS, data-exfiltration limitations |
| `wiki/services/virtual-network.md` | Compiled wiki | NSG rules, ASGs, service tags, flow logs, VNet encryption caveats |
| `raw/articles/networking/security/network-security.md` | Raw Azure docs | Network security overview; service selection factors; portal hub |
| `raw/articles/networking/security/zero-trust-network-security.md` | Raw Azure docs | Zero Trust recommendations per service; risk level classification |
| `raw/articles/networking/security/zero-trust-firewall.md` | Raw Azure docs | Azure Firewall Zero Trust configuration recommendations |
| `raw/articles/networking/security/zero-trust-app-gateway.md` | Raw Azure docs | Application Gateway WAF Zero Trust configuration |
| `raw/articles/networking/security/zero-trust-front-door.md` | Raw Azure docs | Azure Front Door WAF Zero Trust configuration |
| `raw/articles/networking/security/zero-trust-ddos.md` | Raw Azure docs | DDoS Protection Zero Trust configuration |
| `raw/articles/networking/security/zero-trust-vnet.md` | Raw Azure docs | Virtual Network Zero Trust configuration |