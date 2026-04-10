# Enterprise-Scale Hub-Spoke with Azure Virtual Network Manager

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

Azure Virtual Network Manager (AVNM) replaces manual hub-spoke management with a centralized, policy-driven control plane. Instead of creating and maintaining peerings, route tables, and NSG rules across dozens or hundreds of VNets, you define a **management scope**, organize VNets into **network groups**, and deploy **connectivity and security configurations** that AVNM applies at scale. This pattern is the recommended approach for enterprises managing 10+ VNets.

---

## Architecture diagram

```
                    ┌─────────────────────────────────────────────────┐
                    │        AZURE VIRTUAL NETWORK MANAGER            │
                    │        (Management Scope: Management Group)     │
                    │                                                 │
                    │  ┌───────────────────────────────────────────┐  │
                    │  │           NETWORK GROUPS                  │  │
                    │  │                                           │  │
                    │  │  ┌─────────────┐  ┌─────────────────────┐ │  │
                    │  │  │ Prod-Spokes │  │ Dev-Spokes          │ │  │
                    │  │  │ (dynamic via│  │ (static membership) │ │  │
                    │  │  │  Azure Pol) │  │                     │ │  │
                    │  │  └─────────────┘  └─────────────────────┘ │  │
                    │  └───────────────────────────────────────────┘  │
                    │                       │                         │
                    │  ┌────────────────────┼───────────────────────┐ │
                    │  │     CONFIGURATIONS │                       │ │
                    │  │                    ▼                       │ │
                    │  │  ┌──────────────────────────────────────┐  │ │
                    │  │  │ CONNECTIVITY CONFIG (Hub-Spoke)      │  │ │
                    │  │  │ - Hub VNet: 10.0.0.0/16             │  │ │
                    │  │  │ - Spoke Groups: Prod-Spokes          │  │ │
                    │  │  │ - Direct Connectivity: enabled       │  │ │
                    │  │  │ - Global Mesh: enabled (cross-region)│  │ │
                    │  │  └──────────────────────────────────────┘  │ │
                    │  │                                            │ │
                    │  │  ┌──────────────────────────────────────┐  │ │
                    │  │  │ SECURITY ADMIN CONFIG                │  │ │
                    │  │  │ - Rule: DENY RDP from Internet       │  │ │
                    │  │  │   (cannot be overridden by NSG)      │  │ │
                    │  │  │ - Rule: ALLOW HTTPS from Internet    │  │ │
                    │  │  └──────────────────────────────────────┘  │ │
                    │  │                                            │ │
                    │  │  ┌──────────────────────────────────────┐  │ │
                    │  │  │ ROUTING CONFIG (UDR Management)      │  │ │
                    │  │  │ - Route: 0.0.0.0/0 → Azure Firewall  │  │ │
                    │  │  │ - Route: RFC1918 → Azure Firewall    │  │ │
                    │  │  └──────────────────────────────────────┘  │ │
                    │  └────────────────────────────────────────────┘ │
                    └──────────────────────┬──────────────────────────┘
                                           │
                          DEPLOYMENT (Commit to regions)
                                           │
              ┌────────────────────────────┼────────────────────────────┐
              │                            │                            │
              ▼                            ▼                            ▼
     ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
     │  HUB VNET       │       │  SPOKE A        │       │  SPOKE B        │
     │  10.0.0.0/16    │       │  10.1.0.0/16    │       │  10.2.0.0/16    │
     │                 │◄─────►│                 │◄─────►│                 │
     │ - Azure FW      │ peer  │ - Prod workload │direct │ - Prod workload │
     │ - VPN/ER GW     │       │ - Tag: env=prod │conn   │ - Tag: env=prod │
     │ - Bastion       │       │                 │group  │                 │
     └─────────────────┘       └─────────────────┘       └─────────────────┘
              │                            │                            │
              │                            ▼                            │
              │                 ┌─────────────────┐                     │
              │                 │  SPOKE C        │                     │
              │                 │  10.3.0.0/16    │◄────────────────────┘
              │                 │  Tag: env=dev   │
              │                 │  (Dev-Spokes)   │
              └─────────────────│                 │
                                └─────────────────┘
```

---

## Why AVNM over manual hub-spoke

| Challenge with manual hub-spoke | AVNM solution |
|---|---|
| Adding a new spoke requires: create VNet, create 2 peering links, add UDRs, update firewall rules, update every other spoke's UDRs | Add VNet to a network group (or tag it for dynamic membership) — AVNM auto-configures peering and connectivity |
| 50+ spoke VNets = 100+ peering links + hundreds of UDR entries = operational nightmare | Connectivity configuration + routing configuration handle all peerings and UDRs declaratively |
| Subscription owners can delete NSG rules that security team mandates | Security admin rules **cannot be overridden** by subscription-level NSGs; central governance enforced |
| Spoke-to-spoke traffic must transit hub (adds latency, firewall cost) | **Direct connectivity** (connected groups) enables spoke-to-spoke without hub transit |
| Cross-region hub-spoke requires double the configuration | Single AVNM instance can manage VNets across multiple regions; global mesh for cross-region |
| IP address management is manual spreadsheets | AVNM **IPAM** feature allocates non-overlapping CIDRs from hierarchical pools automatically |

---

## Core concepts

### Management scope

AVNM operates within a defined **scope**: management groups and/or subscriptions. AVNM can only view and manage VNets within its scope.

| Scope level | Use case |
|---|---|
| **Management group** | Enterprise-wide; single AVNM governs all subscriptions under the MG |
| **Multiple management groups** | Multi-business-unit enterprises with separate governance trees |
| **Subscriptions (explicit)** | Precise control; useful for pilot or when MG hierarchy doesn't match network topology |

**Constraints:**
- You cannot create two network managers with overlapping scope and the same features enabled
- Higher-scope AVNM takes precedence in conflicts
- Limit: customers with **>15,000 subscriptions** cannot apply AVNM policy at root management-group level [VERIFY]

### Network groups

A **network group** is a logical container of VNets. Membership can be:

| Membership type | How it works | Latency |
|---|---|---|
| **Static** | Explicitly select VNets | Immediate |
| **Dynamic (Azure Policy)** | Azure Policy with `addToNetworkGroup` effect; e.g., all VNets with tag `env=prod` | <1,000 subs: minutes; >1,000 subs: up to 24 hours for policy notification, then minutes to apply |

**Cross-tenant:** Only static membership is supported for VNets in other tenants (two-way consent required).

### Connectivity configurations

Two topology types:

| Topology | Mechanism | Use case |
|---|---|---|
| **Hub-spoke** | Peering (VNetPeering/GlobalVNetPeering next-hop) from hub to each spoke in selected network groups | Traditional hub-spoke; central firewall inspection |
| **Mesh** | Connected group (ConnectedGroup next-hop); all VNets in the group directly connected | Direct spoke-to-spoke without hub transit; no central inspection |

**Combined:** Hub-spoke with **direct connectivity** enabled creates hub-to-spoke peering **plus** spoke-to-spoke connected group within the same spoke network group. This allows spoke-to-spoke traffic to bypass the hub while still routing internet traffic through the hub firewall.

### Security admin rules

Security admin rules are evaluated **before** NSGs. They cannot be overridden by subscription owners.

| Action | Behavior |
|---|---|
| **Deny** | Traffic dropped; evaluation stops; NSG never evaluated |
| **Allow** | Traffic permitted to continue to NSG evaluation |
| **Always Allow** | Traffic permitted; evaluation stops; NSG never evaluated |

**Use case:** Central security team creates `Deny SSH/RDP from Internet` rule at priority 100. Subscription owners cannot create NSG rules to override it — the admin rule terminates evaluation before NSG rules are considered.

### Routing configurations (UDR management)

AVNM can manage User-Defined Routes at scale:

| Feature | Detail |
|---|---|
| Route collections | Target a network group; contain route rules |
| Route rules | Destination type + next hop (Virtual appliance, VNet gateway, VNet, Internet) |
| Azure Firewall import | Import Firewall private IP directly in portal |
| UDR limit | 1,000 routes per table (vs. 400 traditional limit) [VERIFY] |
| Modes | `ManagedOnly` (AVNM creates route tables in managed RG) or `UseExisting` (AVNM appends to existing tables) [VERIFY] |

---

## Configuration steps

### Step 1: Create AVNM instance

```
Resource: Network Manager
Scope: Management Group (or subscriptions)
Features: Connectivity, SecurityAdmin, Routing (select all needed)
```

### Step 2: Create network groups

**Dynamic membership example (Azure Policy):**

```json
{
  "mode": "Microsoft.Network.Data",
  "policyRule": {
    "if": {
      "allOf": [
        { "field": "type", "equals": "Microsoft.Network/virtualNetworks" },
        { "field": "tags['env']", "equals": "prod" }
      ]
    },
    "then": {
      "effect": "addToNetworkGroup",
      "details": {
        "networkGroupId": "/subscriptions/.../networkGroups/prod-spokes"
      }
    }
  }
}
```

Assign this policy at the management group level. All VNets with `env=prod` tag are automatically added to `prod-spokes` network group.

### Step 3: Create connectivity configuration

| Setting | Value | Effect |
|---|---|---|
| Topology | Hub and spoke | Hub VNet bidirectionally peered to all spokes |
| Hub VNet | Select hub | Central services VNet |
| Spoke network groups | `prod-spokes` | All VNets in group become spokes |
| Direct connectivity | Enabled | Spoke-to-spoke connected group (bypasses hub for E-W) |
| Global mesh | Enabled | Cross-region spoke-to-spoke without hub transit |
| Use hub as gateway | Enabled | Spokes use hub's VPN/ER gateway |
| Delete existing peerings | Enabled | Remove manually created peerings that conflict |

### Step 4: Create security admin configuration

| Rule | Priority | Direction | Protocol | Source | Destination | Action |
|---|---|---|---|---|---|---|
| Block-SSH-Internet | 100 | Inbound | TCP | Internet | VirtualNetwork | **Deny** |
| Block-RDP-Internet | 110 | Inbound | TCP | Internet | VirtualNetwork | **Deny** |
| Allow-HTTPS-Internet | 200 | Inbound | TCP | Internet | VirtualNetwork | Allow |

These rules apply to **all VNets** in the target network groups. Subscription owners cannot override `Deny` rules.

### Step 5: Create routing configuration

| Route collection | Target | Rule | Destination | Next hop |
|---|---|---|---|---|
| Egress-via-Firewall | prod-spokes | default-route | 0.0.0.0/0 | Azure Firewall (10.0.0.4) |
| Egress-via-Firewall | prod-spokes | rfc1918-10 | 10.0.0.0/8 | Azure Firewall (10.0.0.4) |
| Egress-via-Firewall | prod-spokes | rfc1918-172 | 172.16.0.0/12 | Azure Firewall (10.0.0.4) |
| Egress-via-Firewall | prod-spokes | rfc1918-192 | 192.168.0.0/16 | Azure Firewall (10.0.0.4) |

### Step 6: Deploy configurations

Configurations are **inert until deployed**. Deploy to specific regions:

```
Configuration → Deploy → Select regions (e.g., East US, West Europe)
```

**Goal-state model:** Deploying configs C1+C2 to a region sets them as the desired state. Deploying C1+C3 later removes C2 and adds C3.

**Deployment latency:** ~15–20 minutes after commit.

---

## Coexistence with existing hub-spoke

AVNM can overlay existing manual hub-spoke deployments:

| Existing resource | AVNM behavior |
|---|---|
| Existing VNets | Add to network groups (static or dynamic); AVNM manages without recreating |
| Existing peerings | AVNM can delete conflicting peerings (`deleteExistingPeerings: true`) or coexist |
| Existing NSGs | Security admin rules evaluated **before** NSGs; NSGs remain intact |
| Existing UDRs | `UseExisting` mode appends AVNM routes to existing tables; `ManagedOnly` creates new tables |

**Migration path:**
1. Create AVNM instance with scope covering existing subscriptions
2. Add existing VNets to network groups
3. Create connectivity configuration matching existing topology
4. Deploy incrementally (one region at a time)
5. Validate with Network Verifier before removing manual peerings

---

## Limits reference [VERIFY all]

| Limit | Value |
|---|---|
| Network managers per subscription | 100 [VERIFY] |
| Network groups per network manager | No limit [VERIFY] |
| VNets per connected group (default) | 250 |
| VNets per connected group (on request) | 1,000 |
| VNets per connected group (preview, `AllowHighScaleConnectedGroup`) | 5,000 |
| Connected groups per VNet | 2 (soft limit) [VERIFY] |
| Spokes per hub (connectivity config) | 1,000 [VERIFY] |
| Security admin rules per rule collection | 100 [VERIFY] |
| Rule collections per security config | 100 [VERIFY] |
| Routing rules per route collection | 100 [VERIFY] |
| UDRs per AVNM-managed route table | 1,000 |
| VNets across peered VNets (direct connectivity) | Follow connected group limits |
| Deployment apply latency | ~15–20 minutes |
| Network group membership propagation | Static: immediate; Dynamic (<1K subs): minutes; Dynamic (>1K subs): up to 24 hours |
| Cross-tenant | Static membership only |

---

## Network Verifier (validation before deployment)

AVNM includes **Network Verifier** for static reachability analysis:

| Use case | How to use |
|---|---|
| Validate connectivity config before deployment | Create verifier workspace → run reachability analysis (VM-A to VM-B) → verify path exists |
| Troubleshoot "why can't A reach B" | Verifier evaluates: NSGs, admin rules, peering, route tables, PEs, Azure Firewall (L4 static) |
| Pre-flight check for security admin rules | Run analysis before deploying a `Deny` rule to confirm expected services aren't broken |

**Limitations:**
- Subnet source/destination must have at least one running VM
- Azure Firewall evaluated as L4 static (application rules not evaluated)

---

## Common pitfalls

| Pitfall | Fix |
|---|---|
| Deployment never takes effect | Configs must be **committed and deployed** to specific regions |
| Dynamic membership slow (>24 hr) | Expected for scopes >1,000 subscriptions; use static for urgent additions |
| Security admin rules not applying to certain services | Some services (SQL MI, Databricks, App Gateway, Bastion, Firewall, VPN GW) skip admin rules by default; opt in with `AllowRulesOnly` |
| Connected group address overlap causing drops | Set `ConnectedGroupAddressOverlap: Disallowed` to enforce non-overlap at admission |
| Cross-tenant VNets not appearing | Only static membership supported; verify two-way consent (network manager connection + VNet manager hub connection) |

---

## Related pages

| Page | Relationship |
|---|---|
| [Virtual Network Manager](../services/virtual-network-manager.md) | Full service reference: scope, network groups, connectivity, security admin, routing, IPAM, verifier |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | Manual hub-spoke patterns, UDR sprawl, when to migrate to AVNM |
| [VNet Peering](../concepts/vnet-peering.md) | Peering properties, connected groups, transitivity |
| [User-Defined Routes](../concepts/user-defined-routes.md) | Route precedence, BGP propagation, force-tunneling |
| [Hub-Spoke with Azure Firewall](./hub-spoke-with-firewall.md) | Complementary pattern: how to configure the hub's firewall |

---

## Source pages

| Source | Notes |
|---|---|
| [Virtual Network Manager](../services/virtual-network-manager.md) | Scope, network groups, connectivity configs, security admin, routing configs, IPAM, Network Verifier, limits |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | UDR patterns, peering configuration, comparison to AVNM |
| [VNet Peering](../concepts/vnet-peering.md) | Connected groups, transitivity, overlapping addresses |
