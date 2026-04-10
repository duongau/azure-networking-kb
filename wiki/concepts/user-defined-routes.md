# User-Defined Routes (UDRs) and Effective Routes

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

## Route table mechanics

Azure uses **longest-prefix-match** routing. When a packet leaves a VM, the effective route table is evaluated — the most specific matching prefix determines the next hop.

### Route sources and priority

When multiple routes exist for the **same prefix**, priority order is:

| Priority | Source | Added by |
|---|---|---|
| 1 (Highest) | **User-defined routes (UDRs)** | Customer in route table |
| 2 | **BGP routes** | VPN/ExpressRoute gateway propagation |
| 3 (Lowest) | **System routes** | Azure automatically |

For **different prefix lengths**, the longer (more specific) prefix **always wins**, regardless of source.

### System default routes

Azure automatically creates these routes for every subnet:

| Prefix | Next hop | Purpose |
|---|---|---|
| VNet address space (e.g., `10.0.0.0/16`) | VirtualNetwork | Intra-VNet routing |
| `0.0.0.0/0` | Internet | Default internet egress |
| `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | None | Drop RFC 1918 traffic not matched by VNet |
| `100.64.0.0/10` | None | Drop CGNAT range traffic |

### Peering-learned routes

When VNet peering is established, routes to the peered VNet's address space are injected automatically:

| Next hop type | Meaning |
|---|---|
| `VNetPeering` | Local peering (same region) |
| `VNetGlobalPeering` | Global peering (cross-region) |

**Critical:** Peering routes are **more specific** than a default route. If Spoke-A (`10.1.0.0/16`) peers with Hub (`10.0.0.0/16`), traffic from Spoke-A to `10.0.0.5` matches the peering route `/16`, not a UDR for `0.0.0.0/0`.

### BGP-propagated routes

When a VPN or ExpressRoute gateway propagates routes into the VNet, they appear in effective routes with next hop type `VirtualNetworkGateway`. These are **lower priority than UDRs** for the same prefix.

**Disabling BGP propagation:** On a route table, set `Disable BGP route propagation = Yes`. This prevents gateway-learned routes from appearing in the subnet's effective routes. Essential for forcing traffic through a firewall.

---

## UDR creation and subnet association

### Creating a route table

1. Create a **Route Table** resource in the same region as the VNet
2. Add **routes** — each route has:
   - **Name** (display only)
   - **Address prefix** (destination CIDR)
   - **Next hop type** (see below)
   - **Next hop address** (if applicable)
3. Associate the route table with one or more **subnets**

### Next hop types

| Next hop type | Behavior | When to use |
|---|---|---|
| **Virtual appliance** | Forward to a specific IP (NVA/Firewall private IP) | Routing through Azure Firewall, third-party NVA |
| **Virtual network gateway** | Forward to VPN gateway | Routing to on-premises via VPN (not ExpressRoute!) |
| **Virtual network** | Use VNet system routes | Override a more specific route back to default VNet routing |
| **Internet** | Forward to public internet via Azure edge | Direct internet egress (bypasses default outbound) |
| **None** | Drop the packet | Blackhole specific prefixes |

> ⚠️ **`Virtual network gateway` next hop supports VPN only** — not ExpressRoute. ExpressRoute routes are injected via BGP propagation; you cannot create a UDR pointing to an ExpressRoute gateway.

---

## Force-tunneling through Azure Firewall

The most common hub-spoke routing pattern: force all spoke internet traffic through a centralized Azure Firewall.

### Configuration

**Spoke subnet route table:**

| Prefix | Next hop type | Next hop address |
|---|---|---|
| `0.0.0.0/0` | Virtual appliance | Azure Firewall private IP |

**Settings:**
- `Disable BGP route propagation = Yes` — prevents on-premises routes from bypassing the firewall

**Result:** All traffic from VMs in the spoke subnet that doesn't match a more specific route (e.g., VNet address space, peering routes) is sent to the firewall for inspection and egress.

### Internet service tag route

Instead of `0.0.0.0/0`, you can use the `Internet` service tag:

| Prefix | Next hop type | Next hop address |
|---|---|---|
| `Internet` (service tag) | Virtual appliance | Azure Firewall private IP |

This routes only internet-bound traffic (matching Azure's definition of Internet IPs) while leaving other traffic on default paths.

**Limit:** 25 routes with service tags per route table [VERIFY].

---

## Hub-spoke UDR pattern

### Problem: Peering routes bypass the firewall

In a hub-spoke topology where Spoke-A (`10.1.0.0/16`) and Spoke-B (`10.2.0.0/16`) both peer with the Hub (`10.0.0.0/16`):
- A `0.0.0.0/0 → Firewall` route on Spoke-A does NOT force traffic to Spoke-B through the firewall
- The peering route to `10.2.0.0/16` (next hop: `VNetPeering`) is more specific than `/0` and takes precedence

### Solution: Explicit UDRs for each spoke

**Spoke-A route table:**

| Prefix | Next hop | Effect |
|---|---|---|
| `0.0.0.0/0` | Firewall IP | Internet via Firewall |
| `10.2.0.0/16` | Firewall IP | Traffic to Spoke-B via Firewall |
| `10.3.0.0/16` | Firewall IP | Traffic to Spoke-C via Firewall |
| (BGP propagation disabled) | — | On-premises via Firewall |

**Spoke-B route table:**

| Prefix | Next hop | Effect |
|---|---|---|
| `0.0.0.0/0` | Firewall IP | Internet via Firewall |
| `10.1.0.0/16` | Firewall IP | Traffic to Spoke-A via Firewall |
| `10.3.0.0/16` | Firewall IP | Traffic to Spoke-C via Firewall |

**Repeat for all spokes.**

### Alternative: RFC 1918 supernet

Instead of per-spoke entries, use RFC 1918 supernets:

| Prefix | Next hop |
|---|---|
| `10.0.0.0/8` | Firewall IP |
| `172.16.0.0/12` | Firewall IP |
| `192.168.0.0/16` | Firewall IP |
| `0.0.0.0/0` | Firewall IP |

**Requirement:** BGP propagation must be **disabled** — otherwise, peering routes (e.g., `10.1.0.0/16`) are more specific than `/8` and still bypass the firewall.

### Return traffic routing

For traffic initiated from spoke VMs, return traffic from the firewall/internet flows naturally. But for traffic initiated **toward** spoke VMs (e.g., on-premises to spoke via hub):

**Hub GatewaySubnet route table:**

| Prefix | Next hop |
|---|---|
| `10.1.0.0/16` | Firewall IP |
| `10.2.0.0/16` | Firewall IP |

This ensures on-premises-initiated traffic passes through the firewall before reaching spokes.

---

## Service tag routes

UDRs support **service tags** as address prefixes for certain next hop types:

| Service tag | Use case |
|---|---|
| `Internet` | Route internet traffic to NVA |
| `VirtualNetwork` | Override to drop traffic |
| `AzureCloud` | Route Azure-bound traffic |
| `Storage`, `Sql`, etc. | Route Azure service traffic |

**Limitations:**
- Max 25 service tag routes per route table [VERIFY]
- Not all service tags supported — check Azure documentation

---

## Diagnosing effective routes

### Azure Portal

1. Navigate to the VM → **Networking**
2. Click the **NIC** resource
3. Click **Effective routes**

Shows all routes (system + UDR + BGP) with source and state.

### Azure CLI

```bash
az network nic show-effective-route-table \
  --resource-group <rg-name> \
  --name <nic-name> \
  --output table
```

### PowerShell

```powershell
Get-AzEffectiveRouteTable -ResourceGroupName <rg-name> -NetworkInterfaceName <nic-name>
```

### Interpreting route states

| State | Meaning |
|---|---|
| **Active** | Route is being used for matching traffic |
| **Invalid** | Route is configured but cannot be used — typically because the next hop IP is unreachable or the next hop type is invalid |

**Common "Invalid" causes:**
- Next hop IP doesn't exist in the VNet
- Next hop IP is in a different VNet (not reachable)
- Next hop type is `Virtual network gateway` but no gateway exists
- Circular route (routes to self)

---

## Common mistakes

### Missing return routes (asymmetric routing)

**Symptom:** Traffic flows one direction but responses don't return.

**Cause:** UDRs force outbound traffic through firewall, but inbound/return traffic bypasses it.

**Fix:** Add UDRs on **GatewaySubnet** to route return traffic through the firewall.

### AzureFirewallSubnet UDR restrictions

| Rule | Detail |
|---|---|
| Cannot add routes that bypass the Firewall | Any route that would cause asymmetric routing is invalid |
| Cannot add `0.0.0.0/0` → Internet | Breaks Firewall operation |
| Can add routes to on-premises | Used for forced tunneling scenarios |

**Forced tunneling:** If Firewall is deployed with forced tunneling enabled, it has a **management NIC** for control plane traffic. Data plane traffic can route to on-premises NVA.

### GatewaySubnet UDR restrictions

| Rule | Detail |
|---|---|
| Next hop cannot be `Internet` | Breaks VPN/ExpressRoute operation |
| Route must not conflict with gateway operation | Routing gateway traffic to an NVA may break tunnel establishment |
| UDRs to spoke prefixes are valid | Used to route on-premises→spoke through firewall |

### BGP propagation not disabled

**Symptom:** Traffic to on-premises bypasses the firewall even though you have `0.0.0.0/0 → Firewall`.

**Cause:** BGP-propagated routes (e.g., `192.168.1.0/24` from on-premises) are more specific than `/0` and take precedence.

**Fix:** Disable BGP route propagation on spoke subnet route tables.

### Peering routes overriding default route

**Symptom:** Spoke-to-spoke traffic bypasses firewall.

**Cause:** Peering-learned routes (`10.2.0.0/16` → `VNetPeering`) are more specific than `0.0.0.0/0`.

**Fix:** Add explicit UDRs for each spoke prefix pointing to the firewall.

---

## Related pages

| Page | Relationship |
|---|---|
| [Virtual Network](../services/virtual-network.md) | System routes, subnet route tables |
| [Azure Firewall](../services/azure-firewall.md) | Centralized egress, forced tunneling |
| [Hub-Spoke Networking](./hub-spoke-networking.md) | UDR patterns for spoke isolation |
| [Route Server](../services/route-server.md) | BGP route injection as alternative to UDRs |
| [Network Security Design](./network-security-design.md) | UDRs as part of defense-in-depth |

---

## Source pages

| Source | Notes |
|---|---|
| [Virtual Network](../services/virtual-network.md) | Route table basics, system routes, BGP propagation |
| [Azure Firewall](../services/azure-firewall.md) | Forced tunneling, AzureFirewallSubnet restrictions |
| [Hub-Spoke Networking](./hub-spoke-networking.md) | UDR sprawl, AVNM routing configs |
| [Network Security Design](./network-security-design.md) | Zero Trust routing patterns |