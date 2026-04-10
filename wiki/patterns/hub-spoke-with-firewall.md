# Hub-Spoke with Azure Firewall

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

This pattern places Azure Firewall as the sole transit and inspection point in a hub VNet. Every spoke-to-spoke flow, every internet egress byte, and every on-premises-bound packet is routed through the Firewall via User-Defined Routes — giving a single policy enforcement point with a full audit log. It is the recommended starting topology for enterprises running more than one workload VNet in Azure.

---

## Architecture diagram

```
                          Internet
                             │
                    ┌────────┴────────┐
                    │  Azure Firewall │  ← AzureFirewallSubnet /26
                    │ (Standard/Prem) │    private IP: e.g. 10.0.0.4
                    └──┬──────────┬───┘
                       │          │
          ┌────────────┘          └─────────────┐
          │ Hub VNet 10.0.0.0/23                │
          │                                     │
          │  GatewaySubnet /27  ──── ER/VPN GW  │
          │  AzureBastionSubnet /26 ─ Bastion   │
          │  DNSInboundSubnet   /28 ─ Resolver  │
          │  DNSOutboundSubnet  /28 ─ Resolver  │
          │                                     │
          └──────┬───────────────────┬──────────┘
      VNet peer  │  (AllowGWTransit) │  VNet peer
   (UseRemoteGW) │                   │ (UseRemoteGW)
                 │                   │
   ┌─────────────┴──────┐  ┌─────────┴──────────┐
   │  Spoke A 10.1.0.0/16│  │  Spoke B 10.2.0.0/16│
   │  ┌──────────────┐   │  │  ┌──────────────┐   │
   │  │ Ingress /24  │   │  │  │ Ingress /24  │   │
   │  │ Backend /24  │   │  │  │ Backend /24  │   │
   │  │ Data    /28  │   │  │  │ Data    /28  │   │
   │  └──────────────┘   │  │  └──────────────┘   │
   │  RT: 0/0 → FW       │  │  RT: 0/0 → FW       │
   │  RT: 10.2/16 → FW   │  │  RT: 10.1/16 → FW   │
   │  BGP propagation OFF │  │  BGP propagation OFF │
   └────────────────────┘  └─────────────────────┘
                                      │
                               On-premises network
                             (via ER/VPN in GatewaySubnet)
```

---

## Step 1 — Address plan (do this before any deployment)

| Subnet | VNet | CIDR | Exact name required? |
|---|---|---|---|
| Firewall | Hub | `10.0.0.0/26` | ✅ `AzureFirewallSubnet` |
| Firewall Management (Basic SKU only) | Hub | `10.0.0.64/26` | ✅ `AzureFirewallManagementSubnet` |
| Gateway | Hub | `10.0.0.128/27` | ✅ `GatewaySubnet` |
| Bastion | Hub | `10.0.0.160/26` | ✅ `AzureBastionSubnet` |
| DNS Resolver inbound | Hub | `10.0.1.0/28` | ❌ (any name; must be dedicated, delegated) |
| DNS Resolver outbound | Hub | `10.0.1.16/28` | ❌ (any name; must be dedicated, delegated) |
| Spoke A — ingress | Spoke A | `10.1.0.0/24` | ❌ |
| Spoke A — backend | Spoke A | `10.1.1.0/24` | ❌ |
| Spoke A — data | Spoke A | `10.1.2.0/28` | ❌ |
| Spoke B (mirror pattern) | Spoke B | `10.2.x.x/xx` | ❌ |

> ⚠️ Reserve all hub subnets at VNet creation time even if you don't deploy the service yet. Hub VNet address space must not overlap with spokes, on-premises, or future VNets — there is no live edit path.

---

## Step 2 — Deploy Azure Firewall

1. **SKU choice:**
   - Standard — enterprise egress control, threat intel alert+deny, DNS proxy, FQDN rules [VERIFY SKU pricing]
   - Premium — adds TLS inspection (outbound + E-W), IDPS (67,000+ signatures), URL filtering; required for PCI DSS [VERIFY]
   - Basic — SMB / dev-test only; no autoscale, no DNS proxy, alert-only threat intel

2. **Deploy with Availability Zones** (Standard/Premium): select all AZs in the region — no extra cost.

3. **Enable DNS proxy** (Standard/Premium — required for FQDN rules in network rules):
   - Firewall → DNS Settings → DNS Proxy: **Enabled**
   - DNS Servers: set to custom on-premises DNS or leave as Azure Default (`168.63.129.16`)
   - Note the Firewall's **private IP** (e.g., `10.0.0.4`) — this is the DNS proxy listener and UDR next-hop.

4. **Create a Firewall Policy** (recommended over classic rules):
   - Attach to Firewall at deployment or post-deployment.
   - Parent policies for shared org-wide rules; child policies per environment.
   - Policy hierarchy: parent rule collection groups always take precedence over child.

---

## Step 3 — UDR configuration

Create one route table per spoke subnet. Apply the same table to every subnet in a given spoke (or use one table per spoke VNet and associate to all subnets).

### Spoke A route table

| Destination | Next hop type | Next hop address | Purpose |
|---|---|---|---|
| `0.0.0.0/0` | Virtual appliance | `10.0.0.4` (FW private IP) | Internet egress via Firewall |
| `10.2.0.0/16` | Virtual appliance | `10.0.0.4` | Spoke-A → Spoke-B via Firewall |
| `10.3.0.0/16` | Virtual appliance | `10.0.0.4` | Spoke-A → Spoke-C via Firewall |
| _(repeat for each spoke)_ | | | |

### Spoke B route table (mirror)

| Destination | Next hop type | Next hop address | Purpose |
|---|---|---|---|
| `0.0.0.0/0` | Virtual appliance | `10.0.0.4` | Internet egress |
| `10.1.0.0/16` | Virtual appliance | `10.0.0.4` | Spoke-B → Spoke-A via Firewall |

> **Disable BGP route propagation** on every spoke route table. Without this, on-premises prefixes learned by the hub VPN/ER gateway inject directly into spoke effective routes and bypass the Firewall for hybrid traffic.

### GatewaySubnet route table (optional — forces on-premises-to-spoke via Firewall)

| Destination | Next hop type | Next hop address |
|---|---|---|
| `10.1.0.0/16` | Virtual appliance | `10.0.0.4` |
| `10.2.0.0/16` | Virtual appliance | `10.0.0.4` |

> Adding UDRs to GatewaySubnet ensures traffic arriving from on-premises is also routed through the Firewall before reaching spoke VMs. Do NOT add `0.0.0.0/0` to GatewaySubnet — this breaks gateway connectivity.

---

## Step 4 — Spoke-to-spoke traffic rules

UDRs steer packets to the Firewall; Firewall rules decide whether to allow or deny. Without rules, the Firewall drops the traffic (implicit deny-all).

**Rule processing order (per policy):** Threat Intelligence → DNAT → Network → Application → Infrastructure → Implicit deny

**Minimum rules for spoke-to-spoke:**

| Rule type | Source | Destination | Port/Protocol | Action |
|---|---|---|---|---|
| Network rule | `10.1.0.0/16` (Spoke A) | `10.2.0.0/16` (Spoke B) | TCP/443 (or specific app ports) | Allow |
| Network rule | `10.2.0.0/16` (Spoke B) | `10.1.0.0/16` (Spoke A) | TCP/443 | Allow |

For HTTP/HTTPS flows: use **Application rules** (FQDN-based) instead of network rules — these give FQDN-level allow listing and benefit from SNI-based inspection.

---

## Step 5 — Internet egress (north-south outbound)

The `0.0.0.0/0 → Firewall` UDR on every spoke subnet forces all internet-bound traffic through the Firewall.

**Key Firewall behaviors for outbound:**
- All outbound traffic is **SNATed** to the Firewall's public IP(s).
- By default, traffic to RFC 1918 destinations (`10.x`, `172.16–31.x`, `192.168.x`) and RFC 6598 (`100.64/10`) is **not SNATed** (treated as private).
- SNAT port limit: **2,496 ports per public IP per Firewall instance** [VERIFY]. If you have many VMs making high-volume outbound connections, attach a NAT Gateway to `AzureFirewallSubnet` — this expands available SNAT ports to 64,512 per public IP [VERIFY].

**Application rules for internet FQDN filtering:**

```
Rule collection: AllowInternetEgress  (priority 200)
  Rule: AllowUpdates
    Source: 10.1.0.0/16, 10.2.0.0/16
    Protocol: Https:443, Http:80
    Target FQDNs: *.microsoft.com, *.windowsupdate.com, *.ubuntu.com
    Action: Allow

Rule collection: BlockAll (priority 300)
    (implicit deny handles this — no explicit block rule needed)
```

> Enable **Threat Intelligence** in Alert+Deny mode (Standard/Premium). It processes before all other rules and blocks known malicious IPs/FQDNs/URLs using Microsoft's cyber security feed.

---

## Step 6 — DNS forwarding to Firewall DNS proxy

Required for FQDN-based **network rules** (Standard/Premium). Application rules work without DNS proxy, but network rules resolve FQDNs at evaluation time — the Firewall must be the DNS resolver.

**Configure VNet DNS settings:**
- Each spoke VNet → DNS servers → Custom: `10.0.0.4` (Firewall private IP)
- Hub VNet → DNS servers → Custom: `10.0.0.4`

**How the DNS proxy chain works:**

```
Spoke VM → DNS query → Firewall DNS proxy (10.0.0.4)
                              │
               ┌──────────────┴──────────────────┐
               │  Checks cache (TTL: +1hr / -30m) │
               │  On miss: forwards to upstream    │
               │  upstream = 168.63.129.16         │
               │           or custom DNS servers   │
               └──────────────────────────────────┘
                              │
                    Response returned to VM
                    Firewall resolves FQDN in
                    network rule at query time
```

**Integration with Private DNS zones:**
- Link all Private DNS zones to the hub VNet (where the Firewall/Resolver lives).
- Spoke VMs query the Firewall DNS proxy → proxy forwards to `168.63.129.16` → Azure DNS resolves the private zone → private IP returned.
- This enables spoke VMs to resolve Private Endpoints without linking every private zone to every spoke VNet.

> ⚠️ Do NOT create Private DNS zones that shadow Microsoft-owned domains (e.g., `*.blob.core.windows.net`, `*.azure.com`). This breaks Firewall management plane connectivity.

---

## Step 7 — VNet peering configuration

| Setting | Hub → Spoke | Spoke → Hub |
|---|---|---|
| Allow virtual network access | ✅ Enabled | ✅ Enabled |
| Allow forwarded traffic | ✅ Enabled | ✅ Enabled |
| Allow gateway transit | ✅ Enabled (if hub has gateway) | ❌ Disabled |
| Use remote gateways | ❌ Disabled | ✅ Enabled (if hub has gateway) |

> Peering is bidirectional — create the link on both sides. Peering is non-transitive — spokes cannot communicate directly; all cross-spoke traffic must route through the Firewall.

---

## Step 8 — Monitoring setup

| What to enable | Where | Sends to |
|---|---|---|
| Firewall diagnostic settings | Firewall resource → Diagnostic settings | Log Analytics workspace |
| Logs: `AzureFirewallApplicationRule`, `AzureFirewallNetworkRule`, `AzureFirewallDnsProxy`, `AzureFirewallThreatIntel` | Firewall resource | Log Analytics |
| Metrics: `FirewallHealth`, `DataProcessed`, `SNATPortUtilization` | Firewall resource → Monitoring → Metrics | Azure Monitor |
| NSG Flow Logs (or VNet Flow Logs — preferred for new deployments) | Per-NSG or VNet → Diagnostic settings | Storage + Traffic Analytics |
| Network Watcher Connection Monitor | Network Watcher → Connection Monitor | Log Analytics |

**Key alert rules to configure:**

| Metric/Log | Alert condition | Severity |
|---|---|---|
| `SNATPortUtilization` | > 80% | High — indicates SNAT exhaustion approaching |
| `FirewallHealth` | < 100% | Critical |
| `ThreatIntel` log count | > 0 | Medium — review blocked flows |
| `AzureFirewallNetworkRule` Deny events | Spike baseline | Medium |

---

## Traffic flow summary

| Flow | Path | Inspection point |
|---|---|---|
| Spoke → Internet | Spoke subnet → UDR → Firewall → Internet | Firewall: app rules, threat intel, optional TLS (Premium) |
| Spoke A → Spoke B | Spoke-A UDR → Firewall → Spoke-B UDR | Firewall: network/app rules, IDPS (Premium) |
| Spoke → On-premises | Spoke UDR → Firewall → GatewaySubnet → ER/VPN → on-prem | Firewall: network rules |
| On-premises → Spoke | On-prem → ER/VPN → GatewaySubnet UDR → Firewall → Spoke | Firewall: DNAT + network rules |
| Internet → Spoke (inbound) | Internet → App Gateway WAF (spoke ingress subnet) → backend | WAF (L7); NSG (L4); Firewall not in inbound HTTP/S path |
| Admin → Spoke VM | Admin browser → Bastion (hub) → VNet peering → VM NIC | Bastion auth; no public IP on VM |

> Azure Firewall does **not** apply application rules to inbound connections — use Application Gateway WAF for inbound HTTP/S inspection.

---

## Common pitfalls

| Pitfall | Fix |
|---|---|
| `0.0.0.0/0` alone doesn't force E-W through Firewall | Add explicit UDR entries for every other spoke's CIDR prefix → Firewall IP |
| Spokes bypassing Firewall for on-premises routes | Disable BGP route propagation on spoke route tables |
| FQDN network rules not resolving | Enable DNS proxy on Firewall; set VNet DNS servers to Firewall private IP |
| Firewall management plane broken | Never create Private DNS zones shadowing `*.azure.com`, `*.microsoft.com`, etc. |
| SNAT port exhaustion on Firewall | Attach NAT Gateway to `AzureFirewallSubnet`; each public IP on NAT GW adds 64,512 SNAT ports [VERIFY] |
| Gateway transit not working for spokes | Verify hub peering has `AllowGatewayTransit: true`; spoke peering has `UseRemoteGateways: true` |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure Firewall](../services/azure-firewall.md) | SKU details, rule processing, DNS proxy, SNAT limits, TLS inspection, forced tunneling |
| [Virtual Network](../services/virtual-network.md) | UDR mechanics, BGP propagation, peering settings, subnet sizing, NSG processing |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | Hub subnet requirements, UDR patterns, peering configuration, routing mechanics, gotchas |
| [Network Security Design](../concepts/network-security-design.md) | Defense-in-depth model, Firewall placement patterns, Zero Trust controls, WAF placement |