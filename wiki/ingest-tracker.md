# Azure Networking KB — Ingest Tracker

Per-service raw article sync status and wiki compilation state.

> **Last raw sync:** 2026-04-09 | **Total articles:** 1,554 | **All wiki pages:** populated

---

## Status legend

| Symbol | Meaning |
|---|---|
| ✅ | Wiki compiled, source articles current |
| 🟡 | Wiki compiled, some source articles may be newer than compiled date |
| 🔴 | Stale — source articles significantly newer than compiled wiki |
| 🔲 | Stub — not yet compiled |

Run `.\scripts\check-kb-freshness.ps1` to regenerate staleness flags.

---

## Services

| Service | Raw path | Articles | Latest ms.date | Wiki page | Wiki compiled | Status |
|---|---|---|---|---|---|---|
| Application Gateway | `raw/articles/application-gateway/` | 175 | 2025-08-25 | [application-gateway.md](services/application-gateway.md) | 2026-04-10 | ✅ |
| Azure Bastion | `raw/articles/bastion/` | 41 | 2025-12-10 | [bastion.md](services/bastion.md) | 2026-04-10 | ✅ |
| DDoS Protection | `raw/articles/ddos-protection/` | 32 | 2025-07-08 | [ddos-protection.md](services/ddos-protection.md) | 2026-04-08 | ✅ |
| Azure DNS | `raw/articles/dns/` | 73 | 2023-04-14 | [dns.md](services/dns.md) | 2026-04-09 | 🟡 |
| ExpressRoute | `raw/articles/expressroute/` | 92 | 2024-06-11 | [expressroute.md](services/expressroute.md) | 2026-04-10 | ✅ |
| Azure Firewall | `raw/articles/firewall/` | 85 | 2025-07-01 | [azure-firewall.md](services/azure-firewall.md) | 2026-04-09 | ✅ |
| Azure Firewall Manager | `raw/articles/firewall-manager/` | 27 | 2024-12-03 | [firewall-manager.md](services/firewall-manager.md) | 2026-04-10 | ✅ |
| Azure Front Door | `raw/articles/frontdoor/` | 102 | 2021-12-30 | [front-door.md](services/front-door.md) | 2026-04-09 | ✅ |
| Internet Peering | `raw/articles/internet-peering/` | 23 | 2026-02-25 | [internet-peering.md](services/internet-peering.md) | 2026-04-09 | ✅ |
| Azure Load Balancer | `raw/articles/load-balancer/` | 94 | 2024-12-06 | [load-balancer.md](services/load-balancer.md) | 2026-04-10 | ✅ |
| NAT Gateway | `raw/articles/nat-gateway/` | 27 | 2024-12-02 | [nat-gateway.md](services/nat-gateway.md) | 2026-04-08 | ✅ |
| Network Function Manager | `raw/articles/network-function-manager/` | 8 | 2021-11-02 | [network-function-manager.md](services/network-function-manager.md) | 2026-04-10 | ✅ |
| Network Watcher | `raw/articles/network-watcher/` | 64 | 2025-12-18 | [network-watcher.md](services/network-watcher.md) | 2026-04-09 | ✅ |
| Networking (cross-service) | `raw/articles/networking/` | 60 | 2022-12-31 | [azure-networking-fundamentals.md](concepts/azure-networking-fundamentals.md) | 2026-04-10 | ✅ |
| Peering Service | `raw/articles/peering-service/` | 9 | 2026-02-25 | [peering-service.md](services/peering-service.md) | 2026-04-10 | ✅ |
| Private Link | `raw/articles/private-link/` | 48 | 2025-10-08 | [private-link.md](services/private-link.md) | 2026-04-09 | ✅ |
| Azure Route Server | `raw/articles/route-server/` | 21 | 2025-10-31 | [route-server.md](services/route-server.md) | 2026-04-10 | ✅ |
| Traffic Manager | `raw/articles/traffic-manager/` | 44 | 2023-06-08 | [traffic-manager.md](services/traffic-manager.md) | 2026-04-09 | 🟡 |
| Azure Virtual Network | `raw/articles/virtual-network/` | 128 | 2024-12-11 | [virtual-network.md](services/virtual-network.md) | 2026-04-09 | ✅ |
| Virtual Network Manager | `raw/articles/virtual-network-manager/` | 52 | 2024-12-31 | [virtual-network-manager.md](services/virtual-network-manager.md) | 2026-04-10 | ✅ |
| Virtual WAN | `raw/articles/virtual-wan/` | 133 | 2025-12-30 | [virtual-wan.md](services/virtual-wan.md) | 2026-04-10 | ✅ |
| VPN Gateway | `raw/articles/vpn-gateway/` | 122 | 2026-02-27 | [vpn-gateway.md](services/vpn-gateway.md) | 2026-04-09 | ✅ |
| Web Application Firewall | `raw/articles/web-application-firewall/` | 77 | 2020-12-09 | [web-application-firewall.md](services/web-application-firewall.md) | 2026-04-10 | 🟡 |

---

## Notes

- **DNS (🟡):** Compiled 2026-04-09, source latest ms.date is 2023 — source articles are older than compiled date; no action needed.
- **Traffic Manager (🟡):** Same situation — ms.dates are from 2023, compiled wiki is more recent.
- **Web Application Firewall (🟡):** Source ms.dates from 2020; wiki compiled 2026-04-10. Source articles may be significantly outdated vs current product.
- Run `.\scripts\check-kb-freshness.ps1 -StaleOnly` for automated detection of services where new source articles have been published since last compile.

---

> To update this file: re-run the manifest data extraction script or ask Atlas to refresh it.
