# Azure Networking Knowledge Base

> An AI-compiled, human-readable knowledge base for Azure Networking — built on Karpathy's LLM-KB architecture. No vector DB. No embeddings. Just structured markdown maintained by a squad of AI agents.

[![Squad](https://img.shields.io/badge/powered%20by-squad-blueviolet)](https://github.com/duongau/squad)

---

## What is this?

This repo is a **living knowledge base** for Azure Networking content teams. AI agents compile and maintain it:

| Agent | Role |
|---|---|
| **Atlas** | Compiler — reads raw Azure docs articles and compiles them into structured wiki pages |
| **Lore** | Librarian — health-checks the wiki for dead links, stale content, and coverage gaps |

The output (`wiki/`) is plain markdown — readable in any editor, searchable with grep, and committable to git.

---

## Current status

> **Coverage: 23 / 23 services · 17 concepts · 10 comparisons · 8 patterns · 4 decision guides · 4 limits/tracking references · 23 source summaries** as of 2026-04-10. See [`wiki/index.md`](wiki/index.md) for the full index.

| Service | Raw articles | Wiki page | Status |
|---|---|---|---|
| Azure Virtual Network | 128 | `wiki/services/virtual-network.md` | ✅ compiled |
| ExpressRoute | 92 | `wiki/services/expressroute.md` | ✅ compiled |
| VPN Gateway | 107 | `wiki/services/vpn-gateway.md` | ✅ compiled |
| Azure Firewall | 86 | `wiki/services/azure-firewall.md` | ✅ compiled |
| Application Gateway | 175 | `wiki/services/application-gateway.md` | ✅ compiled |
| Azure Load Balancer | 94 | `wiki/services/load-balancer.md` | ✅ compiled |
| NAT Gateway | 27 | `wiki/services/nat-gateway.md` | ✅ compiled |
| Azure Bastion | 41 | `wiki/services/bastion.md` | ✅ compiled |
| Private Link | 48 | `wiki/services/private-link.md` | ✅ compiled |
| DDoS Protection | 32 | `wiki/services/ddos-protection.md` | ✅ compiled |
| Azure DNS | 69 | `wiki/services/dns.md` | ✅ compiled |
| Network Watcher | 64 | `wiki/services/network-watcher.md` | ✅ compiled |
| Azure Front Door | 102 | `wiki/services/front-door.md` | ✅ compiled |
| Traffic Manager | 45 | `wiki/services/traffic-manager.md` | ✅ compiled |
| Virtual WAN | 133 | `wiki/services/virtual-wan.md` | ✅ compiled |
| Azure Route Server | 21 | `wiki/services/route-server.md` | ✅ compiled |
| Web Application Firewall | 77 | `wiki/services/web-application-firewall.md` | ✅ compiled |
| Azure Firewall Manager | 27 | `wiki/services/firewall-manager.md` | ✅ compiled |
| Virtual Network Manager | 52 | `wiki/services/virtual-network-manager.md` | ✅ compiled |
| Internet Peering | 23 | `wiki/services/internet-peering.md` | ✅ compiled |
| Peering Service | 9 | `wiki/services/peering-service.md` | ✅ compiled |
| Network Function Manager | 8 | `wiki/services/network-function-manager.md` | ✅ compiled |
| Networking (cross-service) | 60 | `wiki/concepts/azure-networking-fundamentals.md` | ✅ compiled |

### Concept pages

| Concept | Wiki page | Status |
|---|---|---|
| Azure Networking Fundamentals | `wiki/concepts/azure-networking-fundamentals.md` | ✅ compiled |
| Hub-spoke topology | `wiki/concepts/hub-spoke-networking.md` | ✅ compiled |
| Hybrid connectivity | `wiki/concepts/hybrid-connectivity.md` | ✅ compiled |
| IP addressing | `wiki/concepts/ip-addressing.md` | ✅ compiled |
| Network security design | `wiki/concepts/network-security-design.md` | ✅ compiled |
| Routing | `wiki/concepts/routing.md` | ✅ compiled |
| Private access to PaaS | `wiki/concepts/private-access-to-paas.md` | ✅ compiled |
| Monitoring | `wiki/concepts/monitoring.md` | ✅ compiled |
| SNAT in Azure | `wiki/concepts/snat.md` | ✅ compiled |
| BGP and dynamic routing | `wiki/concepts/bgp-dynamic-routing.md` | ✅ compiled |
| User-defined routes (UDRs) | `wiki/concepts/user-defined-routes.md` | ✅ compiled |
| Network Security Groups (NSGs) | `wiki/concepts/network-security-groups.md` | ✅ compiled |
| VNet peering | `wiki/concepts/vnet-peering.md` | ✅ compiled |
| DNS zones and records | `wiki/concepts/dns-zones-and-records.md` | ✅ compiled |
| Flow logs | `wiki/concepts/flow-logs.md` | ✅ compiled |
| Service endpoints | `wiki/concepts/service-endpoints.md` | ✅ compiled |
| VNet encryption | `wiki/concepts/vnet-encryption.md` | ✅ compiled |

### Comparisons

| Comparison | Wiki page | Status |
|---|---|---|
| Load balancing options | `wiki/comparisons/load-balancing-options.md` | ✅ compiled |
| VPN Gateway vs ExpressRoute | `wiki/comparisons/vpn-gateway-vs-expressroute.md` | ✅ compiled |
| Azure Firewall vs NSG | `wiki/comparisons/firewall-vs-nsg.md` | ✅ compiled |
| Azure Firewall SKU comparison | `wiki/comparisons/firewall-sku-comparison.md` | ✅ compiled |
| Virtual WAN vs hub-spoke | `wiki/comparisons/virtual-wan-vs-hub-spoke.md` | ✅ compiled |
| Private Endpoint vs Service Endpoint | `wiki/comparisons/private-endpoints-vs-service-endpoints.md` | ✅ compiled |
| Application Gateway vs Front Door | `wiki/comparisons/app-gateway-vs-front-door.md` | ✅ compiled |
| Azure Front Door vs Traffic Manager | `wiki/comparisons/front-door-vs-traffic-manager.md` | ✅ compiled |
| DDoS IP Protection vs Network Protection | `wiki/comparisons/ddos-ip-vs-network-protection.md` | ✅ compiled |
| Private DNS Resolver vs custom DNS | `wiki/comparisons/private-dns-resolver-vs-custom-dns.md` | ✅ compiled |

### Patterns

| Pattern | Wiki page | Status |
|---|---|---|
| Hub-spoke with Azure Firewall | `wiki/patterns/hub-spoke-with-firewall.md` | ✅ compiled |
| NAT Gateway in hub-spoke | `wiki/patterns/nat-gateway-hub-spoke.md` | ✅ compiled |
| Hybrid DNS resolution | `wiki/patterns/dns-hybrid-resolution.md` | ✅ compiled |
| ExpressRoute resiliency patterns | `wiki/patterns/expressroute-resiliency-patterns.md` | ✅ compiled |
| Multi-region active-active with Front Door | `wiki/patterns/multi-region-front-door.md` | ✅ compiled |
| Zero Trust application delivery | `wiki/patterns/zero-trust-app-delivery.md` | ✅ compiled |
| Enterprise-scale hub-spoke with AVNM | `wiki/patterns/avnm-enterprise-scale.md` | ✅ compiled |
| Private AKS cluster networking | `wiki/patterns/private-aks-networking.md` | ✅ compiled |

### Decision guides

| Decision | Wiki page | Status |
|---|---|---|
| Connectivity options | `wiki/decisions/connectivity-options.md` | ✅ compiled |
| Load balancing options | `wiki/decisions/load-balancing-options.md` | ✅ compiled |
| Firewall & security options | `wiki/decisions/firewall-and-security-options.md` | ✅ compiled |
| Private access options | `wiki/decisions/private-access-options.md` | ✅ compiled |

### Limits & SKU reference

| Article | Wiki page | Status |
|---|---|---|
| SKU comparison | `wiki/limits-and-skus/sku-comparison.md` | ✅ compiled |
| Service limits quick reference | `wiki/limits-and-skus/service-limits-quick-reference.md` | ✅ compiled |
| Retirement and deprecation tracker | `wiki/limits-and-skus/retirement-tracker.md` | ✅ compiled |
| [VERIFY] queue | `wiki/limits-and-skus/verify-queue.md` | ✅ compiled |

### Source summaries

Per-service summaries of raw source material: article counts, coverage strengths, gaps, and links to compiled wiki pages. Located in `wiki/sources/` — one file per service.

---

## Resuming work (Copilot CLI)

This project is maintained using **GitHub Copilot CLI** with the `Content Developer` agent and Atlas sub-agent.

```powershell
cd "C:\GitHub\azure-networking-kb"
# Then say: "hey squad where did we leave off with this?"
```

### Sync raw articles from azure-docs-pr

```powershell
cd "C:\GitHub\azure-networking-kb"
.\scripts\sync-raw.ps1
# Syncs all 23 configured services from C:\GitHub\azure-docs-pr
# To add a new service: .\scripts\sync-raw.ps1 -Services @('new-service-name')
```

### Check for stale wiki pages

```powershell
cd "C:\GitHub\azure-networking-kb"
.\scripts\check-kb-freshness.ps1              # full report across all services
.\scripts\check-kb-freshness.ps1 -StaleOnly   # only services where source is newer than compiled wiki
.\scripts\check-kb-freshness.ps1 -Threshold 30  # only flag if source is >30 days newer
```

### Connected systems

| System | Location | Notes |
|---|---|---|
| **RAG server** | `C:\GitHub\Azure Networking DB\` | Vector DB for semantic search over compiled KB |
| **v4 writing pipeline** | `C:\GitHub\Azure Networking Design\v4-modular-reference\` | Consumes this KB for article drafting |
| **azure-docs-pr** | `C:\GitHub\azure-docs-pr\` | Source of truth for raw articles |

---

## Repo structure

```
azure-networking-kb/
├── raw/
│   ├── manifest.json        # Tracks 1,554 ingested articles + wiki_page mappings
│   └── articles/            # Source articles copied from azure-docs-pr (23 services)
├── wiki/
│   ├── index.md             # Master index — start here
│   ├── log.md               # Chronological operations log
│   ├── health-report.md     # Latest Lore health check output
│   ├── services/            # 23 per-service compiled summaries
│   ├── concepts/            # 17 concept pages (SNAT, BGP, UDRs, NSGs, peering, DNS, flow logs, etc.)
│   ├── comparisons/         # 7 decision matrices (Firewall vs NSG, VWAN vs hub-spoke, etc.)
│   ├── patterns/            # 4 deployment pattern pages with architecture diagrams
│   ├── decisions/           # 4 decision guides (which service to use when?)
│   ├── limits-and-skus/     # 2 SKU comparison and service limits reference pages
│   └── sources/             # 23 per-service source summaries (article counts, coverage gaps)
├── scripts/
│   ├── sync-raw.ps1             # Sync networking articles from azure-docs-pr
│   └── check-kb-freshness.ps1   # Staleness detection: compare source ms.date vs wiki compiled date
```

---

## How it connects to article writing

This KB feeds the **v4 Azure Networking Design Guide** writing pipeline. The Networking Writer squad agent reads `wiki/services/` and `wiki/decisions/` before drafting articles.

```
azure-docs-pr  ──►  raw/articles/  ──►  Atlas  ──►  wiki/services/
                    (sync-raw.ps1)                        │
                                                          ▼
                                          Networking Writer → v4 design guide articles
```

---

## Contributing

- To add new source articles: run `sync-raw.ps1 -Services @('service-name')`
- To trigger a wiki recompile: ask Atlas via Copilot CLI
- To report a wiki issue: open a GitHub issue with label `wiki-gap` or `wiki-stale`
- To run a health check: `Lore, run a full wiki health check and write findings to wiki/health-report.md`
