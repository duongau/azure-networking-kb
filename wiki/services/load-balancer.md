# Azure Load Balancer

> **Compiled:** 2026-04-10 | **Source articles:** 95 | **Status:** current

## What it is

Azure Load Balancer is a Layer-4 (OSI) pass-through network load balancer that distributes inbound TCP and UDP traffic across a backend pool of virtual machines (VMs) or virtual machine scale sets (VMSS). It operates as the single point of contact for clients, distributing flows according to configurable rules and health probes, and supports both inbound and outbound connectivity scenarios. It comes in three SKUs — Standard, Gateway, and Basic (retired September 30, 2025).

---

## Key capabilities

| Capability | Details |
|---|---|
| **Layer-4 load balancing** | Distributes TCP and UDP flows; does not terminate connections; pass-through model preserves original IP |
| **Public and Internal types** | Public LB: internet-facing with public frontend IP. Internal (ILB): private frontend IP for VNet-internal or hybrid traffic |
| **Zone-redundancy** | Standard LB supports zone-redundant, zonal, or no-zone frontend IP configurations |
| **High-availability ports (HA ports)** | Single rule balances all TCP+UDP flows on all ports simultaneously; internal Standard LB only; primary use case: NVAs |
| **Outbound SNAT** | Uses LB frontend IP(s) for outbound via explicit outbound rules; 64,000 [VERIFY] ports per public IP |
| **Health probes** | TCP, HTTP, HTTPS (HTTPS: Standard only); source IP 168.63.129.16; default interval 5 s; HTTP/S timeout 30 s |
| **Distribution modes** | 5-tuple hash (default), 2-tuple session persistence (client IP), 3-tuple (client IP + protocol) |
| **Floating IP (Direct Server Return)** | Maps frontend IP to backend; enables port reuse across rules; requires loopback config on guest OS |
| **Inbound NAT rules** | Port-forward specific frontend IP:port to a specific VM or VMSS instance |
| **Admin State** | Override health probe per backend instance: Up / Down / None; useful for maintenance without connection disruption |
| **Global tier (cross-region)** | Geo-proximity routing across regional Standard LBs; static anycast IP; 5-second health check to regional LBs |
| **Gateway LB** | Dedicated SKU for transparent NVA insertion; VXLAN encapsulation; private frontend only; HA port rules only |
| **Multi-frontend** | Multiple frontend IPs on a single LB; supports multi-VIP scenarios |
| **IPv6 / dual-stack** | Standard LB supports IPv4/IPv6 dual-stack |
| **TCP Reset on idle** | Sends bidirectional RST on idle timeout; Standard only |
| **Zero Trust security** | Standard LB closed to inbound by default; NSG required to allow traffic |
| **Private Link support** | Standard Internal LB can serve as Private Link service origin |
| **NAT Gateway integration** | Standard LB (internal and public) supported behind NAT Gateway for outbound |
| **Global VNet peering** | Standard Internal LB accessible via Global VNet Peering |
| **Cross-subscription backend** | Backend pools and frontends can span subscriptions (Standard) |
| **Diagnostics** | Azure Monitor multi-dimensional metrics: Data Path Availability, Health Probe Status, SYN Count, SNAT Connection Count, Allocated/Used SNAT Ports, Byte Count, Packet Count; bandwidth metrics support Protocol dimension filter (TCP=6, UDP=17) |
| **Health event logs** | GA (February 2025) under Azure Monitor resource log category `LoadBalancerHealthEvent`; all public, China, and Government regions |
| **Health Status** | GA (November 2024); per-backend-instance health state with reason detail |

---

## When to use it

| Scenario | Recommendation |
|---|---|
| Distribute internet traffic to VMs / VMSS | Standard Public LB |
| Internal load balancing within a VNet or from on-premises | Standard Internal LB |
| High availability for NVAs (firewalls, SD-WAN, IDS/IPS) | Standard Internal LB + HA ports, or Gateway LB (preferred) |
| Insert NVAs transparently without UDRs | Gateway LB chained to Standard Public LB |
| Global multi-region failover with geo-proximity routing | Cross-region (Global tier) Standard LB |
| Outbound SNAT for backend VMs (not preferred; use NAT GW first) | Standard Public LB with explicit outbound rules |
| Port forwarding to individual VMs | Inbound NAT rules |
| SQL Always On AG listeners, clustering, multi-TLS endpoint | Floating IP enabled rules |
| Controlled maintenance without dropping existing connections | Admin State: Down |

---

## When NOT to use it

| Anti-pattern | Alternative |
|---|---|
| HTTP/HTTPS routing with path, host, cookie, or TLS offload | [Application Gateway](application-gateway.md) (Layer 7) |
| Global HTTP(S) content delivery, WAF, caching | [Azure Front Door](../decisions/choose-load-balancer.md) |
| Outbound internet connectivity for VMs (primary method) | [NAT Gateway](nat-gateway.md) — preferred over LB outbound rules |
| Private access to Azure PaaS without internet exposure | [Private Link](private-link.md) — avoids SNAT entirely |
| Small non-HA workloads (Basic was the option, now retired) | Upgrade to Standard; no Basic alternative |
| Outbound from ILB backend to ILB frontend | Not supported — outbound flow from backend VM to its own ILB frontend fails |
| Load balancing across VNets | Not supported — frontend and backend must be in the same VNet |
| ICMP load balancing | Not supported (except ICMP on internal Standard LB with HA ports enabled) |

---

## SKUs and tiers

| SKU | Use case | Key limits / notes |
|---|---|---|
| **Standard** | Production-grade; high performance, zone-redundancy, 99.99% SLA [VERIFY] | Backend: any VM/VMSS in a single VNet; closed to inbound by default; supports outbound rules, HA ports, HTTPS probes, TCP reset, multi-dim metrics, Private Link, NAT Gateway, Global VNet peering |
| **Gateway** | Transparent NVA insertion (firewalls, IDS/IPS, packet analytics) | Private frontend only; HA port rules only (protocol: All, port: 0); VXLAN encapsulation; up to 2 tunnel interfaces per backend pool; up to 2 backend pools per rule; does NOT work with Global tier |
| **Basic** *(retired)* | Small-scale, non-HA workloads | **Retired September 30, 2025.** No AZ support, no HTTPS probes, no outbound rules, no HA ports, no diagnostics, open by default, no SLA. Migrate to Standard. |
| **Standard — Global tier** | Cross-region geo-proximity routing; multi-region failover | Public frontend only; backend pool = regional Standard LBs; static anycast IP; 5-second health check interval to regional LBs; home regions limited (9 Azure + Gov/China) [VERIFY]; no outbound rules; no UDP port 3; no NAT64 |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| SNAT ports per public frontend IP | 64,000 [VERIFY] | Each LB or inbound NAT rule consumes 8-port blocks from this pool |
| Default SNAT ports — pool 1–50 VMs | 1,024 per VM [VERIFY] | Capped at 1,024 regardless of additional frontend IPs |
| Default SNAT ports — pool 51–100 VMs | 512 per VM [VERIFY] | |
| Default SNAT ports — pool 101–200 VMs | 256 per VM [VERIFY] | |
| Default SNAT ports — pool 201–400 VMs | 128 per VM [VERIFY] | |
| Default SNAT ports — pool 401–800 VMs | 64 per VM [VERIFY] | |
| Default SNAT ports — pool 801–1,000 VMs | 32 per VM [VERIFY] | |
| SNAT idle timeout | 4–120 minutes | Configurable via outbound rules |
| Health probe source IP | 168.63.129.16 (IPv4) / fe80::1234:5678:9abc (IPv6 link-local) | Must be allowed in NSGs and host firewall |
| Health probe default interval | 5 seconds | |
| HTTP/S probe timeout | 30 seconds | |
| Standard LB SLA | 99.99% [VERIFY] | Requires ≥ 2 healthy backend instances per backend pool |
| Management operations (Standard) | < 30 seconds typical [VERIFY] | |
| Management operations (Basic, retired) | 60–90+ seconds typical [VERIFY] | |
| Backend pool scope | Single virtual network | Cannot span VNets directly |
| Subscription move | Not supported for Standard LB [VERIFY] | Resource group move (same subscription) is supported |
| Full service limits reference | [Azure subscription and service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#load-balancer) | |

---

## Architecture and components

```
Client
  │
  ▼
Frontend IP Configuration  ←── Public IP (public LB) or Private IP (internal LB)
  │
  ├─ Load Balancing Rules  ─────────────────────────────┐
  │    └── maps frontend IP:port → backend pool IP:port  │
  │    └── health probe attached                          │
  ├─ Inbound NAT Rules  ───────────────────────────────  │  → specific VM/instance
  └─ Outbound Rules  ──────────────────────────────────  │  → SNAT via frontend IP(s)
                                                          │
Backend Pool ◄────────────────────────────────────────── ┘
  ├── VMs (NIC-based or IP-based)
  └── VMSS instances
Health Probes (TCP / HTTP / HTTPS) → 168.63.129.16
```

**Distribution modes:**
- **5-tuple hash** (default): src IP, src port, dst IP, dst port, protocol → any healthy backend
- **2-tuple (client IP)**: same client IP → same backend instance
- **3-tuple (client IP + protocol)**: same client IP + protocol → same backend instance

---

## Outbound connectivity priority

| Priority | Method | Production-grade? |
|---|---|---|
| 1 (Best) | NAT Gateway on subnet | ✅ Yes |
| 2 | Instance-level public IP on VM NIC | ✅ Yes |
| 3 | LB frontend via explicit outbound rules | ✅ Yes, with scale limits |
| 4 | LB frontend implicit (no outbound rules) | ❌ No — SNAT exhaustion risk |
| 5 (Worst) | Default outbound access | ❌ No — retiring; IPs subject to change |

> **Important:** Default outbound access retires March 31, 2026 for new VNets. All VMs should have an explicit outbound method.

---

## Health probes

| Property | Details |
|---|---|
| Supported protocols | TCP, HTTP, HTTPS (HTTPS: Standard only) |
| Probe source IP | 168.63.129.16 (IPv4); use `AzureLoadBalancer` service tag in NSGs |
| Default interval | 5 seconds |
| HTTP/S timeout | 30 seconds |
| Probe down behavior (Standard) | Existing TCP flows continue; new flows to unhealthy instance stop |
| Probe down behavior (Basic, retired) | All TCP connections terminated when all probes down |
| All-probes-down (Standard) | Established TCP flows continue; UDP flows move to healthy instance |
| Blocked ports (HTTP probes) | 19, 21, 25, 70, 110, 119, 143, 220, 993 |
| HTTPS probe requirement | Certificate chain minimum SHA256 signature hash |
| Custom health logic | Return non-200 from HTTP/S probe to gracefully drain instance |

> ⚠️ **Known issue — `numberOfProbes` / "Unhealthy threshold" not respected:** The `numberOfProbes` property (shown as "Unhealthy threshold" in the Azure portal) is currently **not honored**. The load balancer marks a backend up or down after a single probe result, regardless of the configured value. **Mitigation:** Use the `probeThreshold` property (API version 2022-05-01 or higher) to control the number of consecutive successful or failed probes required before state change. The `numberOfProbes` property is also **retiring September 1, 2027**.

---

## Retirements and deprecations

| Feature | Retirement date | Action required |
|---|---|---|
| **Basic Load Balancer** | September 30, 2025 (**passed**) | Migrate all existing Basic LBs to Standard. New Basic deployments blocked since March 31, 2025. |
| **`numberOfProbes` property** | September 1, 2027 | Migrate to `probeThreshold` property using API version 2022-05-01 or higher. |
| **Inbound NAT rule V1** (for VMs and VMSS) | September 30, 2027 | Migrate to Inbound NAT rule V2. |
| **Default outbound access** (new VNets) | March 31, 2026 | Explicitly configure NAT Gateway, Standard LB outbound rules, or instance-level PIPs for all VMs. |

---

## Gateway Load Balancer specifics

| Property | Value |
|---|---|
| Frontend IP | Private only (no public frontend) |
| Rule type | HA ports only (protocol: All, port: 0) |
| Encapsulation | VXLAN |
| Tunnel interfaces | Up to 2 per backend pool (external = untrusted inbound, internal = trusted outbound) |
| Chaining | Reference from Standard Public LB frontend or Standard NIC IP config |
| Cross-tenant chaining | Supported via API/CLI/PS; not via portal |
| UDR as next hop | Not supported |
| Global tier compatibility | Not supported |
| IPv6 support | GA (September 2023) |
| MTU recommendation | ≥ 1550; up to 4000 for jumbo frame scenarios [VERIFY] |

---

## Global (cross-region) Load Balancer specifics

| Property | Value |
|---|---|
| Frontend | Public only (no internal global frontend) |
| Routing algorithm | Geo-proximity (closest participating region) |
| Backend pool members | Regional Standard LBs only (no private/internal) |
| Health check to regional LBs | Every 5 seconds |
| Failover | Automatic on regional LB availability = 0 |
| Static anycast IP | Yes; supports IPv4 and IPv6 |
| Client IP preservation | Yes (Layer-4 pass-through) |
| Outbound rules | Not supported at global tier; configure on regional LBs or NAT GW |
| NAT64 | Not supported |
| UDP port 3 | Not supported |
| Home regions (Azure) | Central US, East Asia, East US 2, North Europe, Southeast Asia, UK South, West Europe, West US, US Gov Virginia, China North 2 [VERIFY] |

---

## Monitoring metrics (Standard LB only)

| Metric | Scope | Aggregation | Notes |
|---|---|---|---|
| Data Path Availability | Public + Internal | Average | — |
| Health Probe Status | Public + Internal | Average | — |
| SYN Count | Public + Internal | Sum | Supports Protocol dimension filter (TCP=6, UDP=17) |
| SNAT Connection Count | Public | Sum | — |
| Allocated SNAT Ports | Public | Average | — |
| Used SNAT Ports | Public | Average | — |
| Byte Count | Public + Internal | Sum | Supports Protocol dimension filter (TCP=6, UDP=17) |
| Packet Count | Public + Internal | Sum | Supports Protocol dimension filter (TCP=6, UDP=17) |

> Note: Bandwidth metrics (SYN, byte, packet) do not capture traffic routed via UDR (e.g., from NVA/firewall to internal LB).

**Health event logs** (GA February 2025): Available under Azure Monitor resource log category `LoadBalancerHealthEvent`. Enables collection, storage, and analysis of LB health events. Use for troubleshooting availability issues and configuring alerts. Available in all public, China, and Government regions.

---

## Key operational guidance

- **NSGs are mandatory** on Standard external LB — no NSG = no inbound traffic (closed by default)
- **Unblock 168.63.129.16** in all NSGs and host firewalls for health probes to function
- **Use outbound rules with manual port allocation** to prevent SNAT exhaustion; default allocation is not production-safe
- **Enable TCP Reset** on all rules so application endpoints are notified of idle timeout instead of silent drop
- **Deploy with zone-redundancy** (zone-redundant Standard Public IP on frontend); SLA requires ≥ 2 healthy backend instances
- **Floating IP** requires loopback interface on guest OS configured with LB frontend IP
- **Admin State: Down** for zero-disruption maintenance — existing TCP connections persist, no new connections accepted
- **Gateway LB preferred over dual-LB setup** for NVA scenarios — no UDRs needed, flow symmetry guaranteed
- **Private Link**: use for private access to Azure PaaS to eliminate SNAT entirely
- **Replace `numberOfProbes` with `probeThreshold`**: `numberOfProbes` is not currently enforced (known issue) and retires September 2027. Use API version 2022-05-01+ and the `probeThreshold` property
- **Migrate Inbound NAT rule V1 → V2** by September 2027 for all VMs and VMSS

---

## Related services

- [NAT Gateway](nat-gateway.md) — preferred outbound connectivity method; supersedes LB outbound rules for scale
- [Application Gateway](application-gateway.md) — Layer-7 LB; HTTP(S) routing, WAF, TLS offload; use when path/host-based routing needed
- [Azure Firewall](azure-firewall.md) — can be deployed behind Gateway LB for NVA chaining
- [Private Link](private-link.md) — Standard Internal LB as origin; eliminates SNAT for PaaS access
- [DDoS Protection](ddos-protection.md) — Standard LB public IP can be protected; see [tutorial-protect-load-balancer-ddos](../../raw/articles/load-balancer/tutorial-protect-load-balancer-ddos.md)
- [Virtual Network](virtual-network.md) — LB backend pool scoped to single VNet; NSGs govern inbound access
- [Azure Monitor / Network Watcher](network-watcher.md) — multi-dimensional metrics, resource health, health event logs

---

## Source articles

- [What is Azure Load Balancer?](../../raw/articles/load-balancer/load-balancer-overview.md)
- [Azure Load Balancer SKUs](../../raw/articles/load-balancer/skus.md)
- [Azure Load Balancer components](../../raw/articles/load-balancer/components.md)
- [Source Network Address Translation (SNAT) for outbound connections](../../raw/articles/load-balancer/load-balancer-outbound-connections.md)
- [Global Load Balancer](../../raw/articles/load-balancer/cross-region-overview.md)
- [Gateway Load Balancer](../../raw/articles/load-balancer/gateway-overview.md)
- [High availability ports overview](../../raw/articles/load-balancer/load-balancer-ha-ports-overview.md)
- [Azure Load Balancer health probes](../../raw/articles/load-balancer/load-balancer-custom-probe-overview.md)
- [Azure Load Balancer distribution modes](../../raw/articles/load-balancer/distribution-mode-concepts.md)
- [Standard load balancer diagnostics](../../raw/articles/load-balancer/load-balancer-standard-diagnostics.md)
- [Azure Load Balancer Best Practices](../../raw/articles/load-balancer/load-balancer-best-practices.md)
- [Azure Load Balancer Floating IP configuration](../../raw/articles/load-balancer/load-balancer-floating-ip.md)
- [Administrative State (Admin State)](../../raw/articles/load-balancer/admin-state-overview.md)
- [Outbound rules](../../raw/articles/load-balancer/outbound-rules.md)
- [Inbound NAT rules](../../raw/articles/load-balancer/inbound-nat-rules.md)
- [Backend pool management](../../raw/articles/load-balancer/backend-pool-management.md)
- [Basic Load Balancer upgrade guidance](../../raw/articles/load-balancer/load-balancer-basic-upgrade-guidance.md)
- [What's new](../../raw/articles/load-balancer/whats-new.md) — delta read 2026-04-10 (entries through February 2026)
- *(+ 77 additional articles: quickstarts, tutorials, troubleshooting, cross-subscription, IPv6, move-across-regions, IMDS, monitor reference, TCP reset, idle timeout, health event logs, insights, and more)*
```

---

## ✅ RECOMPILE 3 — Azure Bastion

**File:** `wiki/services/bastion.md`

```markdown