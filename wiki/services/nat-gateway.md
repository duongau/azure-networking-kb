# NAT Gateway

> **Compiled:** 2026-04-08 | **Source articles:** 27 | **Status:** ✅ current

## What it is

Azure NAT Gateway is a **fully managed, highly resilient Network Address Translation (NAT) service** that provides secure, scalable outbound internet connectivity for resources in an Azure virtual network. It uses software-defined networking and spans multiple fault domains — no zone pinning required on StandardV2.

Key behavior:
- Performs **SNAT** (source NAT) — rewrites private IP/port → public IP/port for outbound flows
- Performs **DNAT only for return traffic** — no unsolicited inbound connections from internet
- Becomes the **subnet's default route to the internet** automatically when attached — no UDR needed
- Supports **up to 16 public IP addresses** (or prefixes) per NAT Gateway instance
- **Takes precedence** over Load Balancer outbound rules and instance-level public IPs when attached to the same subnet

---

## Key capabilities

| Capability | Detail |
|---|---|
| Dynamic SNAT port allocation | Ports allocated on-demand from shared pool; no pre-configuration needed |
| Scales up to 1M+ SNAT ports | 16 IPs × 64,512 ports per IP = ~1M SNAT ports |
| Up to 800 subnets per instance | Share one NAT Gateway across all subnets in a VNet |
| Idle TCP timeout configurable | 4–120 minutes (default: 4 min); UDP: fixed 4 min |
| Port reuse timer | Ports recycled after connection closes |
| Metrics + flow logs (V2) | Azure Monitor metrics for bytes, packets, connections, health |

---

## When to use it

✅ **Use NAT Gateway when:**
- You need **outbound internet access** from private subnets (VMs, AKS nodes, App Service VNet-integrated)
- You want **deterministic public IPs** for outbound traffic (firewall allowlisting, partner IP allowlists)
- You need to **scale SNAT** without SNAT port exhaustion (high-connection workloads, chatty microservices)
- You want to **avoid default outbound access** (deprecated for new VNets after March 31, 2026)
- You need **zone-redundant outbound** from all AZs in a region → use StandardV2

> ⚠️ **March 31, 2026 breaking change:** New virtual networks default to private subnets — default outbound access is no longer provided. Explicit outbound method (NAT Gateway recommended) is required for internet connectivity.

---

## When NOT to use it

❌ **Do NOT use NAT Gateway when:**
- You need **inbound internet connectivity** — use Public Load Balancer or Application Gateway instead
- You're in a **vWAN hub** — NAT Gateway isn't supported in vWAN hub configurations
- You need **BYOIP (custom IP prefixes)** with StandardV2 — not supported; use Standard SKU
- The subnet is a **gateway subnet** (VPN Gateway) — NAT Gateway can't attach to gateway subnets
- You require **AKS managed NAT Gateway** with StandardV2 — only user-assigned is supported

---

## SKUs and tiers

| Feature | StandardV2 ✨ | Standard |
|---|---|---|
| Zone support | Zone-redundant (all AZs) | Zonal (single AZ) |
| IPv6 | ✅ IPv4 + IPv6 | ❌ IPv4 only |
| Max bandwidth | 100 Gbps | 50 Gbps |
| Per-connection bandwidth | 1 Gbps | — |
| Packets per second | 10M / 100K per connection | 5M |
| Public IPs | 16 IPv4 + 16 IPv6 | 16 IPv4 |
| IP prefixes | /28 IPv4, /124 IPv6 | /28 IPv4 |
| Flow logs | ✅ | ❌ |
| Pricing | Same price | Same price |

**Recommendation:** Use **StandardV2** for all new deployments. It's zone-redundant by default, has higher throughput, and supports IPv6.

### StandardV2 known limitations and unsupported delegated subnets
StandardV2 does NOT support subnets delegated to:
- Azure SQL Managed Instance, Container Instances, PostgreSQL/MySQL Flexible Server
- Azure Data Factory, Power Platform, Stream Analytics
- Web Apps, Container Apps, DNS Private Resolver

### StandardV2 region gaps (as of Nov 2025)
Not available in: Canada East, Central India, Chile Central, Indonesia Central, Israel Northwest, Malaysia West, Qatar Central, UAE Central, Brazil Southeast, Sweden South, West Central US, West India

---

## Service limits

| Limit | Value |
|---|---|
| Public IPs per NAT Gateway | 16 IPv4 (Standard); 16 IPv4 + 16 IPv6 (StandardV2) |
| Subnets per NAT Gateway | 800 |
| SNAT ports per IP | 64,512 |
| Max SNAT ports total | ~1,032,192 (16 IPs × 64,512) |
| Connections per IP per destination | 50,000 |
| Total concurrent connections | 2,000,000 |
| Idle TCP timeout | 4–120 minutes |
| Max bandwidth (V2) | 100 Gbps |
| VNets per NAT Gateway | 1 |

---

## SNAT port exhaustion — key design considerations

NAT Gateway dynamically allocates SNAT ports on-demand from the shared inventory across all VMs in attached subnets. When all ports are consumed, new connections fail.

**Scaling formula:** `Expected peak concurrent flows × 1.5 safety margin → determine IP count`

Each IP adds 64,512 ports. A single IP supports ~50K concurrent connections to the same destination endpoint.

**Common mitigation patterns:**
- **Add more public IPs** (up to 16) — fastest scaling lever
- **Use IP prefixes** (/28 = 16 IPs, /29 = 8 IPs) — simpler management, same SNAT ports per IP
- **Connection pooling** in app code — reuse connections to reduce port churn
- **Multiple NAT Gateways** — attach different gateways to different subnets to isolate SNAT pools

---

## Monitoring

**Key metrics (Azure Monitor):**
| Metric | What it tells you |
|---|---|
| SNAT Connection Count | Active SNAT connections; high = approaching limits |
| Dropped Packets | Packet loss due to SNAT exhaustion or config issues |
| Bytes | Outbound throughput |
| Datapath Availability | Health of the NAT gateway; should be 100% |

**Access metrics via:**
- NAT Gateway resource → **Monitoring → Metrics**
- NAT Gateway resource → **Monitoring → Insights** (visual topology + dashboards)
- Azure Monitor → Metrics

**Flow logs (StandardV2 only):** Enable via diagnostic settings. Captures per-flow IP/port/protocol/bytes data to Log Analytics or Storage.

---

## Related services

| Service | Relationship |
|---|---|
| **Virtual Network** | NAT Gateway attaches to VNet subnets |
| **Azure Firewall** | Alternative for outbound if you also need egress filtering/inspection |
| **Load Balancer** | NAT Gateway takes precedence over LB outbound rules when both on same subnet |
| **Public IP / Prefix** | NAT Gateway consumes Standard SKU public IPs or prefixes |
| **Azure Bastion** | Use for inbound management access; NAT Gateway handles outbound |
| **VPN Gateway** | Can coexist; NAT Gateway handles internet egress, VPN handles on-prem |
| **Application Gateway** | Handles inbound HTTP/S; NAT Gateway handles VM outbound |

### Coexistence with Azure Firewall
In a hub-spoke topology, Azure Firewall is the preferred egress point when you need **traffic inspection + outbound internet**. NAT Gateway is preferred for direct, high-scale outbound without inspection overhead. In hub-spoke with Firewall, route spoke internet traffic through Firewall — don't attach NAT Gateway to spoke subnets in that pattern.

---

## Source articles

| Article | ms.topic | ms.date |
|---|---|---|
| `nat-overview.md` | overview | 11/04/2025 |
| `nat-sku.md` | overview | 11/04/2025 |
| `nat-gateway-resource.md` | concept-article | 11/04/2025 |
| `nat-gateway-design.md` | concept-article | 11/04/2025 |
| `nat-gateway-snat.md` | concept-article | 04/29/2024 |
| `nat-metrics.md` | how-to | 09/09/2025 |
| `nat-gateway-flow-logs.md` | concept-article | — |
| `troubleshoot-nat.md` | troubleshooting | — |
| `troubleshoot-nat-connectivity.md` | troubleshooting | — |
| `nat-gateway-v2-migrate.md` | how-to | — |
| `quickstart-create-nat-gateway.md` | quickstart | — |
| `quickstart-create-nat-gateway-v2.md` | quickstart | — |
| _(+15 more tutorials and how-tos)_ | | |
