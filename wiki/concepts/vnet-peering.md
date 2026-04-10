# VNet Peering

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

## What VNet peering is

VNet peering connects two Azure virtual networks so resources in each can communicate using private IP addresses over the Microsoft backbone. Traffic between peered VNets does not traverse the public internet.

Two types:
- **Local peering** — VNets in the same Azure region
- **Global peering** — VNets in different Azure regions

---

## Local vs global peering

| Property | Local peering | Global peering |
|---|---|---|
| **Regions** | Same region | Different regions |
| **Latency** | Same as intra-VNet (<1 ms typically) | Cross-region latency (varies by distance) |
| **Bandwidth** | No specific limit; VNet-level limits apply | No specific limit; subject to VM bandwidth |
| **Basic Load Balancer** | Frontend IPs reachable | ❌ **Not reachable** across global peering |
| **Pricing** | Ingress + egress per GB | Higher per-GB rate than local [VERIFY] |
| **Transitivity** | Non-transitive | Non-transitive |

### Pricing notes

Both directions of peering traffic are charged:
- VNet A → VNet B: egress charge on A
- VNet B → VNet A: egress charge on B

Global peering rates are higher than local peering. Check the [VNet peering pricing page](https://azure.microsoft.com/pricing/details/virtual-network/) for current rates per region pair.

---

## Peering properties

When creating a peering, you configure these settings **on each side** (both VNets):

### AllowVirtualNetworkAccess

| Setting | Effect |
|---|---|
| **Enabled** (default) | VMs in this VNet can communicate with VMs in the peered VNet |
| **Disabled** | Blocks all communication; peering exists but traffic doesn't flow |

### AllowForwardedTraffic

| Setting | Effect |
|---|---|
| **Enabled** | This VNet accepts traffic forwarded by an NVA in the peered VNet |
| **Disabled** (default) | Traffic forwarded by NVAs is dropped |

**When to enable:** On spoke VNets peering with a hub that contains a firewall/NVA. The NVA forwards traffic between spokes — spokes must accept forwarded traffic.

### AllowGatewayTransit

| Setting | Effect |
|---|---|
| **Enabled** | This VNet's VPN/ExpressRoute gateway can be used by the peered VNet |
| **Disabled** (default) | Gateway is not shared |

**Where to set:** On the **hub** VNet that has the VPN or ExpressRoute gateway.

### UseRemoteGateways

| Setting | Effect |
|---|---|
| **Enabled** | This VNet uses the gateway in the peered VNet for on-premises connectivity |
| **Disabled** (default) | This VNet does not use the remote gateway |

**Where to set:** On the **spoke** VNets that need to reach on-premises via the hub's gateway.

**Constraint:** Cannot enable if this VNet already has its own gateway.

---

## Hub-spoke gateway transit

The standard hub-spoke pattern for hybrid connectivity:

```
On-premises ──► Hub VNet (VPN/ER Gateway) ◄──peer──► Spoke VNet (no gateway)
```

### Configuration

**Hub → Spoke peering:**
```
AllowVirtualNetworkAccess: Enabled
AllowForwardedTraffic: Enabled
AllowGatewayTransit: Enabled ← share gateway
UseRemoteGateways: Disabled
```

**Spoke → Hub peering:**
```
AllowVirtualNetworkAccess: Enabled
AllowForwardedTraffic: Enabled ← accept forwarded traffic from NVA
AllowGatewayTransit: Disabled
UseRemoteGateways: Enabled ← use hub's gateway
```

### Requirements

- Hub must have a VPN or ExpressRoute gateway deployed **before** enabling `AllowGatewayTransit`
- Spoke cannot have its own gateway if `UseRemoteGateways` is enabled
- Routes from on-premises are automatically propagated to the spoke's effective routes (unless BGP propagation is disabled)

---

## Non-transitivity

VNet peering is **non-transitive**. If VNet A peers with VNet B, and VNet B peers with VNet C:
- A can reach B ✅
- B can reach C ✅
- A **cannot** reach C ❌ (no direct path exists)

```
A ←──peer──► B ←──peer──► C

A → C: ❌ No route exists
```

### Achieving transitivity

| Method | Mechanism |
|---|---|
| **Additional peering** | Peer A directly with C (creates spoke-to-spoke peering) |
| **NVA/Firewall in hub** | A → B (hub with Firewall) → C; requires UDRs on A and C |
| **AVNM connected groups** | Azure Virtual Network Manager creates a connected group; bypasses non-transitivity |
| **Virtual WAN** | Hub router provides automatic transitive routing |

---

## Overlapping address spaces

VNet peering **fails** if the VNets have overlapping CIDR ranges.

| Scenario | Result |
|---|---|
| VNet A: `10.0.0.0/16`, VNet B: `10.0.0.0/16` | ❌ Peering creation fails |
| VNet A: `10.0.0.0/16`, VNet B: `10.0.1.0/24` | ❌ Peering creation fails (B is subset of A) |
| VNet A: `10.0.0.0/16`, VNet B: `10.1.0.0/16` | ✅ Peering succeeds |

### Planning implications

- **Plan address spaces before deployment** — changing VNet CIDRs is disruptive
- **Reserve non-overlapping ranges** for future VNets in your IP address management (IPAM)
- **Use AVNM IPAM** for automated non-overlapping allocation at scale

---

## Azure Virtual Network Manager connected groups

AVNM **connected groups** bypass the non-transitivity limitation of peering.

### How connected groups work

1. Create a network group containing VNets (static or dynamic membership)
2. Create a **mesh connectivity configuration** with the group
3. Deploy the configuration to the region(s)
4. All VNets in the group become directly connected without explicit peering

### Characteristics

| Property | Value |
|---|---|
| Next hop type | `ConnectedGroup` (not `VNetPeering`) |
| Transitivity | **Transitive** within the connected group |
| Hub requirement | None — flat mesh |
| Max VNets per group | 250 (default); 1,000 on request; 5,000 preview [VERIFY] |
| VNets per VNet | Up to 2 connected groups simultaneously [VERIFY] |
| Cross-region | Enable global mesh for cross-region connectivity |

### Overlapping address spaces in connected groups

By default, connected groups **permit** overlapping address spaces. Traffic to overlapping CIDRs is dropped (nondeterministic routing).

To enforce non-overlap: set `ConnectedGroupAddressOverlap: Disallowed` — peering will fail if overlap exists.

---

## Peering vs VPN Gateway connections

| Factor | VNet peering | VPN Gateway VNet-to-VNet |
|---|---|---|
| **Latency** | Sub-millisecond (local); cross-region latency (global) | Higher — IPsec encapsulation overhead |
| **Bandwidth** | VNet/VM limits; no gateway bottleneck | Limited by gateway SKU (e.g., VpnGw1: ~650 Mbps) |
| **Encryption** | None by default; use VNet encryption or app-layer TLS | IPsec — always encrypted |
| **Cost** | Per-GB data transfer | Gateway hourly + per-GB egress |
| **Transitivity** | Non-transitive | Non-transitive (unless BGP enabled) |
| **Use case** | Low-latency, high-bandwidth VNet connectivity | Encrypted connectivity; connectivity to VNets with overlapping CIDRs (with NAT) |

### When to use each

| Scenario | Recommendation |
|---|---|
| Same-region VNet connectivity | **Peering** — lowest latency, lowest cost |
| Cross-region, high bandwidth | **Global peering** — still lower latency than VPN |
| Encryption required (compliance) | **VPN Gateway** or VNet encryption |
| Overlapping address spaces | **VPN Gateway with NAT** or re-architect |
| Transit routing through hub | **Peering + NVA/Firewall** or **Virtual WAN** |

---

## Monitoring peering

### Peering state

| State | Meaning |
|---|---|
| **Initiated** | Peering created on one side only; waiting for reciprocal peering |
| **Connected** | Both sides peered; traffic can flow |
| **Disconnected** | Peering broken; typically due to VNet deletion or address space conflict |

### Metrics and alerts

- **Peering status** — monitor via Azure Resource Graph or Azure Policy
- **Data transfer** — per-peering bytes in/out visible in VNet metrics
- **Effective routes** — verify peering routes appear on VM NICs

### Common issues

| Issue | Cause | Fix |
|---|---|---|
| Peering stuck at "Initiated" | Reciprocal peering not created | Create peering on the other VNet |
| Traffic not flowing | `AllowVirtualNetworkAccess` disabled | Enable on both sides |
| On-premises not reachable from spoke | `UseRemoteGateways` not enabled | Enable on spoke side; verify gateway exists in hub |
| NVA-forwarded traffic dropped | `AllowForwardedTraffic` disabled | Enable on receiving VNet |
| Global peering but Basic LB not reachable | By design — Basic LB not supported over global peering | Upgrade to Standard LB |

---

## Limits

| Limit | Value |
|---|---|
| Peerings per VNet (default) | 500 [VERIFY] |
| Peerings per VNet (with AVNM) | 1,000 [VERIFY] |
| VNets in connected group (default) | 250 [VERIFY] |
| VNets in connected group (on request) | 1,000 [VERIFY] |
| VNets in connected group (preview) | 5,000 [VERIFY] |

---

## Related pages

| Page | Relationship |
|---|---|
| [Virtual Network](../services/virtual-network.md) | Peering overview, address space planning |
| [Hub-Spoke Networking](./hub-spoke-networking.md) | Gateway transit, spoke isolation |
| [Virtual Network Manager](../services/virtual-network-manager.md) | Connected groups, mesh connectivity |
| [VPN Gateway](../services/vpn-gateway.md) | VNet-to-VNet alternative |
| [ExpressRoute](../services/expressroute.md) | Gateway transit for private peering |

---

## Source pages

| Source | Notes |
|---|---|
| [Virtual Network](../services/virtual-network.md) | Peering types, properties, limits |
| [Hub-Spoke Networking](./hub-spoke-networking.md) | Gateway transit config, spoke design |
| [Virtual Network Manager](../services/virtual-network-manager.md) | Connected groups, mesh topology, direct connectivity |