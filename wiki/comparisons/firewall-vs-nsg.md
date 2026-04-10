# Azure Firewall vs NSG (and ASG)

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

NSGs and Azure Firewall are not alternatives — they operate at different layers, serve different purposes, and are designed to be deployed together as a defense-in-depth stack. This page clarifies the distinction, explains the layering, and guides the "when to use each" decision.

---

## Core comparison

| Dimension | Network Security Group (NSG) | Application Security Group (ASG) | Azure Firewall (Standard/Premium) |
|---|---|---|---|
| **What it is** | Stateful L4 ACL (allow/deny) | Logical NIC grouping to simplify NSG rules | Managed stateful L3–L7 firewall-as-a-service |
| **OSI layer** | Layer 4 (port + protocol) | Layer 4 (via NSG rules) | Layers 3–7 (network, application, FQDN) |
| **Stateful?** | ✅ Yes | ✅ Yes (via NSG) | ✅ Yes |
| **Where it attaches** | Subnet or NIC | NIC membership referenced in NSG rules | Dedicated `AzureFirewallSubnet` (/26) in a VNet |
| **FQDN filtering** | ❌ No — IP/port/protocol only | ❌ No | ✅ Yes — HTTP/HTTPS (SNI), MSSQL; wildcard support. Network FQDNs: Standard + Premium |
| **Threat Intelligence** | ❌ No | ❌ No | ✅ Yes — Microsoft Cyber Security feed; processed before all rules. Basic: alert only; Standard/Premium: alert + deny |
| **IDPS** | ❌ No | ❌ No | ✅ Premium only — 67,000+ signatures, 50+ categories, 20–40 new rules/day |
| **TLS inspection** | ❌ No | ❌ No | ✅ Premium only — outbound + east-west (forward proxy); requires intermediate CA cert |
| **Web categories** | ❌ No | ❌ No | ✅ Standard (FQDN-level); Premium (full URL-level with TLS inspection) |
| **DNS proxy / FQDN resolution** | ❌ No | ❌ No | ✅ Standard + Premium — caches responses; required for FQDN network rules |
| **Centralized logging** | ⚠️ NSG flow logs to Storage; Traffic Analytics optional | N/A | ✅ Full log streaming to Azure Monitor, Event Hubs, Sentinel — rule-matched flows with FQDN context |
| **Forced tunneling** | ❌ No | ❌ No | ✅ Standard + Premium — requires management NIC |
| **Rule model** | Priority-ordered allow/deny; first match wins | Group membership referenced in NSG rules | Terminating: Threat Intel → DNAT → Network → Application → Infra → Implicit deny |
| **Cost** | ✅ Free — included with VNet | ✅ Free — included with NSG | 💰 Hourly compute + per-GB data processing; Standard ~$1.25/hr [VERIFY] |
| **Scale** | Per-VNet; up to 1,000 rules per NSG [VERIFY] | Up to 50 ASG members per NSG on PE subnets [VERIFY] | Standard: autoscale to 30 Gbps [VERIFY]; Premium: 100 Gbps [VERIFY] |
| **Managed by** | Customer (ARM/Portal/Policy) | Customer | Microsoft (managed PaaS); policy via Firewall Manager |

---

## NSG in depth

### Rule processing

```
Inbound traffic:
  1. Subnet NSG (if present)
  2. NIC NSG (if present)
  → First DENY rule wins; first ALLOW rule wins within each NSG

Outbound traffic:
  1. NIC NSG (if present)
  2. Subnet NSG (if present)
```

### Built-in default rules (cannot be removed, only overridden)

| Priority | Name | Action | Notes |
|---|---|---|---|
| 65000 | `AllowVNetInBound` | Allow | All traffic between addresses in the VNet + connected VNets |
| 65001 | `AllowAzureLoadBalancerInBound` | Allow | Azure health probe source IPs |
| 65500 | `DenyAllInBound` | Deny | All other inbound — critical: Standard LB closed to inbound by default |

### ASG — logical grouping for scalable rules

Instead of: `Source: 10.0.1.0/24 → Destination: 10.0.2.0/24 port 8080 Allow`
Write: `Source: AsgWeb → Destination: AsgApp port 8080 Allow`

- Add or remove VMs from the group without changing NSG rules
- All NIC members of an ASG must be in the same VNet
- Up to 50 ASG members per NSG on Private Endpoint subnets [VERIFY] — exceeding 50 silently causes PE connection failures

### What NSGs cannot do

- Inspect HTTP content, URLs, or hostnames
- Filter by FQDN (only IP/CIDR/service tags/ASG)
- Log individual connection metadata beyond 5-tuple (port-range, action, byte count)
- Apply threat intelligence or signature-based detection
- Decrypt and inspect TLS payloads
- Centralize policy across subscriptions (use Security Admin Rules via AVNM for that)

---

## Azure Firewall in depth

### Rule processing order

1. **Threat Intelligence** — evaluates first, before all customer rules (all SKUs)
2. **DNAT rules** — inbound port-forwarding (no DNAT support with forced tunneling enabled)
3. **Network rules** — 5-tuple; TCP/UDP/ICMP/Any
4. **Application rules** — HTTP/HTTPS/MSSQL; FQDN-based
5. **Infrastructure rule collection** — built-in Azure platform FQDNs (Windows Update, Azure metadata, etc.)
6. **Implicit deny-all** — default if no rule matches

### IDPS (Premium only) interaction

- **Alert mode:** runs in parallel with rule engine; logs matches; does not block
- **Alert + Deny mode:** runs inline after rule engine; silently drops matched sessions (no TCP RST sent); reduces effective throughput to ~10 Gbps for single-flow inspection [VERIFY]

### Key constraints

- Firewall always deployed in `AzureFirewallSubnet` (minimum /26; exact name required)
- Does **not** apply Application rules to inbound traffic — for inbound HTTP/S WAF, use **Application Gateway WAF**
- TLS inspection applies to **outbound and east-west** only; inbound TLS inspection requires Application Gateway
- DNAT not supported when forced tunneling is enabled (asymmetric routing); exception: Firewalls with Management NIC
- Basic SKU: fixed 2-instance scale (does not autoscale); alert-only threat intel; no IDPS, no TLS, no forced tunneling, no DNS proxy

---

## Can they work together? Yes — and they should.

This is the canonical defense-in-depth pattern for Azure workloads:

```
Internet
    │
    ▼
[Azure Firewall or NVA — hub VNet]          ← Layer: perimeter
    Threat Intel, FQDN rules, IDPS, TLS inspection (Premium)
    Logs east-west + north-south flows
    │
    ▼ (via UDR on spoke subnets → Firewall private IP)
[NSG on subnet — spoke VNet]                ← Layer: network
    Port/protocol allow-list per subnet
    Deny-by-default for inbound (Standard LB behavior)
    │
    ▼
[NSG on NIC — individual VM]                ← Layer: network (optional)
    Only when different VMs in same subnet need different rules
    │
    ▼
[VM workload]
```

**Why both?** Azure Firewall provides centralized FQDN filtering, threat intelligence, and cross-spoke inspection — capabilities NSGs cannot provide. NSGs provide cheap, low-latency, granular port-level controls that the Firewall does not need to process. If a flow is blocked by an NSG, it never reaches the Firewall — reducing Firewall data processing cost.

---

## Decision guide

| Requirement | Use NSG | Use Azure Firewall |
|---|---|---|
| Allow/deny traffic by port, protocol, IP/CIDR at low cost | ✅ | ❌ (overkill and expensive) |
| Filter by FQDN or domain name | ❌ | ✅ |
| Inspect traffic across all spokes from one place | ❌ | ✅ |
| Block known malicious IPs/domains via Threat Intelligence | ❌ | ✅ |
| Detect and block intrusion signatures (IDPS) | ❌ | ✅ Premium only |
| Decrypt and inspect TLS-encrypted outbound traffic | ❌ | ✅ Premium only |
| Simple VM-to-VM micro-segmentation within a subnet | ✅ | ❌ (don't route intra-subnet traffic through Firewall) |
| Low-latency rule enforcement (no additional hop) | ✅ | ❌ (adds ~0.5–1ms hop for routing through Firewall) |
| No per-GB cost tolerance | ✅ (free) | ❌ ($0.016/GB+ data processing [VERIFY]) |
| Centralized policy management across 100+ subscriptions | ❌ (use Security Admin Rules via AVNM) | ✅ Firewall Manager |

---

## Common anti-patterns

| Anti-pattern | Problem | Correct approach |
|---|---|---|
| NSG alone to control egress FQDN filtering | NSGs are IP-only; Azure service IPs rotate without notice | Azure Firewall with FQDN application rules |
| Azure Firewall alone without NSGs | No cheap subnet-level deny for unexpected inbound ports | Use NSGs on all subnets as a backstop |
| Firewall for inbound HTTP/S WAF | Firewall does not apply L7 app rules to inbound flows | Application Gateway WAF_v2 for inbound web traffic inspection |
| Creating Private DNS zones that shadow Microsoft domains (e.g., `*.core.windows.net`) | Breaks Firewall management connectivity and FQDN resolution | Never shadow Microsoft-owned domains in Private DNS |
| Routing intra-subnet traffic through the Firewall | Introduces unnecessary latency; NSGs handle this better | NSGs on the subnet; Firewall for cross-subnet and north-south |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure Firewall](../services/azure-firewall.md) | SKUs, capabilities, rule processing, IDPS, TLS inspection, DNS proxy |
| [Virtual Network](../services/virtual-network.md) | NSG mechanics, ASG, rule processing order, service tags |
| [Network Security Design](../concepts/network-security-design.md) | Defense-in-depth model, WAF patterns, Zero Trust controls |