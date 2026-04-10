# Azure Peering Service

> **Compiled:** 2026-04-10 | **Source articles:** 9 | **Status:** ✅ current

## What it is

**Azure Peering Service** is a public-internet networking service that optimises connectivity from customer networks to Microsoft cloud services (Microsoft 365, Dynamics 365, Azure SaaS, and any Microsoft service reachable over the public internet). It is a **collaboration platform** between Microsoft and vetted **ISPs, IXPs, and SDCI providers** that enforces **cold-potato routing** — keeping traffic on the high-capacity Microsoft global network until it is as close to the destination as possible.

> ⚠️ Peering Service is **not** a private connectivity product. It does not replace ExpressRoute or VPN Gateway; it optimises public-internet paths only.

Key behaviour:
- Traffic enters and exits the **nearest Microsoft Edge PoP** for registered prefixes — both inbound and outbound.
- Customers choose a **preferred partner** and register their **IP prefixes** to activate optimised routing.
- Telemetry (latency metrics, BGP route events) is **opt-in** via Azure portal prefix registration — no telemetry without registration.
- Microsoft will **not** re-advertise customer prefixes to the internet.
- No Microsoft registration is required to use the service — contact a partner to get started; register in the portal only to enable telemetry.

---

## Key capabilities

| Capability | Detail |
|---|---|
| **Cold-potato routing** | Traffic stays on the Microsoft global network backbone until the last possible hop to the customer; contrasts with hot-potato routing where traffic exits Microsoft network early |
| **Local redundancy** | Each primary peering location requires ≥ 2 Peering Service sessions on 2 different routers. Failover within the same PoP is automatic |
| **Geo-redundancy** | Microsoft interconnects with partners at multiple metro locations; SDN-based routing policies reroute via alternate sites if an Edge node degrades |
| **Partner ecosystem** | 30+ partners across Africa, Asia, Europe, Japan, LATAM, North America, and Oceania (ISPs, IXPs, SDCI providers) |
| **Prefix-level telemetry** | Per-prefix latency reporting (6 h / 12 h / 1 d / 7 d / 30 d windows) and BGP route event streaming |
| **BGP route monitoring** | Captures prefix announcement, withdrawal, origin-ASN change, and backup-route events with severity tagging |
| **Multi-management plane** | Connections manageable via Azure portal, Azure CLI (`az peering`), or Azure PowerShell (`Az.Peering` module) |
| **Backup peering location** | Optional secondary PoP; if set to *None*, internet is the default failover path |

---

## Architecture patterns

Peering Service sits between the customer's ISP/IXP and the Microsoft Edge PoP layer on the public internet. It does **not** create a private circuit — it optimises how public traffic enters and traverses the Microsoft global network.

```
Customer network
      │
      ▼
 ISP / IXP / SDCI partner ◄─── Peering Service partner (validates prefix, BGP community)
      │
      ▼ (cold-potato: traffic enters Microsoft backbone at nearest PoP)
 Microsoft Edge PoP (geo-redundant, local-redundant)
      │
      ▼
 Microsoft Global Network
      │
      ▼
 Microsoft 365 / Dynamics 365 / Azure SaaS
```

**Connection object** — the logical registration unit in Azure. One connection per geographic grouping. Attributes:
- Logical name
- Connectivity partner
- Primary service location (PoP closest to customer)
- Backup service location (next-closest PoP; optional)
- IP prefixes (owned by customer or allocated by provider)

---

## Configuration essentials

### Resource provider registration (required before first use)

```azurecli
az feature register --namespace Microsoft.Peering --name AllowPeeringService
az provider register --name Microsoft.Peering
```

### Prefix technical requirements

| Requirement | Detail |
|---|---|
| No private range | Prefix must be a publicly routable IPv4 address |
| Origin ASN registry | Origin ASN must be registered in a major routing registry (ARIN, RIPE, APNIC, etc.) |
| Prefix key match | The **prefix key** entered in Azure must match the key issued by the provider |
| Full advertisement | Prefix must be announced from **all** primary and backup peering sessions |
| BGP community | Routes **must** carry community string **`8075:8007`** |
| AS path length | AS path must be **≤ 3** hops |
| No private ASNs | AS path must not contain any private ASN |
| IPv4 only | Only IPv4 prefixes are currently supported [VERIFY] |

### Key portal operations

| Operation | How |
|---|---|
| Create connection | Portal → Peering Services → **+ Create** |
| Add prefix | Connection → Prefixes → **Add prefix** (name, CIDR, prefix key) |
| Remove prefix | Connection → Prefixes → **...** → **Delete** |
| Modify prefix | ❌ Not supported — delete and re-create the prefix resource |
| Change primary/backup PoP | Email `peeringservice@microsoft.com` with resource ID and desired locations |

---

## Monitoring and troubleshooting

### Available telemetry metrics

| Metric | Notes |
|---|---|
| Ingress/egress traffic rate | Per connection |
| BGP session availability | Per connection |
| Packet drops | Per connection |
| Latency | Per prefix; 6 h / 12 h / 1 d / 7 d / 30 d windows |
| Prefix events | BGP route-level events per prefix |

### Prefix event types

| Event type | Severity | Meaning |
|---|---|---|
| `PrefixAnnouncementEvent` | Information | Prefix announcement received |
| `PrefixWithdrawalEvent` | Warning | Prefix withdrawal received |
| `PrefixOriginAsChangeEvent` | **Critical** | Active route received with unexpected origin ASN |
| `PrefixBackupRouteOriginAsChangeEvent` | Error | Backup route received with unexpected origin ASN |

### Validation failure quick-triage

| Error | Cause | Resolution |
|---|---|---|
| Fewer than two sessions at primary location | Local redundancy requirement not met | Wait for provisioning; contact provider |
| Missing community `8075:8007` | BGP community tag absent | Provider must add community tag to advertisements |
| AS path > 3 | Path too long | Provider must shorten AS path |
| Private ASN in path | Private ASN present | Provider must remove private ASNs |
| Provider not found | Subscription/partner mismatch | Contact `peeringservice@microsoft.com` |

**Escalation contact:** `peeringservice@microsoft.com`

---

## Common gotchas / known limits

- **Prefix modification is not possible** — delete and re-create to change a CIDR or prefix key.
- **Changing primary/backup PoP requires manual Microsoft intervention** — not self-service; email `peeringservice@microsoft.com`.
- **Backup location = None means internet failover** — no second Peering Service path.
- **IPv4 only** — IPv6 prefixes not currently supported. [VERIFY]
- **Latency telemetry is approximated at /24** for more-specific prefixes (compliance limitation).
- **BGP community `8075:8007` is mandatory** — omitting it causes validation failure.
- **AS path ≤ 3 and no private ASNs** — hard requirements; prepending beyond 3 will fail validation.
- **Telemetry is opt-in** — no data collected until prefixes are registered in the portal.

---

## Related services

- **[Internet Peering](internet-peering.md)** — The underlying Microsoft peering infrastructure that Peering Service partners use. Partners must establish Internet Peering before offering Peering Service.
- **[ExpressRoute](expressroute.md)** — Private dedicated circuit connectivity to Azure. Use when private, SLA-backed connectivity is required (not public internet).
- **[VPN Gateway](vpn-gateway.md)** — Encrypted tunnel over the public internet into Azure VNets.
- **[Traffic Manager](traffic-manager.md)** — DNS-based global load balancing for internet-facing endpoints.
