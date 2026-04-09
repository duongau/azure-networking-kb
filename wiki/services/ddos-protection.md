# Azure DDoS Protection

> **Compiled:** 2026-04-08 | **Source articles:** 32 | **Status:** current

## What it is

Azure DDoS Protection provides automatic, always-on mitigation of distributed denial-of-service (DDoS) attacks at Layer 3 and Layer 4 for resources deployed in Azure virtual networks. It monitors traffic 24/7 using machine learning-based per-IP profiling, triggers mitigation automatically when thresholds are exceeded, and offers two paid tiers (Network Protection and IP Protection) above the free infrastructure-level baseline that covers all Azure services.

---

## Key capabilities

| Capability | Details |
|---|---|
| **Always-on traffic monitoring** | Continuous 24/7 monitoring; compares actual utilization against per-IP DDoS policy thresholds |
| **Adaptive real-time tuning** | ML-based per-customer per-public-IP traffic profiling for L3/L4 |
| **Three auto-tuned mitigation policies** | TCP SYN, TCP, and UDP policies per protected public IP |
| **Attack detection-to-mitigation time** | 30-60 seconds [VERIFY] |
| **Attack analytics and flow logs** | 5-minute increment reports during attack; full summary post-attack; stream to Sentinel, Splunk, Azure Storage, or SIEM |
| **Attack metrics and alerting** | Azure Monitor metrics (e.g., *Under DDoS attack or not*, *Inbound packets dropped DDoS*); 30-day retention [VERIFY] |
| **DDoS Rapid Response (DRR)** | Dedicated Microsoft expert team accessible during active attacks - Network Protection only |
| **Cost protection** | Service credit for data-transfer and application scale-out costs during documented attacks - Network Protection only |
| **WAF discount** | Application Gateway WAF billed at Standard_v2 rate (not WAF_v2) when in a DDoS Network Protection VNet |
| **Multi-layered protection** | L3/L4 via DDoS Protection + L7 via WAF (App Gateway WAF or Azure Front Door WAF) |
| **Inline L7 DDoS protection** | Gateway Load Balancer + partner NVAs chained to Standard Public LB for per-packet L7 inspection |
| **Microsoft Sentinel integration** | Native data connector and workbook for correlating DDoS events with broader security telemetry |
| **Multi-subscription / multi-region plan** | One Network Protection plan covers all subscriptions in a tenant across regions |
| **Simulation testing** | Approved partners: BreakingPoint Cloud, MazeBolt, Red Button, RedWolf |

---

## When to use it

| Scenario | Recommendation |
|---|---|
| Any public-facing workload with public IP addresses in Azure VNets | Enable DDoS protection - free infrastructure tier has no adaptive tuning or telemetry |
| Small deployment with <10 public IPs, no need for DRR or cost guarantees | **DDoS IP Protection** (per-IP billing, lower total cost at small scale) |
| Enterprise deployment with 10+ public IPs, or requiring DRR / cost protection / WAF discount | **DDoS Network Protection** (fixed plan covers up to 100 IPs [VERIFY]; shared across tenant) |
| Application Gateway WAF in same VNet as DDoS Network Protection | Enables WAF discount - effectively subsidizes App Gateway SKU cost |
| Hub-and-spoke topology | Enable on hub VNet; all public IPs in hub (Firewall, Bastion, etc.) are protected |
| Latency-sensitive workloads needing L7 inspection (gaming, streaming, financial) | Add inline L7 via Gateway Load Balancer + partner NVA on top of DDoS L3/L4 |

---

## When NOT to use it

| Anti-pattern | Alternative / Notes |
|---|---|
| L7 attack protection (HTTP floods, Slowloris, SQL injection) | DDoS Protection covers L3/L4 only - add **Application Gateway WAF** or **Azure Front Door WAF** |
| Protecting Azure Virtual WAN resources | Not supported |
| Protecting PaaS multitenant services outside VNet integration | Not supported; requires VNet-deployed resources |
| Protecting public IPs attached to NAT Gateway | Explicitly unsupported |
| Classic/RDFE VM deployments | Not supported |
| VPN Gateway / Virtual Network Gateway adaptive tuning | Protection applies but adaptive tuning is not supported for these resource types |

---

## SKUs and tiers

| Tier | Scope | Pricing model | DRR | Cost protection | WAF discount |
|---|---|---|---|---|---|
| **Infrastructure Protection** (free) | All Azure public IPs globally | Included at no cost | No | No | No |
| **DDoS IP Protection** | Per public IP resource | Per protected IP per month [VERIFY] | No | No | No |
| **DDoS Network Protection** | Per VNet (plan covers all IPs in linked VNets) | Fixed monthly plan fee; up to 100 IPs [VERIFY] | Yes | Yes | Yes |

> **Pricing breakeven:** IP Protection is more cost-effective for <10 public IPs; Network Protection becomes more cost-effective at ~10+ IPs [VERIFY]. See [Azure DDoS Protection Pricing](https://azure.microsoft.com/pricing/details/ddos-protection/).

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Public IPs included per Network Protection plan | 100 [VERIFY] | Additional IPs incur overage charges [VERIFY] |
| DDoS protection plans per tenant (recommended) | 1 | One plan links to VNets across all subscriptions and regions |
| Attack metric data retention | 30 days [VERIFY] | Via Azure Monitor |
| Attack detection to mitigation initiation | 30-60 seconds [VERIFY] | May vary by attack type |
| Mitigation policies per protected public IP | 3 (TCP SYN, TCP, UDP) | Auto-tuned via ML-based traffic profiling |
| VMSS DDoS telemetry | Flexible orchestration mode only [VERIFY] | Not available for Uniform orchestration |
| Plan subscription move | Not supported | Must delete and recreate plan in target subscription |

> For authoritative limits see [Azure subscription and service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits).

---

## Related services

- [Azure Firewall](azure-firewall.md) - L3/L4/L7 filtering and threat intelligence; co-deployed in hub VNet for defense-in-depth
- [Application Gateway](application-gateway.md) - WAF provides L7 DDoS protection; gets billing discount when DDoS Network Protection is active on its VNet
- [Load Balancer](load-balancer.md) - Standard LB public IPs are protected resources; Gateway LB enables inline L7 DDoS via partner NVAs
- [Virtual Network](virtual-network.md) - DDoS Network Protection is scoped to a VNet; all public IPs automatically protected
- [Bastion](bastion.md) - Bastion public IP is a supported protected resource in hub-and-spoke topologies
- [VPN Gateway](vpn-gateway.md) - Supported protected resource; adaptive tuning not available
- [Network Watcher](network-watcher.md) - Complementary network diagnostics and flow logs alongside DDoS telemetry
- [Private Link](private-link.md) - Reduces public-facing attack surface by routing PaaS access over private endpoints

---

## Source articles

| Article | Notes |
|---|---|
| `ddos-protection-overview.md` | Primary overview |
| `ddos-protection-sku-comparison.md` | Tier comparison |
| `ddos-protection-features.md` | Feature details |
| `ddos-pricing-guide.md` | Pricing breakeven scenarios |
| `types-of-attacks.md` | Attack taxonomy |
| `fundamental-best-practices.md` | Design guidance |
| `ddos-protection-reference-architectures.md` | Architecture patterns |
| `ddos-rapid-response.md` | DRR details |
| `ddos-optimization-guide.md` | Cost optimization |
| `monitor-ddos-protection-reference.md` | Monitoring reference |
| `manage-permissions.md` | RBAC and restrictions |
| `test-through-simulations.md` | Simulation testing |
| `inline-protection-glb.md` | Inline L7 architecture |
