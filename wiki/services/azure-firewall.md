# Azure Firewall

> **Compiled:** 2025-07-14 | **Source articles:** 86 | **Status:** current

## What it is

Azure Firewall is a fully stateful, cloud-native managed firewall-as-a-service that protects Azure Virtual Network resources. It features built-in high availability, unlimited cloud scalability (auto-scale), and inspects both east-west (lateral) and north-south (internet ingress/egress) traffic. It is available in three SKUs — Basic, Standard, and Premium — each targeting different security depth and throughput requirements.

---

## Key capabilities

| Capability | Details |
|---|---|
| Stateful packet filtering | 5-tuple network rules; TCP/UDP/ICMP/Any; terminating rule model (stops on first match) |
| SNAT / DNAT | All outbound to public IPs is SNATed; inbound via DNAT rules. Default no-SNAT for RFC 1918 / RFC 6598 destinations. |
| Application FQDN filtering | HTTP/HTTPS (SNI-based) and MSSQL FQDN filtering; wildcard support. All SKUs. |
| Network FQDN filtering | FQDNs in network rules (any port/protocol via DNS resolution). Standard + Premium only. |
| Threat Intelligence | Alert or Alert+Deny on known malicious IPs/FQDNs/URLs via Microsoft Cyber Security feed. Processed **before** all other rules. Basic = alert-only. |
| Web categories | Block/allow traffic by site category (gambling, social media, etc). Standard (FQDN-level); Premium (full URL-level). |
| DNS proxy + custom DNS | Forwards client DNS queries; required for FQDN filtering in network rules. Standard + Premium only. Up to 15 custom DNS servers. |
| TLS inspection | Outbound and east-west TLS decrypt/re-encrypt (forward proxy). Premium only. CA certificate required. |
| IDPS | Signature-based intrusion detection and prevention; 67,000+ signatures, 50+ categories, 20-40 new rules/day. Premium only. |
| URL filtering | Full URL path filtering (e.g. `www.contoso.com/a/b`). Premium only; requires TLS inspection for HTTPS. |
| Forced tunneling | Route all internet-bound traffic to an NVA or on-premises firewall. Standard + Premium only. Requires management NIC. |
| IP Groups | Logical groupings of IPs/CIDRs reusable across rules and multiple firewalls. All SKUs. |
| Firewall Manager | Centralized policy management across subscriptions and deployment modes (VNet hub + Virtual WAN). |
| Availability Zones | Multi-zone deployment for high availability. All SKUs. No extra cost for AZ deployment. |
| SIEM integration | Full log streaming to Azure Monitor, Event Hubs, Storage Accounts; Sentinel integration. |
| Policy analytics | Rule hit tracking and management over time. All SKUs. |

---

## When to use it

| Scenario | Recommended SKU |
|---|---|
| SMB / small Azure footprint, budget-constrained | **Basic** |
| Enterprise hub-spoke with centralized egress control, threat intel, DNS proxy | **Standard** |
| Regulated environments (PCI DSS, HIPAA, payment processing) requiring deep packet inspection | **Premium** |
| East-west traffic inspection between VNet spokes | Standard or Premium |
| TLS-encrypted outbound malware inspection | **Premium** |
| North-south internet egress filtering with FQDN rules | Standard or Premium |
| Multi-subscription, multi-region centralized firewall policy | Any SKU + Firewall Manager |
| Forced tunneling through on-premises edge firewall | Standard or Premium |

---

## When NOT to use it

| Anti-pattern | Better alternative |
|---|---|
| Inbound HTTP/S inspection (WAF) | [Azure Application Gateway WAF](application-gateway.md) — Azure Firewall does **not** apply application rules to inbound connections |
| Volumetric DDoS attack absorption | [Azure DDoS Protection](ddos-protection.md) |
| VM-level micro-segmentation / east-west within a subnet | NSGs (cheaper, lower latency, no routing required) |
| Simple port-based allow/deny with no FQDN requirements | NSGs — no per-GB data processing cost |
| Ultra-low latency with deep packet inspection at line rate | Third-party NVA from Azure Marketplace |
| Private endpoint DNS resolution override | Do **not** create Private DNS Zones that shadow Microsoft-owned domains (azure.com, core.windows.net, etc.) |

---

## SKUs and tiers

| SKU | Target use case | Max throughput | Fat flow | Threat Intel | IDPS | TLS Inspection | Forced Tunneling |
|---|---|---|---|---|---|---|---|
| **Basic** | SMB, essential protection | 250 Mbps [VERIFY] | N/A | Alert only | x | x | x |
| **Standard** | Enterprise L3-L7, autoscale | 30 Gbps [VERIFY] | 1 Gbps | Alert + Deny | x | x | Yes |
| **Premium** | Regulated, deep inspection | 100 Gbps [VERIFY] | 10 Gbps | Alert + Deny | Yes | Yes (outbound + E-W) | Yes |

**Key SKU differentiators:**
- Basic has **fixed scale** (2 VM backend instances; does **not** autoscale)
- Standard/Premium autoscale: scale-out triggers at avg throughput/CPU >= 60% or connections >= 80%; scale-in at < 20%. Takes 5-7 minutes.
- Initial out-of-the-box throughput (before autoscale): Standard ~3 Gbps, Premium ~18 Gbps [VERIFY]
- IDPS in Alert+Deny mode reduces Premium effective throughput to **10 Gbps** for single-flow inspection [VERIFY]
- Premium single TCP connection max: 9 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY]
- PCI DSS compliance: Premium only [VERIFY]
- DNS proxy: Standard and Premium only
- Web categories: Standard (FQDN-level); Premium (full URL-level, requires TLS inspection for HTTPS)

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Max public IP addresses per firewall | 250 [VERIFY] | Basic supports multiple but fewer |
| SNAT ports per public IP | 2,496 [VERIFY] | Add more PIPs or attach NAT Gateway to scale |
| Rule priority range | 100 - 65,000 | Lower number = higher priority |
| Max custom DNS servers | 15 [VERIFY] | Configured per firewall or policy |
| IDPS customizable signature overrides | Up to 10,000 [VERIFY] | Alert / Alert+Deny / Disabled per signature |
| IDPS signature library | 67,000+ signatures, 50+ categories | Updated daily (20-40 new rules/day) |
| Parallel IP Group updates | 20 at a time [VERIFY] | Per firewall policy or classic firewall |
| DNS cache TTL (positive) | Up to 1 hour | |
| DNS cache TTL (negative) | Up to 30 minutes | |
| Autoscale scale-out trigger | Avg throughput or CPU >= 60%, or connections >= 80% | |
| Autoscale scale-in trigger | Avg throughput, CPU, and connections < 20% | |

> **Note:** For authoritative limits see [Azure subscription and service limits - Azure Firewall](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-firewall-limits).

---

## Rule processing order

Rules are **terminating** - processing stops on first match. Full processing sequence per policy:

1. **Threat Intelligence** - evaluated first, before all other rules (all SKUs)
2. **DNAT rules** - processed in priority order within rule collection groups
3. **Network rules** - processed after all DNAT rules complete
4. **Application rules** - processed after all network rules (HTTP/HTTPS/MSSQL only)
5. **Infrastructure rule collection** - built-in Azure platform FQDNs; processed after application rules
6. **Implicit deny-all** - default deny if no rule matches

**IDPS interaction:** Alert mode runs in parallel with the rule engine. Alert+Deny mode runs inline after the rule engine and silently drops matched sessions (no TCP RST).

**Policy hierarchy:** Parent policy rule collection groups always take precedence over child policy groups, regardless of priority numbers.

---

## DNS proxy

Required for FQDN filtering in network rules (Standard + Premium):

- Caches responses (positive: up to 1 hr TTL; negative: up to 30 min TTL)
- Health checks every 5 seconds against upstream DNS; automatic failover
- **Warning:** Do not create Private DNS zones that shadow Microsoft-owned domains (e.g., `*.blob.core.windows.net`) - breaks firewall management connectivity

---

## TLS inspection (Premium only)

- Acts as a TLS forward proxy for outbound and east-west traffic
- Terminates client TLS, inspects plaintext, re-encrypts to destination
- Requires a customer-provided intermediate CA certificate
- Inbound TLS inspection is **not** supported - use Application Gateway for that
- 4 web categories exempt from TLS termination: Education, Finance, Government, Health and medicine
- TLS 1.2+ required; 1.0/1.1 deprecated

---

## Forced tunneling

Routes internet-bound traffic to an NVA or on-premises firewall instead of directly to the internet.

- Requires a **management NIC** (separate interface with Azure-managed public IP for control plane)
- DNAT not supported when forced tunneling enabled (asymmetric routing); exception: firewalls with Management NIC
- SNAT behavior: internet-bound traffic SNATed to firewall private IP - configure `0.0.0.0/0` as private range to prevent this

---

## Related services

- [Azure Application Gateway](application-gateway.md) - WAF for inbound HTTP/S; complements Firewall for ingress path
- [Azure DDoS Protection](ddos-protection.md) - volumetric DDoS defense; Firewall does not absorb volumetric DDoS
- [NAT Gateway](nat-gateway.md) - scales SNAT ports beyond Firewall per-PIP limit; attach to AzureFirewallSubnet for port exhaustion
- [Azure DNS](dns.md) - default resolver for Firewall; Private DNS Zones integrate with Firewall-resident name resolution
- [Network Watcher](network-watcher.md) - packet capture, flow logs, connection troubleshooting for Firewall-adjacent traffic
- [Virtual Network](virtual-network.md) - Firewall always deploys into an AzureFirewallSubnet within a VNet

---

## Source articles

| Article | Date |
|---|---|
| `overview.md` | 2026-03-28 |
| `features-by-sku.md` | 2025-09-18 |
| `premium-features.md` | 2025-09-18 |
| `choose-firewall-sku.md` | 2026-03-23 |
| `rule-processing.md` | 2026-03-23 |
| `firewall-performance.md` | 2026-03-28 |
| `firewall-best-practices.md` | 2026-03-28 |
| `threat-intel.md` | 2025-07-10 |
| `forced-tunneling.md` | 2026-03-28 |
| `dns-settings.md` | 2026-02-05 |
| `ip-groups.md` | 2026-03-28 |
| `snat-private-range.md` | 2026-03-28 |
