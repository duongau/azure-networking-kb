# Azure Network Watcher

> **Compiled:** 2025-07-14 | **Source articles:** 64 | **Status:** current

## What it is

Azure Network Watcher is a **regional, IaaS-focused** monitoring and diagnostic service for Azure virtual networking resources (VMs, VNets, NSGs, gateways, load balancers, etc.). It is **not** designed for PaaS monitoring or web analytics. Network Watcher is automatically enabled per-region when a VNet is created or updated in a subscription; the auto-enabled instance creates no charge and has no resource impact.

---

## Key capabilities

| Category | Tool | What it does |
|---|---|---|
| **Monitoring** | Topology | Interactive visual map of resources and relationships across subscriptions, regions, and resource groups |
| **Monitoring** | Connection Monitor | Continuous end-to-end connectivity and latency monitoring over TCP, ICMP, and HTTP for Azure and hybrid (Arc-enabled) endpoints |
| **Diagnostic** | IP Flow Verify | Checks if a packet is allowed or denied at a VM NIC; returns the matching NSG rule name. TCP/UDP only. |
| **Diagnostic** | NSG Diagnostics | Simulates traffic flows against NSG rules for VMs, VMSS NICs, and App Gateway v2; supports TCP/UDP/ICMP, IP prefixes, and service tags; can suggest new rules |
| **Diagnostic** | Next Hop | Returns the next hop type, IP, and route table ID for a given destination IP on a VM NIC; detects routing misconfigurations |
| **Diagnostic** | Effective Security Rules | Aggregated view of all NSG rules (NIC + subnet + AVNM admin rules) applied to a VM NIC; downloadable as CSV |
| **Diagnostic** | Connection Troubleshoot | Point-in-time connectivity test (TCP/ICMP) from VM/VMSS/App Gw v2/Bastion to VM, FQDN, URI, or IP; returns latency, hop-by-hop topology, and fault types. Agentless mode in preview. |
| **Diagnostic** | Packet Capture | Remote capture sessions on VMs or VMSS; saves to local disk or Azure Storage blob; 5-tuple filtering; continuous capture (preview) |
| **Diagnostic** | VPN Troubleshoot | Diagnoses VPN virtual network gateways and their connections; stores results in a storage account |
| **Traffic** | NSG Flow Logs | Layer-4 JSON logs of IP traffic per NSG rule, 1-min intervals. **[RETIRING - migrate to VNet Flow Logs]** |
| **Traffic** | VNet Flow Logs | Layer-4 JSON logs of IP traffic at virtual network scope; covers AVNM security admin rules and encryption status; supersedes NSG flow logs |
| **Traffic** | Traffic Analytics | Aggregates and enriches flow log data in Log Analytics; geo, security, and topology insights via built-in dashboards |

---

## When to use it

- **Troubleshooting connectivity** between Azure VMs, on-premises, or internet endpoints - use Connection Troubleshoot (one-time) or Connection Monitor (continuous)
- **Diagnosing NSG/routing misconfigurations** blocking traffic - IP Flow Verify, NSG Diagnostics, Next Hop, or Effective Security Rules
- **Capturing raw packet data** for deep inspection of intermittent network issues - Packet Capture
- **Debugging VPN tunnel failures** (IKE errors, PSK mismatch, policy mismatch) - VPN Troubleshoot
- **Logging all IP traffic** in a VNet for compliance, forensics, or SIEM export - VNet Flow Logs
- **Visualizing traffic patterns, hotspots, and open ports** across a subscription - Traffic Analytics
- **Monitoring SLA compliance** for hybrid connectivity at scale - Connection Monitor with Azure Monitor alerts
- **Auditing effective NSG rules** across a fleet of VMs - Effective Security Rules

---

## When NOT to use it

| Anti-pattern | Why | Alternative |
|---|---|---|
| Monitoring PaaS services (App Service, SQL, etc.) | Network Watcher is IaaS-only | Azure Monitor, Application Insights |
| Web analytics or application-level telemetry | Out of scope | Application Insights |
| ExpressRoute troubleshooting | VPN Troubleshoot does not support ER gateways | Network Performance Monitor / Azure Monitor for ExpressRoute |
| Policy-based VPN troubleshooting | Not supported by VPN Troubleshoot | Review gateway config manually |
| Running concurrent VPN troubleshoot operations | Only one operation per subscription at a time | Queue sequentially |
| NSG flow logs for new deployments | NSG flow logs are **retiring** | Use VNet flow logs instead |

---

## SKUs and tiers

Network Watcher has **no SKU tiers** — pricing is per-capability:

| Capability | Pricing model |
|---|---|
| Core diagnostics (IP Flow Verify, Next Hop, etc.) | Free for basic checks [VERIFY] |
| NSG Flow Logs | Per GB stored; storage charges separate [VERIFY] |
| VNet Flow Logs | Per GB stored; storage charges separate [VERIFY] |
| Traffic Analytics | Per GB processed + Log Analytics workspace cost [VERIFY] |
| Connection Monitor | Per monitoring check [VERIFY] |

See [Azure Network Watcher pricing](https://azure.microsoft.com/pricing/details/network-watcher/).

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Packet capture sessions (parallel) | 10,000 per region per subscription [VERIFY] | |
| Continuous packet capture duration (max) | 7 days [VERIFY] | Ring buffer |
| VPN troubleshoot concurrent operations | 1 per subscription [VERIFY] | |
| NSG flow log retention | Up to 1 year [VERIFY] | GPv2 storage only |
| Flow log collection interval | 1 minute | No agent required |
| Network Watcher instances | 1 per region per subscription | Auto-created in `NetworkWatcherRG` |

> For authoritative limits see [Azure subscription and service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits).

---

## Enablement and lifecycle

```
Subscription
+-- Region (e.g., East US)
    +-- NetworkWatcherRG
        +-- NetworkWatcher_eastus   <- auto-created on VNet create/update
```

- **Auto-enablement:** Triggered by any VNet create/update. No charge, no resource impact.
- **Opt-out:** Register `DisableNetworkWatcherAutocreation` feature on `Microsoft.Network` provider. Permanent - requires Azure Support to reverse.
- **Disable:** Delete the regional instance. Deletes all flow logs, connection monitors, and packet captures in that region - irreversible.

---

## Tool comparison

| Feature | IP Flow Verify | NSG Diagnostics | Connection Troubleshoot |
|---|---|---|---|
| Scope | VM NIC only | VM, VMSS NIC, App Gw v2 | VM, VMSS, App Gw v2, Bastion |
| Protocols | TCP, UDP | TCP, UDP, ICMP | TCP, ICMP |
| Tests service tags | No | Yes | No |
| Suggests new rules | No | Yes | No |
| Returns latency | No | No | Yes |
| Hop-by-hop topology | No | No | Yes |
| Agent required | No | No | No (agentless preview) |

---

## NSG Flow Logs vs. VNet Flow Logs

| Dimension | NSG Flow Logs | VNet Flow Logs |
|---|---|---|
| Scope | Per NSG (subnet or NIC level) | Per virtual network |
| AVNM security admin rules | No | Yes |
| Encryption state reporting | No | Yes |
| Status | **Retiring** | **Recommended** |
| Traffic Analytics compatible | Yes | Yes |

> **Migration:** Disable NSG flow logs before enabling VNet flow logs to avoid duplicate logging.

---

## RBAC requirements

Minimum role: **Network Contributor** — but several capabilities require additional permissions:

| Capability | Network Contributor gap |
|---|---|
| Flow logs (storage write) | Requires `Microsoft.Storage/*` separately |
| Packet capture (VM access) | Requires `Microsoft.Compute/*` separately |
| Traffic analytics | Requires `Microsoft.OperationalInsights/*` and `Microsoft.Insights/dataCollection*` |

---

## Related services

- [Virtual Network](virtual-network.md) - VNet flow logs target; topology visualization scope
- [VPN Gateway](vpn-gateway.md) - VPN Troubleshoot diagnoses VPN gateway health and connection faults
- [Azure Firewall](azure-firewall.md) - Not directly diagnosed by Network Watcher; use Azure Firewall diagnostics
- [Application Gateway](application-gateway.md) - NSG Diagnostics and Connection Troubleshoot support App Gw v2 as source
- [Azure Bastion](bastion.md) - Connection Troubleshoot supports Bastion as source
- [DDoS Protection](ddos-protection.md) - Flow logs complement DDoS telemetry; both feed monitoring pipelines
- [Private Link](private-link.md) - VNet flow logs capture private endpoint traffic

---

## Source articles

| Article | Date |
|---|---|
| `network-watcher-overview.md` | 2025-07-14 |
| `connection-monitor-overview.md` | 2025-07-14 |
| `nsg-flow-logs-overview.md` | 2025-07-14 |
| `vnet-flow-logs-overview.md` | 2025-07-14 |
| `traffic-analytics.md` | 2025-07-14 |
| `ip-flow-verify-overview.md` | 2025-07-14 |
| `nsg-diagnostics-overview.md` | 2025-07-14 |
| `next-hop-overview.md` | 2025-07-14 |
| `effective-security-rules-overview.md` | 2025-07-14 |
| `connection-troubleshoot-overview.md` | 2025-07-14 |
| `packet-capture-overview.md` | 2025-07-14 |
| `vpn-troubleshoot-overview.md` | 2025-07-14 |
| `network-insights-overview.md` | 2025-07-14 |
| `network-watcher-create.md` | 2025-07-14 |
| `required-rbac-permissions.md` | 2025-07-14 |
| *(+ 49 additional how-to, schema, migration, and tutorial articles)* | |
