# Hybrid DNS Resolution Pattern

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

Hybrid DNS resolution is the practice of enabling consistent name resolution across on-premises and Azure networks — specifically: allowing on-premises clients to resolve Azure Private DNS zones (e.g., for Private Endpoints), and allowing Azure workloads to resolve on-premises domain names. The canonical Azure implementation uses **Azure DNS Private Resolver** as the bridge, replacing legacy VM-based DNS servers with a fully managed, zone-redundant service deployed into hub VNet subnets.

This page covers the full resolution flow, inbound/outbound endpoint configuration, Private Endpoint DNS auto-registration, split-brain DNS, and common failure modes.

---

## Core architecture diagram

```
  ON-PREMISES                           AZURE HUB VNet (10.0.0.0/23)
  ─────────────                         ────────────────────────────────────────
  
  Client PC                             ┌─────────────────────────────────────┐
    │  resolves                         │  DNS Private Resolver               │
    │  storage.contoso.internal         │                                     │
    │  (Azure PaaS private endpoint)    │  ┌──────────────────────────────┐   │
    │                                   │  │ Inbound Endpoint             │   │
    ▼                                   │  │ IP: 10.0.1.4 (/28 subnet)   │   │
  On-premises DNS Server                │  │ Dedicated subnet, delegated  │   │
    │  Conditional forwarder:           │  │ to dnsResolvers              │   │
    │  contoso.internal → 10.0.1.4      │  └──────────────────────────────┘   │
    │  privatelink.*.core.windows.net   │         ↑ receives queries from     │
    │        → 10.0.1.4                 │           on-premises DNS server     │
    │                                   │                                     │
    │──────── ExpressRoute / VPN ──────►│         ↓ resolves against          │
                                        │  Azure Private DNS Zones             │
                                        │  (linked to hub VNet)               │
                                        │   privatelink.blob.core.windows.net  │
                                        │   privatelink.database.windows.net   │
                                        │   contoso.internal                  │
                                        │                                     │
                                        │  ┌──────────────────────────────┐   │
                                        │  │ Outbound Endpoint            │   │
                                        │  │ Separate dedicated subnet    │   │
                                        │  │ DNS Forwarding Ruleset:      │   │
                                        │  │  corp.contoso.com → 10.x.x.x│   │
                                        │  │  (on-prem DNS server)        │   │
                                        │  └──────────────────────────────┘   │
                                        │         ↓ Azure VM queries           │
                                        │  Azure VM in spoke                  │
                                        │    resolves corp.contoso.com        │
                                        │    → outbound endpoint →            │
                                        │    on-prem DNS (10.x.x.x)          │
                                        └─────────────────────────────────────┘
                                               │
                              ┌────────────────┼──────────────────┐
                              │                │                  │
                     ┌────────┴──────┐ ┌───────┴──────┐ ┌────────┴──────┐
                     │  Spoke A      │ │  Spoke B     │ │  Spoke C      │
                     │  DNS → Resolver│ │  DNS → Res.  │ │  DNS → Res.  │
                     └───────────────┘ └──────────────┘ └───────────────┘
```

---

## Component reference

| Component | Required | Subnet | Notes |
|---|---|---|---|
| **DNS Private Resolver** | ✅ | Hub VNet | One resolver instance; auto HA across AZs in supported regions |
| **Inbound endpoint** | ✅ (for on-prem → Azure) | Dedicated /28–/24; delegated to `Microsoft.Network/dnsResolvers` | On-premises points conditional forwarder here |
| **Outbound endpoint** | ✅ (for Azure → on-prem) | Dedicated /28–/24; delegated to `Microsoft.Network/dnsResolvers` | Different subnet from inbound |
| **DNS Forwarding Ruleset** | ✅ (for Azure → on-prem) | Attached to outbound endpoint | Up to 1,000 forwarding rules; longest-suffix-match |
| **Azure Private DNS Zones** | ✅ | Global resource; linked to hub VNet | One zone per service type (e.g., `privatelink.blob.core.windows.net`) |
| **VNet DNS server setting** | ✅ | Per-spoke VNet config | Set to inbound endpoint IP (centralized) or use ruleset links (distributed) |

---

## Step 1 — Deploy the DNS Private Resolver in hub

**Subnet requirements:**
- Create two dedicated subnets in the hub VNet.
- Delegate each to `Microsoft.Network/dnsResolvers`.
- Minimum /28, maximum /24.
- IPv4 only — IPv6 subnets not supported.
- Do NOT place any other resources (VMs, NICs, etc.) in these subnets.

```
Subnet name:       dns-inbound-subnet   → CIDR: 10.0.1.0/28
Subnet name:       dns-outbound-subnet  → CIDR: 10.0.1.16/28
Both delegated to: Microsoft.Network/dnsResolvers
```

**Resolver deployment:**
1. Create Azure DNS Private Resolver → place in hub VNet.
2. Add inbound endpoint → select `dns-inbound-subnet` → note the assigned private IP (e.g., `10.0.1.4`).
3. Add outbound endpoint → select `dns-outbound-subnet`.

---

## Step 2 — Configure conditional forwarding: on-premises → Azure

On the **on-premises DNS server** (Windows DNS, BIND, Unbound, etc.), add conditional forwarders for every Azure private namespace:

| Domain | Forwards to | Purpose |
|---|---|---|
| `contoso.internal` | `10.0.1.4` (inbound endpoint IP) | Custom private Azure zone |
| `privatelink.blob.core.windows.net` | `10.0.1.4` | Storage blob private endpoints |
| `privatelink.database.windows.net` | `10.0.1.4` | Azure SQL private endpoints |
| `privatelink.vaultcore.azure.net` | `10.0.1.4` | Key Vault private endpoints |
| `privatelink.servicebus.windows.net` | `10.0.1.4` | Event Hubs / Service Bus |
| `privatelink.oms.opinsights.azure.com` | `10.0.1.4` | Azure Monitor (Log Analytics) |
| _(add per service — see full list in private-endpoint-dns.md)_ | | |

> ⚠️ **Network connectivity prerequisite:** The on-premises DNS server must be able to reach the inbound endpoint IP (`10.0.1.4`) over ExpressRoute private peering or Site-to-Site VPN. Pure internet connectivity is not sufficient — the inbound endpoint is a private IP inside your VNet.

**How the query resolves:**

```
On-premises client → On-prem DNS → conditional forwarder → Inbound endpoint (10.0.1.4)
                                                                     │
                                              Azure Private DNS Resolver receives query
                                                                     │
                                              Checks Azure Private DNS Zone:
                                              privatelink.blob.core.windows.net
                                                                     │
                                              Returns: A record = 10.1.2.5 (private endpoint IP)
                                                                     │
                                              Response flows back over ER/VPN to on-prem client
```

---

## Step 3 — Configure conditional forwarding: Azure → on-premises

Create a **DNS Forwarding Ruleset** on the outbound endpoint:

1. Create a ruleset → associate with the outbound endpoint.
2. Add forwarding rules:

| Rule name | Domain name | Target DNS IP:Port | Purpose |
|---|---|---|---|
| OnPremCorp | `corp.contoso.com.` | `192.168.1.10:53` | On-prem AD DNS server |
| OnPremInternal | `contoso.internal.` | `192.168.1.10:53` | Internal zone (if on-prem) |
| _(wildcard fallback)_ | `.` (root) | `168.63.129.16:53` | All others → Azure DNS |

3. Link the ruleset to spoke VNets where Azure VMs need to resolve on-premises names:
   - Ruleset → VNet links → add each spoke VNet.
   - One ruleset can link to up to 500 VNets in the same region [VERIFY].

> ⚠️ **Do NOT link the ruleset (containing a rule pointing to the inbound endpoint) back to the hub VNet where that inbound endpoint resides.** This creates a DNS resolution loop.

---

## Step 4 — Spoke VNet DNS configuration

Two hub-spoke DNS distribution patterns:

### Pattern A — Centralized (recommended for simplicity)

Set each spoke VNet's DNS server to the **inbound endpoint IP**:
```
Spoke VNet → Settings → DNS servers → Custom: 10.0.1.4
```
All DNS queries from spoke VMs flow to the resolver:
- Azure private zones (linked to hub VNet): resolved directly.
- On-premises names: resolved via outbound endpoint + forwarding ruleset.
- Public internet names: forwarded to upstream (168.63.129.16).

**Trade-off:** All DNS traffic from spokes crosses the VNet peering to hub — adds a hop and peering data cost.

### Pattern B — Distributed (ruleset links; recommended for scale)

Keep spoke VNet DNS servers as Azure Default (`168.63.129.16`). Link the forwarding ruleset directly to spoke VNets:

```
Ruleset → VNet links → Spoke A, Spoke B, Spoke C
```

- Azure-provided DNS (`168.63.129.16`) resolves public names and Azure Private DNS zones **linked to the spoke VNet** natively.
- The ruleset intercepts queries for domains in its forwarding rules and redirects to the outbound endpoint.
- Private DNS zones linked only to the hub (not spokes) are **not** resolved from spokes in this model unless the spoke is also linked to those zones.

---

## Step 5 — Private Endpoint DNS auto-registration

When a Private Endpoint is created for an Azure PaaS service, DNS must resolve the public FQDN to the private IP. Azure provides automatic guidance:

**How the CNAME chain works:**

```
Client query: storageaccount.blob.core.windows.net
                    │
           Azure Public DNS returns CNAME:
           → storageaccount.privatelink.blob.core.windows.net
                    │
           Azure Private DNS Zone (privatelink.blob.core.windows.net)
           linked to hub VNet returns A record:
           → 10.1.2.5  (private endpoint IP in spoke subnet)
```

**Setup:**
1. Create Private Endpoint for the storage account in a spoke subnet.
2. Create (or use existing) Azure Private DNS Zone: `privatelink.blob.core.windows.net`.
3. Link the private DNS zone to the **hub VNet** (where the resolver lives).
4. When the Private Endpoint is created with the DNS integration option enabled, Azure automatically creates an A record in the zone pointing to the private endpoint's private IP.
5. With hub VNet DNS configuration from Step 4, all spokes and on-premises clients can resolve the private endpoint.

**Selected Private DNS Zone names:**

| Service | Private DNS Zone name |
|---|---|
| Azure Storage (blob) | `privatelink.blob.core.windows.net` |
| Azure Storage (file) | `privatelink.file.core.windows.net` |
| Azure SQL Database | `privatelink.database.windows.net` |
| Azure Key Vault | `privatelink.vaultcore.azure.net` |
| Event Hubs / Service Bus | `privatelink.servicebus.windows.net` |
| Azure Monitor (Log Analytics) | `privatelink.oms.opinsights.azure.com` |
| Azure Monitor (ODS) | `privatelink.ods.opinsights.azure.com` |
| Cosmos DB (SQL) | `privatelink.documents.azure.com` |

> Full list: see `raw/articles/private-link/private-endpoint-dns.md`

---

## Step 6 — Split-brain DNS

Split-brain DNS allows the same domain name to resolve to different addresses for internal vs. external clients.

**Use case:** `api.contoso.com` resolves to a private IP for Azure VMs and on-premises clients, but to a public IP for internet clients.

**Configuration:**

| Zone type | Zone name | Contains | Used by |
|---|---|---|---|
| Azure Public DNS zone | `contoso.com` | A record: `api.contoso.com → 20.x.x.x` (public IP) | Internet clients |
| Azure Private DNS zone | `contoso.com` | A record: `api.contoso.com → 10.1.0.5` (private IP) | VNet-internal + on-premises clients |

**How it works:**
- VNets linked to the private zone always use the private zone for `contoso.com` lookups — the private zone takes precedence over public DNS for linked VNets.
- Internet clients have no VNet link → public DNS resolves normally.
- No changes needed on clients — DNS returns different IPs based on resolver context.

---

## Common failure modes

| Symptom | Root cause | Fix |
|---|---|---|
| On-premises client can't resolve Azure private endpoint | No conditional forwarder for `privatelink.*` on on-premises DNS | Add forwarder for all required `privatelink.*` zones pointing to inbound endpoint IP |
| Azure VM can't resolve on-premises name | Forwarding ruleset not linked to spoke VNet, or outbound endpoint missing the rule | Add forwarding rule; link ruleset to spoke VNet |
| DNS loop / NXDOMAIN loop | Ruleset containing inbound endpoint IP linked to hub VNet | Never link a ruleset with an inbound endpoint forwarding rule to the inbound endpoint's own VNet |
| Private endpoint resolves to public IP | Private DNS zone not linked to VNet or A record not created | Link zone to hub VNet; check PE DNS integration was enabled at creation |
| VMs in spoke can't resolve private zones | Spoke VNet DNS set to Azure default; private zones only linked to hub | Either also link zones to spokes, or switch to centralized pattern (DNS → inbound endpoint IP) |
| Resolver deployment fails | Subnet not dedicated or not delegated to `Microsoft.Network/dnsResolvers` | Use a subnet with no other resources; add delegation |
| ExpressRoute FastPath + DNS resolver fails | FastPath bypasses gateway; DNS Private Resolver in spoke VNets not supported with FastPath | Move DNS Private Resolver to hub VNet (not spoke VNets) |

---

## Monitoring

| Data type | Source | Destination |
|---|---|---|
| DNS query logs | DNS Security Policy (attach to VNet) | Log Analytics, Storage, Event Hubs |
| Resolver availability | Azure Monitor metrics on Private Resolver resource | Metrics explorer |
| Threat intelligence blocks | DNS Security Policy threat intel block events | Log Analytics alerts |
| Zone record counts | Azure Resource Graph Explorer | — |

**Recommended alerts:**
- Alert if DNS Private Resolver inbound endpoint stops responding (Connection Monitor probe from on-premises or hub VM to `10.0.1.4:53`).
- Alert on unexpected NXDOMAIN volume spikes (may indicate misconfigured forwarders or broken zone links).

---

## Service limits reference

| Limit | Value |
|---|---|
| Inbound/outbound subnet minimum size | /28 |
| DNS forwarding rules per ruleset | 1,000 [VERIFY] |
| VNets linked per ruleset | 500 (same region) [VERIFY] |
| Outbound endpoints per ruleset | 2 (same resolver instance only) |
| IPv6 subnet support for resolver | ❌ Not supported |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure DNS](../services/dns.md) | Private Resolver architecture, inbound/outbound endpoints, forwarding rulesets, hybrid DNS patterns, split-brain, zone sharding |
| [Hybrid Connectivity](../concepts/hybrid-connectivity.md) | ER/VPN connectivity requirement for on-premises-to-Azure DNS path; BGP route propagation |
| [Private Access to PaaS](../concepts/private-access-to-paas.md) | Private Endpoint DNS requirement, CNAME chain mechanism, selected privatelink zone names |