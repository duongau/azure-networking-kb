# BGP in Azure Networking

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

## Overview

**Border Gateway Protocol (BGP)** is the routing protocol that enables dynamic route exchange between Azure and external networks (on-premises, other clouds, NVAs). Instead of manually configuring static routes, BGP peers automatically advertise and learn prefixes — routes update dynamically as networks change.

In Azure, BGP is used by:
- **ExpressRoute** — private peering to on-premises (mandatory BGP)
- **VPN Gateway** — optional BGP for site-to-site connections
- **Azure Route Server** — BGP with NVAs for dynamic route injection into VNets
- **Virtual WAN** — hub router BGP with branches, NVAs, and ExpressRoute circuits

---

## BGP fundamentals in Azure context

| Concept | Azure behavior |
|---|---|
| **ASN (Autonomous System Number)** | Every BGP participant has an ASN. Azure uses **AS 12076** for ExpressRoute MSEEs and **AS 65515** for internal components (Route Server, Virtual WAN hub router, VPN Gateway default). |
| **eBGP (external BGP)** | Sessions between different ASNs — e.g., your on-premises router (your ASN) peering with Azure ExpressRoute (AS 12076). |
| **iBGP (internal BGP)** | Sessions within the same ASN. Azure Route Server acts as a route reflector within the VNet, distributing routes learned from NVAs. |
| **Route advertisement** | Prefixes are announced to peers; the receiving peer programs them into its routing table. |
| **Route propagation** | In Azure, "propagation" refers to whether VNet route tables learn routes from VPN/ExpressRoute gateways (disabled via route table setting). |
| **BGP timers** | Azure Route Server: keepalive 60s, hold 180s (fixed). ExpressRoute: hold 180s (fixed by Microsoft). |

### Reserved ASNs (do not use)

| Category | ASNs |
|---|---|
| Azure public | 8074, 8075, 12076 |
| Azure private / internal | 65515, 65517, 65518, 65519, 65520 |
| IANA reserved | 23456, 64496–64511, 65535–65551 |

---

## ExpressRoute BGP

ExpressRoute **requires** BGP — there is no static routing option. Each circuit establishes two eBGP sessions (primary + secondary link) with Microsoft Enterprise Edge (MSEE) routers at the peering location.

### Private peering

| Property | Value |
|---|---|
| Microsoft ASN | **12076** |
| Customer ASN | Your ASN (2-byte or 4-byte supported) |
| IP addressing | Private IPs (RFC 1918) or public IPs (your choice) |
| BGP subnet | /29 split into two /30s (IPv4); /125 split into two /126s (IPv6) |
| Session count | 2 (primary + secondary) — both must be active for SLA |

### Microsoft peering

| Property | Value |
|---|---|
| Microsoft ASN | **12076** |
| IP addressing | **Public IPs only** — must be registered in RIR/IRR to your ASN |
| Route filters | **Required** for circuits created after Aug 1, 2017 — no prefixes advertised without a route filter |
| NAT requirement | All traffic must be SNATed to your public IP pool |

### AS-PATH prepending

Prepend your ASN multiple times to make a path less preferred. Use for:
- **Active-passive ER circuits** — prepend on the passive circuit
- **Influencing Microsoft inbound path selection** — longer AS-PATH = less preferred

```
Primary circuit: [YourASN] → 12076 (preferred)
Secondary circuit: [YourASN, YourASN, YourASN] → 12076 (backup)
```

**Warning:** When Microsoft performs maintenance, it prepends **12076** three times on the path being drained. If your active-passive uses equal prepending, traffic may not fail over as expected.

### BGP communities

Microsoft uses BGP communities to tag prefixes by region and service. You can use communities for:
- **Traffic engineering** — prefer specific regions
- **Selective route filtering** — accept only prefixes for regions you care about

| Community format | Meaning |
|---|---|
| `12076:<region-code>` | Azure region identifier |
| `12076:5<region-code>` | Azure service (region-specific) |

### MED vs LOCAL_PREF

| Attribute | Scope | How Azure uses it |
|---|---|---|
| **MED (Multi-Exit Discriminator)** | Inter-AS — influences **inbound** path selection | Microsoft sets MED on routes advertised to you; you can set MED on routes sent to Microsoft |
| **LOCAL_PREF** | Intra-AS — influences **outbound** path selection | You set LOCAL_PREF on your routers to prefer certain paths |

**Azure behavior:** Microsoft generally does not honor customer-set MED for Microsoft peering (traffic engineering is limited). For private peering, MED can influence path selection if you have multiple circuits.

### 4-byte ASN support

ExpressRoute supports both 2-byte (0–65535) and 4-byte (65536–4294967295) ASNs. Use 4-byte ASNs if your organization has exhausted 2-byte space or requires a globally unique ASN.

---

## VPN Gateway BGP

BGP on VPN Gateway is **optional** — you can use static routes instead. BGP enables:
- Dynamic route updates without manual LNG changes
- Failover across multiple tunnels
- Transit routing through Azure

### When to use BGP vs static routes

| Scenario | Recommendation |
|---|---|
| Single S2S tunnel, stable on-premises prefixes | Static routes sufficient |
| Multiple tunnels for HA | BGP — automatic failover without LNG updates |
| On-premises prefix changes frequently | BGP — routes update automatically |
| Transit routing (on-premises → Azure → another on-premises) | BGP required |
| ExpressRoute + VPN coexistence with Route Server | BGP required |

### Active-active with BGP

| Configuration | Description |
|---|---|
| Active-active gateway | Two instances, each with its own public IP |
| BGP peer per instance | On-premises device peers with both Azure gateway IPs |
| Tunnel count | 4 tunnels for full redundancy (2 Azure instances × 2 on-premises devices) |
| Failover | Automatic via BGP — no interruption when one instance fails |

### Custom ASNs

VPN Gateway default ASN is **65515**. You can configure a custom ASN (2-byte) to:
- Avoid ASN conflicts with on-premises or NVAs
- Enable transit scenarios where AS 65515 would cause path loops

**Cannot use:** 0, 23456, 64496–64511, 65517–65520, 65535–65551

### APIPA addresses for BGP peering

For active-active VPN gateways, use **APIPA addresses** (169.254.x.x) as BGP peer IPs. Benefits:
- No collision with on-premises RFC 1918 space
- Simplifies peering configuration
- GA on all non-Basic SKUs

**Limitation:** APIPA addresses are **not supported** with VPN Gateway NAT rules.

---

## Azure Route Server BGP

Azure Route Server is a **control-plane only** service — it exchanges BGP routes but does not forward data traffic. It acts as a route reflector within the VNet.

### Core behavior

| Aspect | Detail |
|---|---|
| ASN | Fixed at **65515** |
| Peer IPs | Two internal IPs (HA pair) — NVAs must peer with **both** |
| BGP timers | Keepalive 60s, hold 180s (fixed) |
| eBGP | Sessions between Route Server and NVAs (NVA ASN must differ from 65515) |
| Route injection | Routes learned from NVAs are programmed into VNet SDN and peered spoke VNets |

### Route injection into spokes

Spoke VNets peered with **Use Remote Route Server** enabled automatically receive routes advertised by NVAs. No UDRs required — routes appear in effective routes.

**Critical rule:** Route Server will not advertise a route with a prefix equal to or longer than the VNet's own address space. To attract spoke-to-spoke traffic through an NVA, the NVA must advertise a **supernet** (shorter prefix).

### Branch-to-branch via NVA

When **branch-to-branch** is enabled on Route Server:
- NVAs learn routes from VPN/ExpressRoute gateways
- VPN/ExpressRoute gateways learn routes from NVAs
- Enables transit: on-premises → NVA → another on-premises

**Default:** Branch-to-branch is **disabled**. Enable explicitly for transit scenarios.

### Routing preference

| Setting | Behavior |
|---|---|
| **ExpressRoute** (default) | ER routes preferred over VPN/NVA routes |
| **VPN** | VPN and NVA routes preferred over ER |
| **AS Path** | Standard BGP best-path — shortest AS-PATH wins |

### Limitations

- IPv6 not supported
- Only 2-byte (16-bit) ASNs supported
- NVA must be in the same VNet or directly peered VNet
- On-premises BGP peering through Route Server not supported
- ExpressRoute circuit-to-circuit transit not supported (use Global Reach)

---

## Virtual WAN BGP

Virtual WAN hubs include a **virtual hub router** that handles all BGP route exchange between gateways (S2S VPN, P2S VPN, ExpressRoute), spoke VNets, and NVAs.

### Hub BGP peering (NVA in spoke)

You can establish BGP sessions between the hub router and an NVA deployed in a spoke VNet:
- Hub router has two BGP peer IPs (HA) — NVA must peer with both
- Routes advertised by NVA are distributed to all hub connections
- Useful for SD-WAN or NGFW in spoke VNets

### Hub routing preference

| Setting | Behavior |
|---|---|
| **ExpressRoute** (default) | ER routes win when multiple path types exist |
| **VPN** | S2S VPN routes preferred |
| **AS Path** | Standard BGP; shortest AS-PATH wins |

### Route-maps (per-connection)

Virtual WAN supports route manipulation per connection:
- **Prefix filtering** — allow/deny specific prefixes
- **AS-PATH manipulation** — prepend, replace, remove ASNs
- **Route aggregation** — summarize prefixes
- **BGP community tagging** — add/replace/remove

**Limitations:**
- Only 2-byte ASNs supported
- Cannot be applied to NVA connections inside the hub
- A prefix cannot be modified by both Route-maps AND NAT rules

---

## Common BGP issues

### AS-PATH loops

Azure Route Server and Virtual WAN hub router both use **AS 65515**. If you have Route Server in multiple hubs, routes containing 65515 in the AS-PATH will be dropped when advertised back to another Route Server.

**Solution:** Configure **as-override** on NVAs — strip AS 65515 from the path before re-advertising cross-region.

### Route filtering failures

| Issue | Cause | Fix |
|---|---|---|
| No routes received from ExpressRoute (Microsoft peering) | Route filter not attached | Attach route filter; select services |
| NVA routes not appearing in spokes | NVA advertising prefix equal to VNet CIDR | Advertise a supernet (shorter prefix) |
| Routes learned but traffic doesn't flow | UDR with higher priority | Check effective routes; verify UDR conflicts |

### Asymmetric routing

Traffic takes different paths inbound vs. outbound — can break stateful firewalls.

| Cause | Mitigation |
|---|---|
| Multiple ER circuits with different preferences | Use consistent AS-PATH prepending |
| VPN + ER with default routing preference | Explicitly set routing preference to match traffic patterns |
| UDRs overriding BGP-learned routes | Ensure UDRs are consistent for both directions |
| ExpressRoute FastPath bypassing firewall | FastPath does not support return traffic inspection; disable for firewall scenarios |

### BGP session flapping

| Cause | Mitigation |
|---|---|
| Hold timer expiring (link issues) | Enable BFD on ExpressRoute private peering — reduces detection to <1 sec |
| Route count exceeding limits | ExpressRoute: 4,000 IPv4 / 10,000 IPv4 (Premium). Check limits. |
| MTU issues | ExpressRoute MTU is 1,400 — ensure on-premises routers don't exceed |

---

## Related pages

| Page | Relationship |
|---|---|
| [ExpressRoute](../services/expressroute.md) | BGP private/Microsoft peering, Global Reach, resiliency |
| [VPN Gateway](../services/vpn-gateway.md) | Optional BGP for S2S, active-active, NAT |
| [Route Server](../services/route-server.md) | NVA BGP peering, route injection |
| [Virtual WAN](../services/virtual-wan.md) | Hub router BGP, route-maps, routing preference |
| [User-Defined Routes](./user-defined-routes.md) | Interaction between BGP and UDRs |

---

## Source pages

| Source | Notes |
|---|---|
| [ExpressRoute](../services/expressroute.md) | AS 12076, BGP communities, MED, 4-byte ASN, hold timers |
| [VPN Gateway](../services/vpn-gateway.md) | BGP overview, APIPA addresses, active-active, custom ASN |
| [Route Server](../services/route-server.md) | eBGP with NVAs, branch-to-branch, routing preference, fixed timers |
| [Virtual WAN](../services/virtual-wan.md) | Hub routing preference, route-maps, reserved ASNs |