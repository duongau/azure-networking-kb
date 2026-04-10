# Azure networking — retirement and deprecation tracker

> **Last updated:** 2026-04-10 | **Sources:** compiled from all 23 service wiki pages | **Status:** ✅ current

Use this page to quickly find retirement dates, migration paths, and urgency levels for Azure Networking features and SKUs. All items sourced from compiled wiki service pages — verify against official Microsoft communications before taking action.

## Status legend

| Status | Meaning |
|---|---|
| 🔴 **Past retirement** | Feature/SKU is already retired or sunset |
| 🟠 **Imminent** | Retiring within 6 months of last update |
| 🟡 **Upcoming** | Retiring within 12 months |
| 🟢 **Announced** | Retirement date confirmed, >12 months away |
| ⚠️ **Blocking** | New deployments already blocked |

---

## Retirement index

| Service | Item | Status | Date | Migration path | Impact |
|---|---|---|---|---|---|
| **Application Gateway** | V1 SKU (Standard, WAF) | 🟠 Imminent | Apr 28, 2026 | Migrate to v2 (Standard_v2 / WAF_v2) | New V1 deployments blocked since Sep 1, 2024 |
| **Load Balancer** | Basic SKU | 🔴 Past | Sep 30, 2025 | Migrate to Standard | New deployments blocked since Mar 31, 2025 |
| **Load Balancer** | `numberOfProbes` property | 🟢 Announced | Sep 1, 2027 | Use `probeThreshold` (API 2022-05-01+) | Property currently not enforced (known bug) |
| **Load Balancer** | Inbound NAT Rule V1 (VMs/VMSS) | 🟢 Announced | Sep 30, 2027 | Migrate to Inbound NAT Rule V2 | — |
| **VPN Gateway** | Standard SKU (legacy) | 🟠 Imminent | Mar 31, 2026 | Auto-migrates to VpnGw1AZ | — |
| **VPN Gateway** | High Performance SKU (legacy) | 🟠 Imminent | Mar 31, 2026 | Auto-migrates to VpnGw2AZ | — |
| **VPN Gateway** | Non-AZ SKUs (VpnGw1–5) | 🟡 Upcoming | Sep 16, 2026 | Manual upgrade to AZ SKUs recommended | New creations blocked Nov 1, 2025; auto-migrate if not upgraded |
| **VPN Gateway** | Policy-based gateway (portal) | 🔴 Past | Oct 1, 2023 | Use route-based; CLI/PowerShell only for policy-based | — |
| **VPN Gateway** | Basic SKU Public IP on non-Basic gateways | 🟡 Upcoming | End Jun 2026 | Migrate to Standard SKU Public IP | — |
| **VPN Gateway** | Classic VPN Gateway | 🔴 Past | Aug 2024 – Aug 2025 | Migrate to ARM-based gateway | — |
| **Virtual Network** | Default outbound access (new VNets) | 🟠 Imminent | Mar 31, 2026 | Use NAT Gateway, Standard LB outbound rules, or instance-level PIPs | New VNets default to private subnets |
| **Virtual Network** | Basic SKU Public IP | 🔴 Past | Sep 30, 2025 | Migrate to Standard SKU | [VERIFY] |
| **Front Door** | Classic SKU | 🟢 Announced | Mar 31, 2027 | Zero-downtime migration tool available | No new Classic profiles after Apr 1, 2025; managed certs end Aug 15, 2025 |
| **Front Door** | Classic managed certificates | 🟠 Imminent | Aug 15, 2025 | Migrate to Standard/Premium before this date | Certs valid until Apr 14, 2026 after cutoff |
| **Front Door** | DHE cipher suites | 🟠 Imminent | Apr 1, 2026 | Update TLS config to non-DHE ciphers | `TLS_DHE_RSA_WITH_AES_*` suites removed |
| **Network Watcher** | Connection Monitor (Classic) | 🔴 Past | Already retired | Use Connection Monitor (new) | — |
| **Network Watcher** | Network Performance Monitor | 🔴 Past | Jul 1, 2021 | Use Connection Monitor or Azure Monitor | — |
| **Network Watcher** | NSG Flow Logs | 🟡 Upcoming | Migration recommended | Use VNet Flow Logs | NSG Flow Logs marked as retiring in docs |
| **Network Function Manager** | Entire service | 🔴 Past | Oct 1, 2025 | No replacement; do not design new solutions | Service was sunset |
| **WAF** | CRS 2.2.9 ruleset | 🔴 Past | Mar 2025 | Upgrade to DRS 2.x or CRS 3.2 | — |
| **WAF** | CRS 3.0 / 3.1 / DRS 1.x rulesets | 🟢 Announced | Feb 26, 2027 | Upgrade to DRS 2.x or CRS 3.2+ | App Gateway and Front Door |
| **Traffic Manager** | TLS 1.0 / 1.1 | 🔴 Past | Feb 28, 2025 | Use TLS 1.2+ | — |
| **Traffic Manager** | Traffic View (Sovereign clouds) | 🔴 Past | Mar 15, 2025 | Public cloud only | — |
| **Application Gateway** | TLS 1.0 / 1.1 (frontend) | 🔴 Past | Aug 31, 2025 | TLS 1.2+ required | [VERIFY] |

---

## Detail sections

### Application Gateway

#### V1 SKU retirement — April 28, 2026

**Status:** 🟠 Imminent

| Detail | Value |
|---|---|
| Retirement date | April 28, 2026 |
| New deployments blocked | September 1, 2024 |
| Affected SKUs | Standard (v1), WAF (v1) — Small, Medium, Large sizes |
| Migration target | Standard_v2, WAF_v2 |
| Migration guidance | [Migrate from V1 to V2](../../raw/articles/application-gateway/v1-retirement.md) |

**Why migrate:**
- V1 lacks: autoscaling, zone redundancy, static VIP, Key Vault integration, mTLS, header/URL rewrite, Private Link, AGIC, custom WAF rules, TCP/TLS proxy
- V2 has faster scale-out, better performance, modern feature set
- V1 throughput is significantly lower (7.5–200 Mbps depending on size vs. 62,500 CPS on v2)

---

### Load Balancer

#### Basic SKU retirement — September 30, 2025 (PAST)

**Status:** 🔴 Past retirement

| Detail | Value |
|---|---|
| Retirement date | September 30, 2025 |
| New deployments blocked | March 31, 2025 |
| Migration target | Standard SKU |
| Migration guidance | [Basic Load Balancer upgrade guidance](../../raw/articles/load-balancer/load-balancer-basic-upgrade-guidance.md) |

**What Basic lacked:**
- No Availability Zone support
- No HTTPS health probes
- No outbound rules
- No HA ports
- No diagnostics / multi-dimensional metrics
- No SLA
- Open to inbound by default (security risk)

#### `numberOfProbes` property — September 1, 2027

**Status:** 🟢 Announced

The `numberOfProbes` property (shown as "Unhealthy threshold" in the Azure portal) is **currently not enforced** — this is a known bug. The load balancer marks backends up/down after a single probe result regardless of the configured value.

**Action required:**
- Use the `probeThreshold` property instead (API version 2022-05-01 or higher)
- Both properties will be honored after full enforcement
- `numberOfProbes` retires September 1, 2027

#### Inbound NAT Rule V1 — September 30, 2027

**Status:** 🟢 Announced

Inbound NAT Rule V1 for VMs and VMSS will be retired. Migrate to Inbound NAT Rule V2.

---

### VPN Gateway

#### Legacy Standard and High Performance SKUs — March 31, 2026

**Status:** 🟠 Imminent

| SKU | Throughput | Max tunnels | Migrates to |
|---|---|---|---|
| Standard | 100 Mbps | 10 | VpnGw1AZ |
| High Performance | 200 Mbps | 30 | VpnGw2AZ |

**Migration path:** Auto-migration via Basic IP migration process if not manually upgraded.

#### Non-AZ SKUs (VpnGw1–5) — September 16, 2026

**Status:** 🟡 Upcoming (new creation already blocked)

| Event | Date |
|---|---|
| New creations blocked | November 1, 2025 |
| Manual migration period | September 2025 – September 2026 |
| Auto-migration | September 16, 2026 |

**Action required:** Manually upgrade to AZ-equivalent SKUs (VpnGw1AZ–5AZ) during the migration window for controlled upgrade timing. Auto-migration preserves functionality but occurs during Microsoft-chosen window.

---

### Virtual Network

#### Default outbound access — March 31, 2026 (new VNets)

**Status:** 🟠 Imminent

Starting March 31, 2026, new virtual networks created with API versions after this date will default to **private subnets** — no implicit default outbound internet access.

**Action required:**
- All VMs must have an explicit outbound method:
  1. **NAT Gateway** (recommended) — highest scale, deterministic IPs
  2. **Standard LB with outbound rules** — good for existing LB deployments
  3. **Instance-level public IP** — per-VM, useful for specific workloads

**Risks of default outbound access (why it's being retired):**
- IPs subject to change without notice
- No ICMP support
- No fragmented packet support
- Not production-safe

#### Basic SKU Public IP — September 30, 2025 (PAST)

**Status:** 🔴 Past retirement

Migrate all Basic SKU public IPs to Standard SKU. Standard requires NSGs to allow inbound traffic (closed by default).

---

### Azure Front Door

#### Classic SKU retirement timeline

**Status:** 🟢 Announced (final retirement) / 🟠 Imminent (managed cert cutoff)

| Milestone | Date | Impact |
|---|---|---|
| No new Classic profiles | April 1, 2025 | New profiles must be Standard/Premium |
| No new domain onboarding | August 15, 2025 | Cannot add new custom domains |
| Managed certificates cease | August 15, 2025 | No new managed certs issued |
| Existing managed cert expiry | April 14, 2026 | After Aug 15, 2025 cutoff |
| Full service retirement | March 31, 2027 | All access and support ends |

**Migration:** Zero-downtime migration tool available in Azure portal and PowerShell.

---

### Network Watcher

#### Connection Monitor (Classic) — Already retired

**Status:** 🔴 Past retirement

The classic Connection Monitor has been retired. Use the new Connection Monitor which supports:
- Azure and hybrid (Arc-enabled) endpoints
- TCP, ICMP, and HTTP protocols
- Azure Monitor integration

#### Network Performance Monitor — July 1, 2021

**Status:** 🔴 Past retirement

Use Connection Monitor or Azure Monitor for network performance monitoring.

#### NSG Flow Logs — Migration recommended

**Status:** 🟡 Upcoming (migration recommended)

NSG Flow Logs are marked as retiring in documentation. Migrate to **VNet Flow Logs** which provide:
- Virtual network-level scope (vs. per-NSG)
- AVNM security admin rule coverage
- Encryption state reporting

**Action:** Disable NSG flow logs before enabling VNet flow logs to avoid duplicate logging.

---

### Network Function Manager

#### Service sunset — October 1, 2025

**Status:** 🔴 Past retirement

Azure Network Function Manager (NFM) was sunset on October 1, 2025. Do not design new solutions around this service. There is no direct replacement — consider alternative architectures for edge network function deployment.

---

### WAF (Web Application Firewall)

#### Ruleset retirements

| Ruleset | End of support | Platform | Action |
|---|---|---|---|
| CRS 2.2.9 | March 2025 ✓ | App Gateway | Upgrade to CRS 3.2 or DRS 2.x |
| CRS 3.0 / 3.1 | February 26, 2027 | App Gateway | Upgrade to CRS 3.2 or DRS 2.x |
| DRS 1.x | February 26, 2027 | App Gateway + Front Door | Upgrade to DRS 2.x |
| Bot Manager 0.1 | Not supported | All | Use Bot Manager 1.0 or 1.1 |

---

### Traffic Manager

#### TLS 1.0 / 1.1 support ended — February 28, 2025

**Status:** 🔴 Past retirement

Traffic Manager now requires TLS 1.2 or higher for all connections.

#### Traffic View in Sovereign clouds — March 15, 2025

**Status:** 🔴 Past retirement

Traffic View feature is now available in public cloud only. Removed from Azure Government and Azure China.

---

## Cross-cutting retirements

### Basic SKU Public IPs

Multiple services have transitioned away from Basic SKU public IPs:

| Service | Impact | Standard SKU requirement |
|---|---|---|
| Load Balancer | Basic LB retired | Standard LB requires Standard PIP |
| VPN Gateway | Basic PIP retiring Jun 2026 | Standard PIP required |
| Bastion | Basic/Standard/Premium SKUs | Standard PIP required |
| NAT Gateway | All deployments | Standard PIP required |

### TLS 1.0/1.1 deprecation

| Service | TLS 1.2+ required date |
|---|---|
| Traffic Manager | February 28, 2025 |
| Application Gateway | August 31, 2025 [VERIFY] |
| Front Door | Always (TLS 1.2 minimum) |
| Azure Firewall | TLS 1.2+ for TLS inspection |

---

## Action checklist

### Immediate (within 3 months)

- [ ] Migrate Application Gateway V1 to V2 (Apr 28, 2026)
- [ ] Migrate VPN Gateway Standard/High Performance to AZ SKUs (Mar 31, 2026)
- [ ] Implement explicit outbound access for all VMs (Mar 31, 2026 for new VNets)
- [ ] Migrate Front Door Classic before managed cert cutoff (Aug 15, 2025)
- [ ] Update Front Door TLS config for DHE cipher removal (Apr 1, 2026)

### Near-term (within 12 months)

- [ ] Upgrade VPN Gateway non-AZ SKUs before auto-migration (Sep 16, 2026)
- [ ] Migrate NSG Flow Logs to VNet Flow Logs
- [ ] Upgrade WAF rulesets to DRS 2.x or CRS 3.2+

### Planning (>12 months)

- [ ] Update Load Balancer configs to use `probeThreshold` before `numberOfProbes` retirement (Sep 1, 2027)
- [ ] Migrate Inbound NAT Rule V1 to V2 (Sep 30, 2027)
- [ ] Complete Front Door Classic migration (Mar 31, 2027)

---

## Source pages

| Service | Wiki page |
|---|---|
| Application Gateway | [application-gateway.md](../services/application-gateway.md) |
| Load Balancer | [load-balancer.md](../services/load-balancer.md) |
| VPN Gateway | [vpn-gateway.md](../services/vpn-gateway.md) |
| Virtual Network | [virtual-network.md](../services/virtual-network.md) |
| Front Door | [front-door.md](../services/front-door.md) |
| Network Watcher | [network-watcher.md](../services/network-watcher.md) |
| Network Function Manager | [network-function-manager.md](../services/network-function-manager.md) |
| WAF | [web-application-firewall.md](../services/web-application-firewall.md) |
| Traffic Manager | [traffic-manager.md](../services/traffic-manager.md) |
