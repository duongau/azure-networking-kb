# ExpressRoute Resiliency Patterns

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

ExpressRoute does not encrypt traffic by default and does not traverse the public internet — but that does not make it automatically resilient. A single circuit with active-passive configuration is one link failure away from a complete outage. This page covers four design patterns that Microsoft recommends for production workloads, plus the Resiliency Insights scoring framework and the circuit migration procedure for moving production traffic with minimal disruption.

---

## Resiliency pattern overview

| Pattern | Protection against | Resiliency score contribution | Complexity |
|---|---|---|---|
| **1. Dual circuits, different providers/locations** | Site outage, provider outage, complete circuit failure | Up to 20% route score × up to ×4 validation multiplier | Medium |
| **2. ER + VPN Gateway failover (coexistence)** | Circuit failure; encrypted backup path over internet | Route score depends on circuit count; VPN adds encrypted fallback | Medium |
| **3. ExpressRoute Metro** | Single-location outage within a city; simpler than dual circuits | 10% route score (vs. 20% for dual distinct locations) | Low |
| **4. Zone-redundant gateway (ErGw\*Az)** | Availability zone failure in the gateway region | Up to 10% zone redundancy score | Low |

> All four patterns are complementary — the highest overall Resiliency Insights score requires implementing all of them simultaneously.

---

## Pattern 1 — Dual circuits from different providers / peering locations

### What it protects against

A single ExpressRoute circuit — even with its built-in primary + secondary MSEE links — can fail entirely if:
- The provider's equipment at that peering location fails.
- The physical facility has a power or connectivity outage.
- The provider's network has a regional event.

Two circuits at two geographically distinct peering locations ensure that no single provider or facility failure takes down your hybrid connectivity.

### Architecture diagram

```
On-premises primary DC             On-premises secondary DC
         │                                    │
         │  (via Provider A or Direct)        │  (via Provider B or Direct)
         ▼                                    ▼
 ER Peering Location 1              ER Peering Location 2
  e.g., Equinix NY5                  e.g., CoreSite VA3
         │                                    │
         │  Circuit A                         │  Circuit B
         │  (primary + secondary MSEE links)  │  (primary + secondary MSEE links)
         ▼                                    ▼
         └──────────────┬─────────────────────┘
                        │
               ExpressRoute VNet Gateway
               (ErGw*Az — zone-redundant)
                        │
               ┌────────┴────────┐
               │   Azure VNet    │
               │  Hub + Spokes   │
               └─────────────────┘
```

### Active-active vs. active-passive

| Mode | Behavior | Recommendation |
|---|---|---|
| **Active-active** (recommended) | Both circuits carry traffic simultaneously; ECMP load balancing across up to 4 circuits | ✅ Always use — passive path may carry stale routes under Microsoft maintenance prepend events |
| **Active-passive** | One circuit preferred; other on standby | ❌ Avoid — passive path can fail to carry traffic when needed; harder to test |

**Microsoft's maintenance behavior with active-passive:** Microsoft uses AS path prepending to drain traffic to the healthy link during maintenance windows. If you've configured active-passive with your own prepend, ensure the passive path can handle full traffic when Microsoft drains to it — this is a common HA gap.

### BGP configuration for active-active

Each circuit should carry the **same route advertisements** (same prefixes, no prepending that makes one less preferred unless intentional). Azure VNet Gateway uses ECMP to distribute outbound flows across both circuits.

```
Circuit A BGP:
  Azure advertises: 10.0.0.0/16 (VNet space)
  On-prem advertises: 192.168.0.0/16
  AS path: <on-prem-ASN> 12076

Circuit B BGP (same configuration):
  Azure advertises: 10.0.0.0/16
  On-prem advertises: 192.168.0.0/16
  AS path: <on-prem-ASN> 12076
```

### BGP weight / AS path prepending for active/passive preference

To make Circuit A preferred while keeping Circuit B as warm standby (without sacrificing testability):

**On-premises router — inbound from Azure (prefer Circuit A):**
```
# On CE router receiving Azure routes via Circuit A
route-policy PREFER_CIRCUIT_A in
  set local-preference 200        ← higher = more preferred

# On CE router receiving Azure routes via Circuit B
route-policy CIRCUIT_B_STANDBY in
  set local-preference 100        ← lower = less preferred
```

**From Azure toward on-premises (prefer Circuit A for inbound Azure traffic):**
```
# Advertise on-premises via Circuit B with AS path prepend
# (longer AS path = less preferred by Azure)
route-policy CIRCUIT_B_PREPEND out
  prepend-as <on-prem-ASN> 3 times   ← makes Circuit B less preferred from Azure
```

> After ER circuit recovery, traffic may not auto-revert. Test failback explicitly — BGP reconvergence can take 30–90 seconds after BFD detects recovery.

### BFD configuration (mandatory for fast failover)

Without BFD: ER failure detection = ~3 minutes (BGP hold timer 180 s)
With BFD: ER failure detection = **<1 second**

Configure BFD on your Customer Edge (CE) router on both primary and secondary links of both circuits. Microsoft already supports BFD on all MSEE routers.

```
# Cisco IOS-XR example on CE router
interface GigabitEthernetX/Y.100
  bfd interval 300 min_rx 300 multiplier 3
  
router bgp <ASN>
  neighbor <MSEE-IP>
    bfd fast-detect
```

---

## Pattern 2 — ER + VPN Gateway failover coexistence

### Use when

- ExpressRoute is the primary path for latency-sensitive, high-bandwidth production traffic.
- You need an **encrypted fallback** path for disaster scenarios where the ER circuit (or both ER circuits) are down.
- VPN over internet provides acceptable latency and bandwidth for the DR scenario.
- Compliance requires encryption — IPsec over VPN provides L3 encryption that ER alone does not.

### Architecture diagram

```
On-premises                                    Azure Hub VNet
  ┌──────────┐                             GatewaySubnet (/26 recommended)
  │ CE Router│──── ExpressRoute ──────────► ┌────────────────────────────┐
  │ (BGP)    │     (primary path)           │  ER Gateway (ErGw*Az)      │
  │          │     preferred via            │  type: ExpressRoute        │ ──► Hub VNet
  │          │     local-pref / no prepend  │  BGP: routes from ER       │     Spoke VNets
  │          │                             └────────────────────────────┘
  │          │──── IPsec over internet ───► ┌────────────────────────────┐
  │ (BGP)    │     (failover path)          │  VPN Gateway (VpnGw*AZ)   │
  └──────────┘     less preferred via       │  type: Vpn                 │
                   AS path prepend          │  BGP: same prefixes,       │
                   on VPN routes            │  longer AS path            │
                                           └────────────────────────────┘
                                                        │
                                             Both in same GatewaySubnet
                                             Share VNet routing table
```

### Deployment steps

**1. GatewaySubnet sizing:**
- Minimum /27 for either gateway alone.
- **Plan /26 or larger when both gateways coexist** — more IP addresses are consumed.

**2. Deploy ER Gateway:**
```
Gateway type: ExpressRoute
SKU: ErGw1Az / ErGw2Az / ErGw3Az / ErGwScale (zone-redundant)
Recommendation: ErGwScale (autoscales 1–40 SUs; FastPath at ≥10 SUs)
```

**3. Deploy VPN Gateway (same VNet, same GatewaySubnet):**
```
Gateway type: Vpn
VPN type: Route-based (required for BGP + active-active)
SKU: VpnGw1AZ or higher (zone-redundant; non-AZ SKUs blocked from Nov 2025)
Mode: Active-active (requires 2 public IPs + BGP)
BGP: ✅ Enabled — required for coexistence failover routing
```

**4. BGP configuration for ER-preferred / VPN-standby:**

The key: make VPN-advertised routes less preferred than ER-advertised routes at both the on-premises and Azure levels.

```
On on-premises CE router:

  # Routes received via ER circuit (prefer these)
  set local-preference 200 for ER BGP sessions

  # Routes received via VPN tunnel (standby)
  set local-preference 100 for VPN BGP sessions

  # Advertise on-premises prefix via VPN with AS path prepend
  # (Azure will prefer ER-learned routes with shorter AS path)
  prepend-as <on-prem-ASN> 3 times on VPN BGP outbound
```

**5. Verify failover with BFD:**
- Enable BFD on ER private peering (CE router side).
- BFD reduces failure detection from ~3 min → <1 second.
- When ER fails, BGP reconverges to VPN path within seconds.

**6. Failback behavior — test explicitly:**

> ⚠️ When ER recovers, traffic does **not necessarily switch back automatically**. Route Server defaults to preferring ER, but BGP reconvergence takes time and is not guaranteed to self-heal without verification. Explicitly test failback during a maintenance window.

### ER + VPN coexistence cost model

| Component | When billed |
|---|---|
| ER Gateway (hourly compute) | Always — even when ER is healthy |
| VPN Gateway (hourly compute) | Always — even when idle on standby |
| VPN data egress | Only when traffic uses the VPN path (internet egress rates) |
| ER data charges | Depends on circuit billing: Unlimited = flat; Metered = per-GB |

---

## Pattern 3 — ExpressRoute Metro (dual-location within a city)

### What it is

ExpressRoute Metro creates a **single circuit** with two physical link sets at **two distinct peering locations within the same metropolitan area**. This provides physical site diversity without the cost and complexity of two independent circuits from two providers.

### Architecture diagram

```
On-premises                          Metro Location 1
  ┌──────────┐                       e.g., Equinix NY5
  │   CE     │──── Physical Link ──► ┌─────────────┐
  │  Router  │                       │   MSEE-A    │
  │          │                       └──────┬──────┘
  │          │                              │  Same ER circuit
  │          │                       ┌──────┴──────┐
  │          │──── Physical Link ──► │   MSEE-B    │
  └──────────┘                       └─────────────┘
                                     Metro Location 2
                                     e.g., 165 Halsey Street
                                     (New York Metro example)
                                            │
                                   ER VNet Gateway
                                            │
                                       Azure VNet
```

### Key properties

| Property | Value |
|---|---|
| Circuit count | 1 (single circuit object, two physical link sets) |
| Site diversity | ✅ Two distinct facilities in same city |
| Provider diversity | ❌ Same provider/cross-connect (not dual-provider) |
| Resiliency score contribution | 10% (vs. 20% for dual circuits at distinct locations) |
| Resiliency Validation support | ❌ Not supported — Metro circuits cannot be used with Resiliency Validation testing |
| Available locations | 21 metro locations [VERIFY for latest list] |

### When Metro is the right choice vs. dual circuits

| Criterion | Metro | Dual circuits |
|---|---|---|
| Need dual-provider diversity | ❌ Not provided | ✅ Yes |
| Want simpler management (one circuit) | ✅ One circuit object | ❌ Two circuits |
| Need maximum Resiliency Insights score | ❌ 10% route score (half of maximum) | ✅ 20% route score |
| Need Resiliency Validation simulation testing | ❌ Not supported | ✅ Supported |
| Budget-constrained but need site diversity | ✅ Lower cost than two circuits | ❌ Higher cost |
| Physical facility outage in same city possible | ⚠️ Both links in same metro area | ✅ Fully separate locations |

### Selected Metro locations (as of 2026-04-07)

| Metro | Sites | Local Azure Region | ER Direct |
|---|---|---|---|
| New York Metro | Equinix NY5 / 165 Halsey Street | — | ✅ |
| Washington DC Metro | Equinix DC6 / CoreSite VA3 | East US / East US 2 | ✅ |
| Chicago Metro | Equinix CH1 / CoreSite CH1 | North Central US | ✅ |
| London Metro | Telehouse North / Telehouse North2 | UK South | ✅ |
| Amsterdam Metro | Equinix AM5 / Digital Realty AMS8 | West Europe | ✅ |
| Frankfurt Metro | Digital Realty FRA11 / Equinix FR7 | Germany West Central | ✅ |
| Dublin Metro | Equinix DB3 / Digital Realty DUB02 | North Europe | ✅ |
| Singapore Metro | Global Switch Tai Seng / Equinix SG1 | Southeast Asia | ✅ |
| Toronto Metro | Cologix TOR1 / Allied King West | Canada Central | ✅ |
| _(+12 more — see expressroute.md for full list)_ | | | |

---

## Pattern 4 — ER Resiliency Insights + Resiliency Validation

### Resiliency Insights — what it measures

Resiliency Insights is a portal feature on the **ExpressRoute VNet Gateway** that computes a 0–100 resiliency score. It answers: *"How resilient is this gateway's ExpressRoute connectivity right now?"*

**Score formula:**

```
Final score = (Route score × Validation multiplier) + Zone redundancy score + Advisor score
```

| Factor | Max contribution | How to maximize |
|---|---|---|
| **Route resiliency** | 20% | Deploy dual circuits in **distinct peering locations** (20%); Metro = 10%; Single site = 5%; 0 if MSEE-PE link failure present |
| **Zone-redundant gateway** | 10% | Use ErGw\*Az (zone-redundant): 10%; ErGwScale >4 SU: 10%; zonal-only: 8%; Standard/HP/Ultra: 0–2% |
| **Advisor recommendations** | 10% | Resolve all outstanding Azure Advisor recommendations for this gateway |
| **Validation multiplier** | ×1 to ×4 | Run Resiliency Validation within the last 30 days: ×4; 31–60 days: ×3; 61–90 days: ×2; >90 days: ×1 |

**Maximum achievable score:** 
```
(20% × 4) + 10% + 10% = 100
```

This requires: dual circuits at distinct locations + Resiliency Validation run within 30 days + zone-redundant gateway + no Advisor issues.

**Access:** ExpressRoute VNet gateway → Monitoring → Resiliency. Refreshes automatically every hour. Requires Contributor authorization on the gateway.

---

### Resiliency Validation — circuit failover simulation

Resiliency Validation temporarily disconnects the gateway from one ER circuit to prove that traffic fails over to the redundant circuit — without touching production infrastructure.

**Prerequisites:**

| Requirement | Notes |
|---|---|
| ≥2 circuits in **distinct peering locations** | Metro circuits: ❌ not supported |
| Virtual WAN ER gateway | ❌ Not supported — use dedicated VNet gateway |
| Contributor authorization | On the ExpressRoute VNet gateway resource |

**How to run:**

1. Navigate to: ExpressRoute VNet gateway → Monitoring → Resiliency → **Validate Resiliency**
2. Select the target circuit to simulate failure on.
3. Portal initiates disconnection → monitors failover → displays status.
4. **Test runs indefinitely** until you click Stop.
5. Confirm success/failure when stopping — this updates the Validation multiplier.

**What happens during validation:**

```
Normal state:    Gateway ←──── Circuit A (primary)
                 Gateway ←──── Circuit B (standby)
                 
Validation:      Gateway  ✗✗✗  Circuit A (simulated down)
                 Gateway ←──── Circuit B (now carrying all traffic)
                 
Result:          Failover completes in ~15 seconds typically
                 TCP connections: iPerf tests show no packet loss
                 BGP reconvergence: brief event may occur in real outages
```

**FastPath behavior during validation:** FastPath routes are automatically withdrawn from the affected circuit; the failover circuit maintains FastPath connectivity.

**Manual failover alternative** (when automated Resiliency Validation can't be used):
1. Navigate to: ER circuit → Peerings → Azure private peering.
2. Deselect "Enable IPv4 Peering" (or IPv6) to disable BGP peering on that circuit.
3. Observe traffic failover to the redundant circuit.
4. Re-enable after validation is complete.

---

## Circuit migration without downtime

When migrating production traffic from an old circuit to a new circuit (provider change, bandwidth upgrade, Direct migration), use the 5-step controlled migration:

### Step 1 — Deploy new circuit in isolation

```
- Provision new ER circuit (new provider or bandwidth tier)
- Connect to a TEST-ONLY VNet gateway (not production)
- Validate BGP sessions, prefix advertisements, and latency
- Do NOT connect to production VNet gateway yet
```

### Step 2 — Block production traffic on new circuit

Use BGP route policy on your CE router to prevent the new circuit from carrying production traffic during validation:

```
# Cisco IOS-XR: block all prefixes from being advertised to new circuit MSEE
route-policy BLOCK_NEW_CIRCUIT
  drop
end-policy

router bgp <ASN>
  neighbor <new-circuit-MSEE-IP>
    address-family ipv4 unicast
      route-policy BLOCK_NEW_CIRCUIT out

# Juniper: use empty export policy
set routing-options policy-options policy-statement BLOCK_NEW_CIRCUIT term 1 then reject
```

### Step 3 — Connect new circuit to production VNet gateway + validate

```
- Create Connection: new circuit → production VNet gateway
- BGP sessions establish but on-premises prefixes are NOT advertised (blocked by policy)
- Azure VNet routes ARE received from the new circuit (visible in gateway BGP table)
- Validate: new circuit shows connected; Azure prefixes visible on CE router
```

### Step 4 — Switch production traffic to new circuit

```
# Remove the block — allow advertising on-premises prefixes via new circuit
Remove or update BLOCK_NEW_CIRCUIT route-policy

# Make old circuit less preferred (AS path prepend)
route-policy OLD_CIRCUIT_PREPEND out
  prepend-as <ASN> 5 times

# Azure now prefers new circuit (shorter AS path) for sending traffic on-prem
# On-premises router now receives Azure prefixes via both circuits
# Adjust local-preference to prefer new circuit for Azure-bound traffic
```

### Step 5 — Decommission old circuit

```
- Monitor for 24–72 hours (capture any traffic still using old circuit)
- Once confirmed: zero flows via old circuit
- Disconnect old circuit from VNet gateway (delete Connection object)
- Deprovision old circuit with provider
- Delete old circuit resource in Azure
```

> This process applies to L2 provider circuits and ExpressRoute Direct circuits. Provider-managed L3 circuits may have a different provider-side migration process.

---

## Resiliency design checklist

| Check | Pattern | Priority |
|---|---|---|
| Two ER circuits at geographically distinct peering locations | Pattern 1 | 🔴 High |
| Both circuits in active-active mode (no BGP prepend making one passive) | Pattern 1 | 🔴 High |
| BFD enabled on private peering (CE router side) | Patterns 1 & 2 | 🔴 High |
| Zone-redundant ER gateway (ErGw\*Az SKU) | Pattern 4 | 🟡 Medium |
| Resiliency Validation run within last 30 days | Pattern 4 | 🟡 Medium |
| VPN Gateway deployed as encrypted fallback | Pattern 2 | 🟡 Medium (regulated workloads) |
| BGP AS path prepend configured for active/passive preference when required | Patterns 1 & 2 | 🟡 Medium |
| Explicit failback testing documented and scheduled | All patterns | 🟡 Medium |
| Customer-controlled maintenance windows scheduled | All patterns | 🟢 Low |
| No outstanding Azure Advisor recommendations on ER gateway | Pattern 4 | 🟢 Low |

---

## Service limits reference

| Limit | Value | Notes |
|---|---|---|
| ER circuits per subscription | 50 (default) | Increasable [VERIFY] |
| Circuits linkable to same VNet (same peering location) | 4 | ECMP across all 4 |
| Circuits linkable to same VNet (different peering locations) | 16 | ECMP only across 4; rest are failover |
| BGP hold time (Microsoft fixed) | 180 seconds | Cannot change Microsoft side |
| BFD detection time (with BFD) | <1 second | Vs. ~3 min without BFD |
| Resiliency Validation failover time | ~15 seconds typical | |
| Resiliency score refresh interval | Every 1 hour | Automatic |
| Maximum Resiliency Insights score | 100 | Dual circuits + validation in 30d + ZR GW + no Advisor issues |

---

## Source pages

| Source | Notes |
|---|---|
| [ExpressRoute](../services/expressroute.md) | HA patterns, Metro locations, Resiliency Insights score formula, Resiliency Validation steps, circuit migration, BFD, MACsec, FastPath |
| [VPN Gateway](../services/vpn-gateway.md) | ER+VPN coexistence configuration, GatewaySubnet sizing, active-active mode, BGP over VPN, failover timing |
| [Hybrid Connectivity](../concepts/hybrid-connectivity.md) | BGP hold timers, AS path prepending, BFD details, ER+VPN coexistence pattern, Route Server branch-to-branch |