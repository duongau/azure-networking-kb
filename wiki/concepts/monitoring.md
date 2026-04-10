# Azure Network Monitoring

> **Compiled:** 2026-04-10 | **Source articles:** 4 | **Status:** current

## What it is

Azure network monitoring is layered across two tightly integrated surfaces: **Azure Network Watcher** (the primary IaaS monitoring and diagnostic engine) and **Azure Monitor Network Insights** (the visualization and aggregation layer built on top of Azure Monitor). Together they cover topology visualization, end-to-end connectivity monitoring, traffic logging and analysis, and a suite of on-demand diagnostic tools. Network Watcher is scoped to **IaaS resources only** — it is explicitly not designed for PaaS monitoring or web analytics.

---

## Key capabilities

### Azure Network Watcher — Three capability areas

#### Monitoring

| Tool | What it does |
|---|---|
| **Topology** | Interactive visual map of all network resources and their relationships, spanning subscriptions, regions, and resource groups |
| **Connection Monitor** | Continuous end-to-end connectivity and latency monitoring over TCP, ICMP, and HTTP for Azure and hybrid (Arc-enabled) endpoints; replaces deprecated Connection Monitor (Classic) and Network Performance Monitor |

#### Network Diagnostic Tools (7 tools)

| Tool | What it does | Primary use case |
|---|---|---|
| **IP Flow Verify** | Checks allow/deny at VM NIC for a specific 5-tuple; returns matching NSG rule name | "Why is my traffic being blocked at this VM?" |
| **NSG Diagnostics** | Simulates traffic against NSG rules for VM, VMSS, App Gateway; supports IP prefixes and service tags; can suggest new rules | Deeper NSG analysis across multiple levels |
| **Next Hop** | Returns next hop type, IP, and route table ID for a given destination from a VM NIC | "Is my traffic being routed correctly?" |
| **Effective Security Rules** | Aggregated view of all NSG rules applied to a NIC (NIC-level + subnet-level + AVNM admin rules) | Full NSG ruleset audit per NIC |
| **Connection Troubleshoot** | Point-in-time connectivity test from VM/VMSS/App Gw v2/Bastion to VM, FQDN, URI, or IP; returns latency, hop-by-hop topology, and fault types | One-time connectivity test without ongoing monitoring |
| **Packet Capture** | Remote capture sessions on VMs or VMSS; saves to local disk or Azure Storage; 5-tuple filtering | Deep packet inspection for troubleshooting |
| **VPN Troubleshoot** | Diagnoses virtual network gateways and their connections; writes results to a storage account | VPN gateway/connection failures |

#### Traffic

| Tool | What it does | Notes |
|---|---|---|
| **NSG Flow Logs** | Layer-4 JSON logs of IP traffic per NSG rule, 1-min intervals | ⚠️ **RETIRING** — migrate to VNet Flow Logs |
| **VNet Flow Logs** | Layer-4 JSON logs of IP traffic scoped to an entire virtual network; covers AVNM security admin rules and encryption status | Successor to NSG Flow Logs; preferred |
| **Traffic Analytics** | Aggregates and enriches flow log data in Log Analytics; provides geo, security, topology, and performance insights via dashboards | Requires Log Analytics workspace |

---

### Azure Monitor Network Insights — Five components

Azure Monitor Network Insights provides a **zero-configuration** visual dashboard of all networking resources across subscriptions. No setup required to see basic health and metrics.

| Component | What it provides |
|---|---|
| **Topology** | Visual representation of VNets and connected resources; drill down to individual resource-level traffic and connectivity insights |
| **Network health and metrics** | Inventory of all network resource types with health status and alert counts; filterable by subscription, resource group, type |
| **Connectivity** | Visualization of all Connection Monitor tests across subscriptions; reachability status, RTT, checks-failed % |
| **Traffic** | Lists NSGs configured for flow logs and Traffic Analytics; regional tile view; search by IP address |
| **Diagnostic Toolkit** | Drop-down access to all Network Watcher diagnostic tools (packet capture, VPN troubleshoot, connection troubleshoot, next hop, IP flow verify) |

**Onboarded resources** (get topology view + built-in metrics workbook):
Application Gateway, Azure Bastion, Azure Firewall, Azure Front Door, Azure NAT Gateway, ExpressRoute, Load Balancer, Local Network Gateway, Network Interface, Network Security Group, Private Link, Public IP address, Route table/UDR, Traffic Manager, Virtual Hub, Virtual Network, Virtual Network Gateway (ER+VPN), Virtual WAN

---

### Traffic Analytics — Detail

Traffic Analytics processes raw flow logs to provide actionable network intelligence.

| Capability | Details |
|---|---|
| **Data flow** | Flow logs → aggregated by 5-tuple common flows → enriched with geography, security, topology → stored in Log Analytics workspace |
| **Security insights** | Identifies: open ports, VMs attempting internet access, VMs connecting to rogue networks, malicious traffic indicators |
| **Traffic insights** | Most-communicating hosts, protocols, host pairs; allowed vs blocked; inbound vs outbound; traffic distribution per datacenter/VNet/subnet |
| **Capacity planning** | Traffic flow patterns across Azure regions and internet for right-sizing |
| **Prerequisites** | Network Watcher enabled + Log Analytics workspace + flow logs enabled (NSG or VNet) |

---

## When to use it

| Problem | Tool |
|---|---|
| "Is my VM's traffic being dropped by an NSG?" | IP Flow Verify or NSG Diagnostics |
| "Why isn't my VM routing traffic to the right place?" | Next Hop |
| "Can VM A reach VM B right now?" | Connection Troubleshoot |
| "I need continuous monitoring of path latency between two endpoints" | Connection Monitor |
| "I need to capture packets off a VM for deep analysis" | Packet Capture |
| "My VPN connection is failing" | VPN Troubleshoot |
| "I want to see all traffic flowing through my VNets" | VNet Flow Logs + Traffic Analytics |
| "I want a dashboard of all my networking resources' health" | Azure Monitor Network Insights |
| "I need to audit all NSG rules on a specific NIC" | Effective Security Rules |
| "I want to understand who's communicating with what in my network" | Traffic Analytics |

---

## When NOT to use it

| Anti-pattern | Notes |
|---|---|
| PaaS monitoring (Azure SQL, App Service, etc.) | Network Watcher is explicitly IaaS-only; use Azure Monitor service-specific diagnostics for PaaS |
| Web analytics | Not the intended use case |
| Network Performance Monitor (NPM) | **NPM is retired (July 1, 2021)** — migrate tests to Connection Monitor. New tests can no longer be added in NPM. |
| Connection Monitor (Classic) | Also retired — migrate to Connection Monitor in Network Watcher |

---

## SKUs and tiers

Network Watcher and Azure Monitor Network Insights have **no separate SKUs**. Costs are driven by:

| Component | Pricing model |
|---|---|
| Network Watcher (monitoring, diagnostics) | No separate charge for most tools; packet capture and connection monitor have per-usage charges [VERIFY] |
| Flow logs (NSG or VNet) | Data volume charges for logs written to storage [VERIFY] |
| Traffic Analytics | Charged per GB of data processed [VERIFY] |
| Log Analytics workspace | Standard Azure Monitor log ingestion and retention pricing [VERIFY] |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Network Watcher enablement | Auto-enabled per region when VNet created | Manual enable required if previously opted out |
| Network Watcher instances | 1 per subscription per region | |
| Packet capture sessions (concurrent) | Limited per region [VERIFY] | See Azure subscription limits |
| Traffic Analytics processing frequency | Every 10 minutes or 60 minutes [VERIFY] | Configurable per workspace |

---

## Key operational notes

- **NSG Flow Logs are retiring** — migration to VNet Flow Logs is required. See [Network Watcher](../services/network-watcher.md) for current status.
- Network Watcher is **automatically enabled** per region when a VNet is created — no charge, no impact on resources.
- Connection Monitor requires the **Azure Monitor Agent** on Arc-enabled machines for hybrid monitoring.
- Traffic Analytics requires a **Log Analytics workspace** to be configured before flow logs can be analyzed.
- Azure Monitor Network Insights is available **without any configuration** for all networking resources — not just onboarded ones.

---

## Related services

- [Azure Network Watcher](../services/network-watcher.md) — detailed reference for all Network Watcher tools, limits, and source articles
- [Azure Virtual Network](../services/virtual-network.md) — NSGs, flow logs, and VNet topology are the primary objects being monitored
- [Azure Firewall](../services/azure-firewall.md) — onboarded to Network Insights; Firewall logs are separate from flow logs
- [ExpressRoute](../services/expressroute.md) — Connection Monitor supports ER monitoring; onboarded to Network Insights
- [Network security design](network-security-design.md) — Traffic Analytics is a key input to Zero Trust posture assessment

---

## Source articles

- [What is Azure Network Watcher?](../../raw/articles/network-watcher/network-watcher-overview.md)
- [Network Insights overview](../../raw/articles/network-watcher/network-insights-overview.md)
- [Traffic analytics overview](../../raw/articles/network-watcher/traffic-analytics.md)
- [Network monitoring solutions](../../raw/articles/networking/network-monitoring-overview.md)
