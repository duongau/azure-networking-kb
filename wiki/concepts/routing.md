# Azure Network Routing

> **Compiled:** 2025-07-31 | **Type:** Concept | **Source services:** 6 | **Status:** ✅ current

## How Azure routing works

Azure uses a **software-defined networking (SDN)** layer to route traffic within and between virtual networks. Every NIC in every VM has an effective route table that Azure programs automatically — combining system routes, BGP-learned routes, and user-defined routes (UDRs). The platform evaluates each packet's destination against this table using **longest prefix match (LPM)**: the most-specific matching prefix wins, regardless of route type. When two routes have identical prefix length, a strict priority order breaks the tie: **UDR > BGP > System route**.

The routing control plane involves three distinct mechanisms that can coexist:

| Layer | What programs routes | Examples |
|---|---|---|
| **System routes** | Azure SDN — automatic | VNet address space, internet default route, peering routes |
| **BGP** | VPN Gateway, ExpressRoute gateway, Azure Route Server, Virtual WAN hub router | On-premises prefixes, NVA-advertised routes, cross-region routes |
| **UDR** | Customer-defined route tables attached to subnets | Force-tunnel to firewall, drop specific prefixes, override gateway routes |

---

## System routes

Azure automatically creates and maintains system routes for every subnet in a VNet. These are not visible or editable but can be overridden by UDRs.

| Route | Destination | Next hop | Created when |
|---|---|---|---|
| **VNet local** | VNet address space prefix(es) | Virtual network | VNet is created |
| **Internet default** | `0.0.0.0/0` | Internet | VNet is created |
| **RFC 1918 black holes** | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`, `100.64.0.0/10` | None (drop) | VNet is created |
| **Peering route** | Peered VNet's address space | Virtual network peering | VNet peering is configured |
| **Gateway route** | On-premises prefixes learned via BGP | Virtual network gateway | BGP propagation enabled + gateway active |
| **Service endpoint** | Azure service prefix (e.g., Storage, SQL) | Virtual network (backbone) | Service endpoint enabled on subnet |

> **Platform-reserved address:** `168.63.129.16/32` is Azure's internal host DNS and platform management IP. It is not assignable and must never be blocked in NSGs or UDRs — blocking it breaks gateway management, DNS resolution, and health probes.

**Key behavior:** System routes provide sensible defaults but are intentionally overridable. A UDR with the same or longer prefix always wins.

---

## User-Defined Routes (UDRs)

UDRs let you override system and BGP routes on a **per-subnet** basis. You create a route table resource, add route entries, and associate the table with one or more subnets.

### Route table structure

Each entry is: **address prefix** + **next hop type** + (optional) next hop IP address.

### Next hop types

| Next hop type | Use case | Notes |
|---|---|---|
| **Virtual Appliance** | Send traffic to NVA/firewall private IP | Must specify next hop IP; NVA must have IP forwarding enabled on its NIC |
| **VNet Gateway** | Send traffic into the VPN gateway | VPN gateways **only** — ExpressRoute gateway is NOT a valid UDR next hop [VERIFY] |
| **Virtual Network** | Keep traffic within the VNet SDN | Overrides a Virtual Appliance or None route back to normal |
| **Internet** | Send traffic to public internet | Explicitly overrides a force-tunnel UDR for specific prefixes |
| **None** | Drop the traffic (black hole) | Use to suppress specific prefixes; no ICMP unreachable returned |

### Limits [VERIFY]

| Limit | Default | With VNet Manager |
|---|---|---|
| Routes per route table | 400 | 1,000 |
| Routes using service tag as prefix | 25 per table | 25 per table |
| Route tables per subscription per region | 200 | — |

### Force-tunneling

The most common UDR pattern: a `0.0.0.0/0 → Virtual Appliance` route pointing at an Azure Firewall or NVA private IP. This redirects all internet-bound traffic through the security appliance for inspection before it egresses.

```
Subnet route table:
  0.0.0.0/0  →  Virtual Appliance  →  10.0.0.4 (Azure Firewall private IP)
```

> **Critical:** When force-tunneling via UDR, you **must** also **disable BGP route propagation** on that subnet's route table. If propagation is left enabled, gateway-learned routes (including a default route from on-premises or ER) will be injected and may override or conflict with the UDR `0.0.0.0/0`. See [Common gotchas](#common-gotchas).

### Associating route tables to subnets

- One route table per subnet (one-to-one association)
- A single route table can be associated with multiple subnets
- Routes take effect immediately upon association
- **GatewaySubnet**: UDRs on `GatewaySubnet` are not supported and will break gateway connectivity — never attach a custom route table to GatewaySubnet

### BGP route propagation toggle

Each route table has a **Gateway route propagation** setting (enabled by default):
- **Enabled:** BGP routes learned by the VNet's gateways are automatically injected into the subnet's effective route table
- **Disabled:** Gateway BGP routes are suppressed for that subnet; only system routes and UDR entries apply

Disable this on subnets that have a `0.0.0.0/0` UDR to prevent the gateway from injecting on-premises default routes that override your force-tunnel.

---

## BGP in Azure

Border Gateway Protocol (BGP) is the dynamic routing protocol Azure uses for route exchange between gateways, NVAs, and on-premises networks. Azure's routing control plane uses BGP extensively — even when customers aren't explicitly configuring it.

### How BGP routes enter the VNet

| Source | Mechanism | Result |
|---|---|---|
| VPN Gateway (S2S) | BGP peering between Azure gateway (ASN 65515 [VERIFY]) and on-premises CPE | On-premises prefixes injected into VNet subnet route tables |
| ExpressRoute Gateway | BGP peering between Azure gateway and MSEE (Microsoft ASN 12076) | On-premises private prefixes injected into all subnets (unless propagation disabled) |
| Azure Route Server | BGP peering between Route Server and NVA | NVA-advertised prefixes programmed into VNet SDN |
| Virtual WAN hub router | BGP between hub router and all connected gateways/NVAs | Routes distributed across all hub connections |

### ASN requirements

| Category | ASNs | Notes |
|---|---|---|
| **Microsoft / Azure public** | 8074, 8075, **12076** | 12076 = ER MSEE; do not use for NVAs |
| **Azure internal private** | 65515, 65517, 65518, 65519, 65520 | Azure VPN Gateway default = 65515 [VERIFY] |
| **IANA reserved** | 23456, 64496–64511, 65535–65551 | Never use |
| **Valid private range for NVAs** | 64512–65534 (excluding Azure reserved above) | Use for customer NVAs, Route Server peers, on-premises CPE |
| **4-byte (32-bit) ASNs** | 1,000,000+ | Supported by VPN Gateway and ExpressRoute; **NOT** supported by Azure Route Server (16-bit only) |

### BGP timers

| Service | Keepalive | Hold timer |
|---|---|---|
| Azure Route Server | 60 s | 180 s |
| ExpressRoute (fixed by Microsoft) | 60 s | 180 s |
| VPN Gateway | Configurable | Configurable |

### ExpressRoute BGP communities

ExpressRoute Microsoft peering uses BGP communities to tag route advertisements by scope, enabling you to filter which prefixes you accept:

| Community | Prefixes included |
|---|---|
| Regional service prefixes | Azure services in the ER peering location's region |
| National prefixes | All Azure services in the geopolitical area (Standard SKU reach) |
| Global prefixes | Azure services globally (Premium SKU required) |
| Exchange community tags | Used by some providers; pass-through to Microsoft |

### BGP path selection in Azure

Azure gateways apply standard BGP best-path selection. Operators can influence path preference via:
- **AS path prepending** — longer AS path = less preferred; commonly used to steer failover
- **MED (Multi-Exit Discriminator)** — accepted but behavior varies by service
- **BGP communities** — honored on ExpressRoute Microsoft peering for traffic engineering
- **Route Server routing preference** — overrides pure AS path with an explicit ExpressRoute > VPN > AS Path hierarchy

---

## Azure Route Server

Azure Route Server is a managed BGP route reflector inside a VNet. It solves a fundamental scale problem: without Route Server, every NVA-injected route must be maintained as a manual UDR entry in every subnet route table. Route Server eliminates this by letting the NVA advertise routes dynamically via BGP — which Route Server then programs into the VNet SDN automatically.

**Route Server operates in the control plane only.** It does not forward or inspect data traffic.

### How it works

```
NVA (BGP speaker)
    ↕ eBGP (multi-hop)
Azure Route Server (two internal instances — peer with BOTH)
    ↕ programs routes
VNet SDN (all VMs in VNet + spoke VNets using remote Route Server)
```

- NVA establishes eBGP sessions with **both** Route Server IPs (high-availability pair)
- Route Server learns NVA routes → programs them into every VM's effective route table
- Route Server learns VNet prefixes → advertises them back to the NVA
- Spoke VNets peered with **Use Remote Route Server** receive dynamically injected routes — no per-spoke UDRs needed

### Key configuration requirements

| Requirement | Value |
|---|---|
| Dedicated subnet name | Must be exactly `RouteServerSubnet` |
| Subnet minimum size | `/26` |
| Public IP SKU | Standard SKU (Standard v2 **not** supported) |
| Max Route Servers per VNet | 1 |
| NVA ASN | Must differ from 65515; 16-bit only |
| NVA location | Same VNet or directly peered VNet (on-premises NVA not supported) |
| IPv6 | **Not supported** — deploying Route Server in a dual-stack VNet breaks IPv6 connectivity |

### Branch-to-branch route exchange

When **branch-to-branch** is enabled on Route Server, it mediates route exchange between NVAs, ExpressRoute gateways, and VPN gateways in the same VNet. Disabled by default.

- NVAs learn on-premises prefixes from ER/VPN gateways
- ER and VPN gateways learn NVA-advertised routes
- **Limitation:** Azure VPN Gateway will **not** advertise a default route (0.0.0.0/0) learned from Route Server to on-premises peers
- **Limitation:** ER circuit-to-circuit transit is NOT supported through Route Server — use [ExpressRoute Global Reach](../services/expressroute.md) instead
- P2S VPN transit is **not** supported (S2S only)

### Route advertisement rules

- Route Server will **not** advertise routes equal to or longer than the VNet's own address space back to NVAs
- NVAs must advertise a **supernet** (shorter/less-specific prefix than the VNet address space) to influence intra-VNet routing
- `NO_ADVERTISE` BGP community: routes tagged with this community are not forwarded to other peers (e.g., suppresses re-advertisement to ER)

### ECMP support

When multiple NVAs advertise the same prefix with equal AS path length, Route Server programs all NVA next hops — VMs use ECMP across them. NVAs can advertise the frontend IP of an internal load balancer as the BGP next hop for active/active HA.

### Routing preference

| Setting | Behavior |
|---|---|
| **ExpressRoute** (default) | ER-learned routes preferred over VPN/NVA routes |
| **VPN** | VPN gateway and NVA routes preferred over ER |
| **AS Path** | Standard BGP best-path; shorter AS path wins |

---

## Virtual WAN routing

Virtual WAN replaces customer-managed route tables and UDRs with a managed hub router that automatically distributes routes across all connected spokes, branches, and gateways. Understanding its routing model is essential for large-scale deployments.

### Route tables

Every hub has a built-in `defaultRouteTable`. Standard SKU supports custom route tables.

| Concept | Definition |
|---|---|
| **Route table** | Stores static routes and BGP-learned routes for the hub. Connections read routes from associated route tables. |
| **Association** | A connection (VNet, VPN branch, ER circuit) is *associated with* one route table — it uses that table's routes for traffic forwarding |
| **Propagation** | A connection *propagates* its routes to one or more route tables — making its prefixes available to connections using those tables |
| **Labels** | Named groups of route tables. Built-in label `Default` applies to all `defaultRouteTables` across all hubs in the WAN. Used for multi-hub propagation rules |
| **Static routes** | Manually injected into a route table with a next-hop NVA IP in a spoke VNet. Do NOT use hub router IPs as next hop |

### Default routing behavior

Out of the box (no customization):
- All connections associate **and** propagate to `defaultRouteTable`
- Result: any-to-any connectivity — branches, VNets, and ER circuits can all reach each other
- Branch-to-branch must be enabled at the WAN level (enabled by default)

### Hub routing preference (HRP)

Controls best-path selection when multiple path types exist (e.g., both ER and VPN advertise the same prefix):

| Setting | Preference order |
|---|---|
| **ExpressRoute** (default) | ER routes win over VPN and NVA routes |
| **VPN** | VPN and NVA routes win over ER |
| **AS Path** | Standard BGP; shorter AS path wins regardless of connection type |

### Routing Intent and Routing Policies

Routing Intent is the Virtual WAN mechanism for force-tunneling all traffic through a security appliance (Azure Firewall, NVA, or SaaS security) without manual route tables.

| Policy type | Traffic redirected |
|---|---|
| **Internet Traffic Routing Policy** | All internet-bound (`0.0.0.0/0`) traffic from all branches and VNets → hub firewall |
| **Private Traffic Routing Policy** | All branch-to-VNet, VNet-to-VNet, and inter-hub private traffic → hub firewall |

> **Critical limitation:** The default route (`0.0.0.0/0`) is **hub-local** — it does NOT propagate across hub-to-hub links. Each hub with a security appliance must independently learn or originate the default route. If hub A has a firewall and hub B does not, branch VNets connected to hub B are not protected.

### Route-maps

Per-connection route manipulation, applied inbound or outbound. Supported actions:

| Action | Supported |
|---|---|
| Prefix filtering (match specific prefixes) | ✅ |
| Route aggregation / summarization | ✅ |
| AS-PATH prepend / replace / remove | ✅ |
| BGP community add / replace / remove | ✅ |
| More-specific route injection | ❌ (summarization only — cannot create longer prefixes) |
| 4-byte ASNs | ❌ (2-byte only) |

> Route-maps cannot be applied to NVA connections **inside** the hub — only to VNet, S2S VPN, P2S VPN, and ER connections.

### Virtual WAN routing limits [VERIFY]

| Limit | Value |
|---|---|
| Max routes per hub (all sources combined) | 10,000 |
| Single TCP flow throughput cap | 1.5 Gbps (regardless of RIU count) |
| Max directly-connected VNet address spaces per Routing Intent hub | 600 |
| Routing Infrastructure Units (max) | 50 (= 50 Gbps hub router) |

---

## Routing priority resolution

The table below shows which route wins in common conflict scenarios. Assumes longest-prefix-match has already selected a candidate set; this is the tiebreak within same-prefix-length routes.

| Scenario | Route type | Winner | Explanation |
|---|---|---|---|
| UDR `10.10.0.0/24 → None` vs. system route `10.10.0.0/16 → VNet` | Different prefix lengths | UDR `/24` wins | LPM: `/24` is more specific than `/16` |
| UDR `0.0.0.0/0 → Virtual Appliance` vs. BGP-learned `0.0.0.0/0` from ER | Same prefix, UDR vs. BGP | **UDR wins** | UDR always overrides BGP at same prefix length |
| UDR `0.0.0.0/0 → Firewall` but BGP propagation enabled on subnet | Same prefix | **Unpredictable / BGP may override** | BGP propagation must be **disabled** to prevent this |
| BGP route `172.16.0.0/12` from VPN vs. system route `172.16.0.0/12 → None` | Same prefix, BGP vs. system | **BGP wins** | BGP outranks system routes at same prefix length |
| Two BGP routes to same prefix, one from ER, one from VPN | Same prefix, BGP vs. BGP | **ER wins** (default) | Route Server / Virtual WAN routing preference: ExpressRoute > VPN |
| UDR `10.0.0.0/8` on spoke subnet vs. peering route `10.10.0.0/16` | Different prefix lengths | Peering `/16` wins for `10.10.x.x` traffic | LPM: more-specific peering route wins for destinations inside `10.10.x.x` |

### Full priority stack (same prefix length)

```
1. UDR (user-defined route table entry)           ← ALWAYS wins
2. BGP route (from gateway or Route Server)        ← Wins over system
3. System route (Azure-created)                    ← Lowest priority
```

---

## NVA routing patterns

### Pattern 1: Hub NVA with spoke UDRs

The classic hub-and-spoke design. Azure Firewall or third-party NVA sits in the hub VNet. Every spoke subnet has a route table with:
- `0.0.0.0/0 → Virtual Appliance → <NVA/Firewall private IP>` (force-tunnel to internet)
- Optionally: specific hub/on-premises prefixes → Virtual Appliance (east-west inspection)

**Problem at scale:** Every spoke subnet needs a UDR entry for every NVA-managed prefix. As routes change, all UDRs must be updated manually.

### Pattern 2: Route Server eliminates UDR sprawl

With Azure Route Server in the hub:
1. NVA peers via BGP with Route Server and advertises routes (e.g., `0.0.0.0/0`, on-premises prefixes)
2. Route Server programs those routes into **all VMs** in the hub VNet and all spoke VNets using Remote Route Server
3. No per-subnet UDR updates required — route changes propagate automatically within BGP convergence time

> NVA must advertise a **supernet** (less-specific than the VNet CIDR) to influence routing within the VNet.

### Pattern 3: ECMP across multiple NVAs

When multiple NVAs advertise the same route with equal AS path length to Route Server, Azure programs all NVA IPs as next hops. VMs use **ECMP** (per-flow load balancing) across all NVAs. Best combined with NVAs advertising the ILB frontend IP as next hop for symmetric routing:

```
NVA-1 → BGP advertise 0.0.0.0/0, next-hop = ILB-frontend-IP
NVA-2 → BGP advertise 0.0.0.0/0, next-hop = ILB-frontend-IP
Route Server programs: 0.0.0.0/0 → ILB-frontend-IP (single next hop, load balances internally)
```

### Pattern 4: Hairpin routing (SNAT on NVA)

When an NVA inspects traffic between two Azure VMs (east-west), both VMs' traffic arrives at and exits the same NVA interface. For stateful firewalls: the NVA must SNAT the source IP to its own IP so that return traffic flows back through the same NVA instance — otherwise asymmetric routing breaks the stateful session.

```
VM-A (10.0.1.4) → NVA (10.0.0.5) → SNAT to 10.0.0.5 → VM-B (10.0.2.4)
VM-B replies to 10.0.0.5 → NVA (de-NATed) → VM-A
```

Without SNAT: VM-B's reply follows its own route table (e.g., directly to VM-A), bypassing the NVA entirely — stateful session breaks.

### Pattern 5: NVA-to-NVA multi-region routing

In multi-region hub-and-spoke with Route Server:
1. Each region has a hub VNet with Route Server + NVA
2. NVAs maintain IPsec/VXLAN tunnels between regions
3. NVAs re-advertise cross-region routes via BGP to Route Server

**AS path loop prevention problem:** Both Route Servers use ASN 65515. If Region-A's Route Server advertises a route, Region-B's NVA learns it, re-advertises to Region-B's Route Server — which drops it because 65515 is already in the AS path. **Fix:** NVAs must use **AS-override** or **AS-path rewrite** to strip/replace 65515 from cross-region advertisements.

---

## Common gotchas

| Gotcha | Detail | Fix |
|---|---|---|
| **BGP propagation not disabled on force-tunnel subnet** | If BGP propagation is enabled on a subnet with `0.0.0.0/0 → Virtual Appliance`, gateway-learned routes (including an on-premises default route over ER) will be injected and may override the UDR | Disable **Gateway route propagation** on all route tables that have a `0.0.0.0/0` UDR |
| **UDR on GatewaySubnet** | Attaching a route table to `GatewaySubnet` breaks gateway functionality — Azure does not support UDRs on the gateway subnet | Never attach a route table to GatewaySubnet |
| **ExpressRoute routes flood all subnets** | ER-learned BGP routes are injected into ALL subnet route tables by default (BGP propagation is enabled by default) | Disable propagation on any subnet that must not receive ER routes (e.g., subnets with conflicting UDRs) |
| **UDR next hop `VNet Gateway` does not support ExpressRoute** | The `VNet Gateway` next hop type in UDRs only works with VPN gateways, not ExpressRoute gateways — this is a hard platform constraint | Use BGP propagation from the ER gateway (automatic) rather than UDR for ER routing |
| **Transitive routing blocked by VNet peering** | VNet peering is non-transitive by default: Spoke-A cannot reach Spoke-B via the hub without explicit routing | Deploy NVA or Azure Firewall in hub + UDRs in spokes, or use Azure Route Server with NVA BGP advertisements |
| **Asymmetric routing with dual stateful NVAs** | Two NVAs without SNAT: forward flow goes through NVA-1, return flow may go through NVA-2 → stateful session breaks | Use SNAT (hairpin) on each NVA, or use an ILB with session affinity as the common next hop |
| **Default route (0.0.0.0/0) over ER hijacks Microsoft peering** | Advertising `0.0.0.0/0` over ER private peering force-tunnels ALL traffic on-premises — including traffic to Azure PaaS services that use Microsoft peering (Storage, SQL, etc.) | Add service endpoints to keep Azure PaaS traffic on the backbone; do not rely on private peering for internet breakout |
| **Route Server + IPv6** | Deploying Route Server in a dual-stack VNet breaks IPv6 connectivity for the VNet | Do not deploy Route Server in dual-stack VNets until IPv6 support is added |
| **Virtual WAN: spoke VNet cannot have VPN Gateway or Route Server** | A spoke VNet connected to a Virtual WAN hub cannot also have its own gateway or Route Server | Use standalone hub-and-spoke with customer-managed hub if you need per-VNet gateways |
| **Virtual WAN: 0.0.0.0/0 does not cross hub-to-hub links** | Default route is hub-local — it is not propagated from one Virtual WAN hub to another | Each hub must independently originate or learn the default route (typically from its own Azure Firewall or on-premises advertisement) |
| **Virtual WAN: ECMP for ExpressRoute not on by default** | ER ECMP load balancing across multiple ER circuits is disabled by default in Virtual WAN hubs | Create a Route-map (can be empty) on the hub to trigger a hub software upgrade that enables ER ECMP |
| **Route Server AS path loop with multi-region** | Route Servers in different hubs share ASN 65515; cross-hub route advertisements are dropped by the receiving Route Server due to its own ASN in the path | NVAs must use AS-override/AS-path rewrite to strip 65515 from cross-region advertisements |
| **Route Server: NVA must peer with BOTH IPs** | Route Server exposes two internal BGP peer IPs (two HA instances); NVA must establish sessions with both or risk routing blackholes if the unpeered instance becomes primary | Configure BGP on NVA to peer with both Route Server IPs |

---

## Related pages

- [Azure Virtual Network](../services/virtual-network.md) — VNet is the routing boundary; system routes, UDRs, NSGs, and peering all originate here
- [Azure Route Server](../services/route-server.md) — Managed BGP route reflector; eliminates UDR sprawl for NVA-based routing at scale
- [Azure VPN Gateway](../services/vpn-gateway.md) — Hybrid connectivity via IPsec/IKE; BGP route propagation injects on-premises prefixes into VNet routing
- [Azure ExpressRoute](../services/expressroute.md) — Private dedicated connectivity; ER gateway propagates on-premises prefixes to all VNet subnets via BGP
- [Azure Firewall](../services/azure-firewall.md) — Most common force-tunnel UDR target (`0.0.0.0/0 → Virtual Appliance`); inspect all egress before it leaves Azure
- [Azure Virtual WAN](../services/virtual-wan.md) — Managed hub-and-spoke at scale; replaces customer-managed route tables with hub router, defaultRouteTable, and Routing Intent