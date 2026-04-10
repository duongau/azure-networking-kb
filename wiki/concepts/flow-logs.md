# Flow Logs in Azure

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** current

## Overview

Azure flow logs capture Layer-4 IP traffic metadata flowing through your network, enabling security analysis, compliance auditing, and traffic pattern visualization. Azure offers two flow log types: **NSG Flow Logs** (retiring) and **VNet Flow Logs** (recommended).

---

## NSG Flow Logs vs VNet Flow Logs

| Dimension | NSG Flow Logs | VNet Flow Logs |
|---|---|---|
| **Scope** | Per NSG (subnet or NIC level) | Per virtual network |
| **AVNM security admin rules** | ❌ Not captured | ✅ Captured |
| **Encryption status reporting** | ❌ | ✅ |
| **Traffic Analytics compatible** | ✅ | ✅ |
| **Status** | ⚠️ **RETIRING** — migrate to VNet Flow Logs | ✅ **Recommended** |

> **Migration note:** Disable NSG flow logs before enabling VNet flow logs to avoid duplicate logging.

---

## Schema fields

Flow logs are JSON-formatted with 1-minute intervals.

### Key fields

| Field | Description |
|---|---|
| `srcAddr` | Source IP address |
| `dstAddr` | Destination IP address |
| `srcPort` | Source port |
| `dstPort` | Destination port |
| `protocol` | Protocol number (6=TCP, 17=UDP, 1=ICMP) |
| `action` | Allow (A) or Deny (D) |
| `flowState` | Begin (B), Continuing (C), End (E) |
| `bytesSourceToDestination` | Bytes sent from source to destination |
| `bytesDestinationToSource` | Bytes sent from destination to source |
| `packetsSourceToDestination` | Packets sent from source to destination |
| `packetsDestinationToSource` | Packets sent from destination to source |

### VNet Flow Log additional fields

| Field | Description |
|---|---|
| `encryptionStatus` | Indicates if traffic was encrypted via VNet encryption |
| `securityAdminRuleMatch` | AVNM security admin rule that matched the traffic |

---

## Storage destinations

| Destination | Use case | Notes |
|---|---|---|
| **Azure Storage Account** | Long-term retention, compliance archival | GPv2 required; up to 1 year retention [VERIFY] |
| **Log Analytics workspace** | Query, alerting, Traffic Analytics | Required for Traffic Analytics |
| **Event Hub** | SIEM export (Splunk, Sentinel, third-party) | Real-time streaming |

### Retention

- Storage account: configurable up to 1 year [VERIFY]
- Log Analytics: governed by workspace retention settings
- Flow log collection interval: 1 minute (no agent required)

---

## Traffic Analytics

Traffic Analytics processes raw flow logs to provide actionable network intelligence.

### Data flow

```
Flow logs → Aggregated by 5-tuple common flows → Enriched with geography, 
security, topology → Stored in Log Analytics workspace
```

### Key capabilities

| Capability | Description |
|---|---|
| **Top talkers** | Identifies hosts with highest traffic volume |
| **Geo-map** | Traffic distribution by source/destination geography |
| **Anomaly detection** | Identifies unusual traffic patterns and potential threats |
| **Security insights** | Open ports, rogue network connections, malicious indicators |
| **Capacity planning** | Traffic flow patterns across Azure regions and internet |

### Query examples

**Top 10 source IPs by traffic volume:**
```kusto
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(24h)
| summarize TotalBytes = sum(BytesSentSourceToDestination_d + BytesSentDestinationToSource_d) by SrcIP_s
| top 10 by TotalBytes desc
```

**Blocked traffic by destination port:**
```kusto
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(24h)
| where FlowStatus_s == "D"
| summarize Count = count() by DestPort_d
| top 10 by Count desc
```

**Traffic by geography:**
```kusto
AzureNetworkAnalytics_CL
| where TimeGenerated > ago(7d)
| summarize TotalBytes = sum(BytesSentSourceToDestination_d) by Country_s
| order by TotalBytes desc
```

---

## Cost considerations

| Component | Pricing model |
|---|---|
| Flow logs (NSG or VNet) | Per GB stored; storage account charges separate [VERIFY] |
| Traffic Analytics | Per GB processed + Log Analytics workspace cost [VERIFY] |
| Log Analytics workspace | Standard Azure Monitor log ingestion and retention pricing |

### Cost optimization

- Enable flow logs only on critical subnets/VNets
- Use Traffic Analytics processing frequency of 60 minutes instead of 10 minutes for lower cost
- Configure appropriate retention periods
- Use storage lifecycle policies for archival

---

## Enabling via Azure Policy

Azure Policy can enforce flow log configuration at scale:

| Policy | Effect |
|---|---|
| `Network Watcher flow logs should be enabled` | Audit / DeployIfNotExists |
| `Deploy VNet flow logs with Traffic Analytics` | DeployIfNotExists |

### Example policy assignment

```json
{
  "properties": {
    "displayName": "Enable VNet Flow Logs",
    "policyDefinitionId": "/providers/Microsoft.Authorization/policyDefinitions/...",
    "parameters": {
      "storageAccountId": { "value": "/subscriptions/.../storageAccounts/flowlogstorage" },
      "workspaceId": { "value": "/subscriptions/.../workspaces/flowlogworkspace" }
    }
  }
}
