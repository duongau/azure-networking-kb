# Azure Firewall SKU Comparison

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Azure Firewall ships in three SKUs — Basic, Standard, and Premium — plus a WAF service (Web Application Firewall) that runs on Application Gateway and Front Door for inbound HTTP/S inspection. This page compares the three Firewall SKUs and cross-references WAF for completeness.

---

## Azure Firewall SKU overview

| Feature | Basic | Standard | Premium |
|---|---|---|---|
| **Target use case** | SMB / dev-test / simple essential protection | Enterprise hub-spoke; centralized egress; threat-aware | Regulated environments (PCI DSS, HIPAA); deep packet inspection |
| **Max throughput** | 250 Mbps [VERIFY] | 30 Gbps [VERIFY] | 100 Gbps [VERIFY] (10 Gbps with IDPS Alert+Deny [VERIFY]) |
| **Fat flow (single TCP)** | N/A | 1 Gbps | 10 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY] |
| **Autoscaling** | ❌ Fixed — 2 backend VM instances | ✅ Autoscales at avg throughput/CPU ≥60% or connections ≥80%; scale-out 5–7 min | ✅ Same autoscale behavior |
| **Initial throughput (before scale-out)** | 250 Mbps [VERIFY] | ~3 Gbps [VERIFY] | ~18 Gbps [VERIFY] |
| **Availability Zones** | ✅ Supported (no extra cost) | ✅ Supported | ✅ Supported |
| **Stateful packet filtering** | ✅ | ✅ | ✅ |
| **SNAT / DNAT** | ✅ | ✅ | ✅ |
| **Application FQDN filtering** | ✅ (HTTP/HTTPS SNI + MSSQL) | ✅ | ✅ |
| **Network FQDN filtering** | ❌ | ✅ (via DNS proxy) | ✅ (via DNS proxy) |
| **DNS proxy + custom DNS** | ❌ | ✅ (up to 15 DNS servers) | ✅ (up to 15 DNS servers) |
| **Threat Intelligence** | ✅ Alert-only (no Alert+Deny) | ✅ Alert or Alert+Deny | ✅ Alert or Alert+Deny |
| **Web categories** | ❌ | ✅ FQDN-level | ✅ Full URL-level (requires TLS inspection for HTTPS) |
| **IDPS** | ❌ | ❌ | ✅ 67,000+ signatures; 50+ categories; 20–40 new rules/day; Alert or Alert+Deny |
| **TLS inspection** | ❌ | ❌ | ✅ Outbound + east-west (forward proxy); requires intermediate CA cert; inbound TLS NOT supported |
| **URL filtering (full path)** | ❌ | ❌ | ✅ Requires TLS inspection for HTTPS |
| **Forced tunneling** | ❌ | ✅ (requires Management NIC) | ✅ (requires Management NIC) |
| **Management NIC** | ❌ (Basic SKU has none — no forced tunneling) | ✅ Required for forced tunneling | ✅ Required for forced tunneling |
| **IP Groups** | ✅ | ✅ | ✅ |
| **Policy analytics** | ✅ | ✅ | ✅ |
| **Firewall Manager** | ✅ | ✅ | ✅ |
| **SIEM / Log Streaming** | ✅ | ✅ | ✅ |
| **PCI DSS compliance** | ❌ | ❌ | ✅ [VERIFY] |
| **Pricing tier** | Lowest | Mid | Highest |
| **SLA** | [VERIFY] | [VERIFY] | [VERIFY] |

---

## IDPS deep-dive (Premium only)

| IDPS property | Value |
|---|---|
| Signature library | 67,000+ signatures |
| Categories | 50+ |
| Update rate | 20–40 new rules/day |
| Customizable signature overrides | Up to 10,000 [VERIFY] |
| Override actions per signature | Alert / Alert+Deny / Disabled |
| Alert mode behavior | Runs in parallel with rule engine — logs only, no blocking |
| Alert+Deny mode behavior | Runs inline after rule engine — silently drops matched sessions (no TCP RST) |
| Throughput impact (Alert+Deny) | Reduces effective throughput to 10 Gbps aggregate [VERIFY]; single TCP flow max 300 Mbps [VERIFY] |

---

## TLS inspection deep-dive (Premium only)

| TLS property | Value |
|---|---|
| Supported direction | Outbound (internet-bound) and east-west (spoke-to-spoke) |
| **Not** supported direction | Inbound — use **Application Gateway WAF_v2** for inbound HTTP/S inspection |
| Mechanism | Forward proxy — terminates client TLS, inspects plaintext payload, re-encrypts to destination |
| Certificate requirement | Customer-provided intermediate CA certificate |
| TLS versions supported | TLS 1.2+ (1.0/1.1 deprecated) |
| Categories exempt from TLS termination | Education, Finance, Government, Health and medicine (4 categories) |
| Integration with IDPS | TLS inspection must be enabled to enable IDPS on HTTPS traffic |
| Integration with URL filtering | TLS inspection required for full URL path filtering on HTTPS |

---

## Forced tunneling (Standard + Premium)

Routes all internet-bound firewall traffic to an NVA or on-premises edge instead of directly to the internet.

| Property | Value |
|---|---|
| Requirement | Management NIC (separate control-plane interface with Azure-managed public IP) |
| Basic SKU | ❌ Not supported |
| DNAT compatibility | Not supported when forced tunneling enabled (asymmetric routing); exception: firewalls WITH Management NIC |
| SNAT behavior | Configure `0.0.0.0/0` as private range to prevent Firewall from SNATing to its own IP before handoff |

---

## Threat Intelligence (all SKUs — different modes)

| Property | Basic | Standard | Premium |
|---|---|---|---|
| Mode available | Alert only | Alert or Alert+Deny | Alert or Alert+Deny |
| Evaluated | Before all customer rules | Before all customer rules | Before all customer rules |
| Feed source | Microsoft Cyber Security feed | Same | Same |
| Covers | Known malicious IPs, FQDNs, URLs | Same | Same |

---

## Rule processing order (all SKUs — same sequence)

```
1. Threat Intelligence        ← evaluated FIRST (before customer rules)
2. DNAT rules                 ← inbound port-forwarding
3. Network rules              ← 5-tuple; priority 100–65,000
4. Application rules          ← FQDN-based; HTTP/HTTPS/MSSQL
5. Infrastructure rule collection ← built-in Azure platform FQDNs
6. Implicit deny-all          ← default if no match
```

IDPS (Premium only): Alert mode runs in parallel with step 3/4; Alert+Deny runs inline after step 4.

---

## "Which SKU?" decision guide

```
START: Do you need Azure Firewall?

├─ Budget-constrained, small Azure footprint, dev/test?
│   └─ YES → Azure Firewall Basic
│            (250 Mbps, fixed scale, alert-only threat intel, no DNS proxy)

├─ Enterprise hub-spoke, centralized egress, multi-subscription governance?
│   └─ YES → Azure Firewall Standard
│            (30 Gbps autoscale, alert+deny threat intel, DNS proxy,
│             FQDN network rules, web categories, forced tunneling)
│             └─ Sub-question: Does your compliance mandate IDPS, TLS inspection,
│                              PCI DSS, or full URL-path filtering?
│                 ├─ YES → Azure Firewall Premium
│                 └─ NO  → Standard is sufficient

├─ Regulated environment (PCI DSS, HIPAA, payment processing)?
│   └─ YES → Azure Firewall Premium (only SKU with PCI DSS compliance [VERIFY])
│            (100 Gbps, IDPS, TLS inspection, URL filtering, full web categories)

└─ Need inbound HTTP/S WAF (blocking SQLi, XSS, bots at ingress)?
    └─ YES → NOT Azure Firewall — use Application Gateway WAF_v2 or Front Door WAF
             (Azure Firewall does not apply application rules to inbound flows)
```

---

## Comparison: Azure Firewall vs WAF (complementary, not competing)

| Dimension | Azure Firewall (Standard/Premium) | Application Gateway WAF_v2 | Front Door WAF (Premium) |
|---|---|---|---|
| **Primary function** | Stateful network/app firewall; egress + east-west control | Inbound HTTP/S reverse proxy with WAF | Global edge inbound WAF + L7 delivery |
| **Direction** | Outbound + east-west (inbound via DNAT only) | Inbound only | Inbound at global edge |
| **Protocol** | Any (L3–L7); FQDN application rules for HTTP/S | HTTP / HTTPS / WebSocket / HTTP/2 | HTTP / HTTPS |
| **OWASP managed rules** | ❌ | ✅ DRS 2.x, CRS 3.x | ✅ DRS 2.1+ (Premium only) |
| **Bot protection** | Threat Intel (known malicious IPs — broad) | ✅ Bot Manager 1.0/1.1 (fine-grained bot classification) | ✅ Bot Manager 1.1 (Premium) |
| **IDPS (signature-based)** | ✅ Premium (67,000+ signatures) | ❌ | ❌ |
| **TLS decrypt/inspect** | ✅ Premium (outbound/E-W) | ✅ Yes (inbound TLS termination + re-encrypt to backend) | ✅ Yes (edge TLS termination) |
| **Cost model** | Hourly + per-GB data processing | Hourly + per CU | Monthly base + per-request + per-GB |

**Canonical combined pattern:**
```
Internet → Front Door WAF Premium (global L7) → App Gateway WAF_v2 (regional inbound) 
        → VNet → Azure Firewall Premium (east-west + egress IDPS + TLS inspection) → Backend
```

---

## Service limits [VERIFY all]

| Limit | Basic | Standard | Premium |
|---|---|---|---|
| Max public IPs | Multiple (fewer than Std) [VERIFY] | 250 | 250 |
| SNAT ports per public IP | 2,496 [VERIFY] | 2,496 [VERIFY] | 2,496 [VERIFY] |
| Custom DNS servers | ❌ | 15 | 15 |
| Rule priority range | 100–65,000 | 100–65,000 | 100–65,000 |
| Parallel IP Group updates | 20 | 20 | 20 |
| DNS cache TTL (positive) | N/A | ≤1 hour | ≤1 hour |
| DNS cache TTL (negative) | N/A | ≤30 minutes | ≤30 minutes |
| IDPS signature overrides | N/A | N/A | Up to 10,000 |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure Firewall](../services/azure-firewall.md) | All SKU capabilities, IDPS, TLS inspection, rule processing, forced tunneling, limits |
| [Web Application Firewall](../services/web-application-firewall.md) | WAF rule sets, DRS/CRS versions, bot protection, per-platform modes, rate limiting |