# NAT Gateway in Hub-Spoke Topology

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

NAT Gateway provides deterministic, scalable outbound internet connectivity with up to ~1M SNAT ports (16 IPs × 64,512 ports per IP). In hub-spoke topologies it can be deployed in three distinct sub-patterns depending on whether Azure Firewall is present, how much SNAT isolation is needed between workloads, and whether centralized inspection is required. This page covers all three sub-patterns with deployment steps and ASCII diagrams.

> ⚠️ **March 31, 2026:** New VNets default to private subnets — default outbound access is no longer provided. Explicit outbound (NAT Gateway, Azure Firewall, or Standard Load Balancer with outbound rules) is required for internet connectivity.

---

## Sub-pattern A — NAT Gateway on hub (shared SNAT pool for all spokes)

### Use when
- No Azure Firewall in the topology (outbound internet without traffic inspection).
- Multiple spoke VNets need outbound internet; centralized pool of public IPs preferred over per-spoke IPs.
- Deterministic public IPs required for all spokes (partner allowlists, firewall rules at the destination).
- Cost efficiency: one NAT Gateway instance, one set of public IPs shared across all workloads.

### Architecture diagram

```
                     Internet
                        │
                        │ ← SNAT to NAT GW public IPs
                        │
              ┌─────────┴──────────┐
              │   NAT Gateway      │
              │  (hub VNet subnet) │  IPs: pip-natgw-1 … pip-natgw-N
              └─────────┬──────────┘
                        │  NAT GW attached to hub subnet
              ┌─────────┴──────────┐
              │     Hub VNet       │
              │  10.0.0.0/23       │
              │  ┌───────────────┐ │
              │  │ NatGWSubnet   │ │  /26 — hosts NAT GW (no VMs needed)
              │  │ GatewaySubnet │ │  /27 — VPN/ER GW (optional)
              │  └───────────────┘ │
              └─────┬──────────────┘
          VNet peer │         VNet peer
                    │
       ┌────────────┴──────────┬────────────────────┐
       │                       │                    │
┌──────┴────────┐     ┌────────┴──────┐    ┌────────┴──────┐
│  Spoke A      │     │  Spoke B      │    │  Spoke C      │
│  10.1.0.0/16  │     │  10.2.0.0/16  │    │  10.3.0.0/16  │
│               │     │               │    │               │
│  UDR:         │     │  UDR:         │    │  UDR:         │
│  0.0.0.0/0 → │     │  0.0.0.0/0 → │    │  0.0.0.0/0 → │
│  Hub NatGW IP │     │  Hub NatGW IP │    │  Hub NatGW IP │
└───────────────┘     └───────────────┘    └───────────────┘
```

### Deployment steps

**1. Deploy NAT Gateway in hub:**
```
Resource:   NAT Gateway (StandardV2 recommended — zone-redundant, 100 Gbps)
Region:     Same as hub VNet
Public IPs: 1–16 Standard SKU public IPs (or a /28 prefix = 16 IPs)
Idle timeout: 4 minutes (default); increase to 120 min for long-lived TCP connections
```

**2. Attach NAT Gateway to the hub transit subnet:**
- Create a dedicated subnet in the hub VNet (e.g., `NatGWSubnet 10.0.0.192/26`).
- Attach the NAT Gateway to this subnet.
- NAT Gateway does NOT need VMs in its subnet — it acts as the next-hop for routed traffic.

**3. Create route tables on each spoke subnet:**

| Destination | Next hop type | Next hop address |
|---|---|---|
| `0.0.0.0/0` | Virtual appliance | Hub NatGW subnet NIC IP (or hub transit NIC) |

> **Important UDR requirement:** NAT Gateway automatically becomes the default route only for subnets it is *directly attached to*. For spoke VNets that peer into the hub but have their own subnets, a UDR is required to steer outbound traffic from spoke subnets to the hub subnet where NAT GW is attached. Configure the default route to point to an NVA or routing NIC in the hub that forwards to the NAT GW subnet — OR use a different approach: attach NAT Gateway directly to spoke subnets (see Sub-pattern B).

**4. NAT Gateway operational note on UDR interaction:**
- NAT Gateway takes precedence over Load Balancer outbound rules and instance-level public IPs when attached to a subnet.
- It does NOT require a UDR itself — it **is** the default internet route for any subnet it's directly attached to.
- For the hub-shared pattern, routing logic via NVA or Azure Route Server is needed to funnel spoke traffic to the NAT GW subnet first.

### Monitoring

| Metric | Alert threshold | What it means |
|---|---|---|
| `SNAT Connection Count` | > 800K (of 1M) | Approaching pool exhaustion; add more IPs |
| `Dropped Packets` | > 0 for sustained period | SNAT exhaustion or misconfiguration |
| `Datapath Availability` | < 100% | NAT Gateway health degraded |
| `Bytes` | Baseline + 2σ spike | Unexpected egress volume |

---

## Sub-pattern B — NAT Gateway per spoke (isolated SNAT pools)

### Use when
- Workload isolation is required — one spoke's SNAT exhaustion must not affect another spoke.
- Different spokes need different public IP sets (compliance, partner-specific IP allowlists).
- Each workload team manages its own outbound IP identity independently.
- Still no Azure Firewall — outbound without inspection.

### Architecture diagram

```
              Internet
           /      |      \
          /       |       \
  ┌──────┴──┐ ┌───┴───┐ ┌──┴──────┐
  │ NAT GW A│ │NAT GW B│ │NAT GW C │
  │ pip-A   │ │ pip-B  │ │ pip-C   │
  └────┬────┘ └───┬───┘ └────┬────┘
       │          │          │
       │ attached │          │ attached
       ▼          ▼          ▼
┌──────────┐ ┌──────────┐ ┌──────────┐
│ Spoke A  │ │ Spoke B  │ │ Spoke C  │
│10.1.0.0/16│ │10.2.0.0/16│ │10.3.0.0/16│
│ subnets  │ │ subnets  │ │ subnets  │
│ (NAT GW  │ │ (NAT GW  │ │ (NAT GW  │
│ attached)│ │ attached)│ │ attached)│
└──────────┘ └──────────┘ └──────────┘
       │          │          │
       └──────────┴──────────┘
                  │ VNet peering
              ┌───┴───┐
              │  Hub  │
              │VNet   │
              │(GW etc│
              └───────┘
```

### Deployment steps

**1. Deploy one NAT Gateway per spoke VNet:**
- Each in the same region as its spoke VNet.
- Assign dedicated public IPs or prefixes per NAT Gateway.

**2. Attach NAT Gateway to spoke subnets:**
- Associate the NAT Gateway with every subnet in that spoke that needs internet access.
- NAT Gateway automatically becomes the default internet route for attached subnets — **no UDR needed** for internet egress.
- A subnet can only be attached to **one** NAT Gateway.

**3. No UDR needed for internet egress in this pattern:**
- The direct attachment means `0.0.0.0/0 → Internet` traffic is automatically SNATed through the attached NAT Gateway.
- UDRs are only needed if you want spoke-to-spoke traffic routed through a hub NVA (separate concern).

**4. Sizing each NAT Gateway:**

| Expected peak concurrent flows | IPs needed |
|---|---|
| Up to 64,512 | 1 IP |
| Up to 192K | 3 IPs |
| Up to 640K | 10 IPs |
| Up to 1M | 16 IPs (max) |

Scale formula: `Peak concurrent flows × 1.5 safety margin ÷ 64,512 = IPs needed`

### Subnet attachment constraints

NAT Gateway **cannot** attach to:
- `GatewaySubnet` (VPN Gateway subnet)
- Subnets in Azure Virtual WAN hubs
- Subnets delegated to: Azure SQL MI, Container Instances, PostgreSQL/MySQL Flexible Server, Data Factory, Power Platform, Stream Analytics, Web Apps, Container Apps, **DNS Private Resolver** (StandardV2 only)

---

## Sub-pattern C — NAT Gateway on AzureFirewallSubnet (SNAT port scaling for Firewall)

### Use when
- Azure Firewall is already deployed in the hub and handles all spoke internet egress (via UDRs).
- High-scale workloads are exhausting Azure Firewall's SNAT port pool (2,496 ports per public IP per Firewall instance [VERIFY]).
- You need to scale SNAT capacity without adding dozens of public IPs to the Firewall.

### The SNAT port exhaustion problem

| Resource | SNAT ports per public IP | Max with 16 IPs |
|---|---|---|
| Azure Firewall (Standard/Premium) | 2,496 per IP [VERIFY] | ~39,936 total |
| NAT Gateway (on AzureFirewallSubnet) | 64,512 per IP [VERIFY] | ~1,032,192 total |

Attaching NAT Gateway to the `AzureFirewallSubnet` redirects Firewall's outbound SNAT through the NAT Gateway's IP pool instead of the Firewall's own public IPs — dramatically scaling available SNAT ports.

### Architecture diagram

```
                         Internet
                            │
                 ┌──────────┴──────────┐
                 │     NAT Gateway     │ ← attached to AzureFirewallSubnet
                 │ (up to 16 public IPs│   outbound SNAT for ALL spoke traffic
                 │  × 64,512 ports ea) │   exiting through Firewall
                 └──────────┬──────────┘
                            │
                 ┌──────────┴──────────┐
                 │   Azure Firewall    │  AzureFirewallSubnet /26
                 │ (inspection, rules) │  private IP: 10.0.0.4
                 └──────────┬──────────┘
                            │  (UDRs from spokes)
              ┌─────────────┴──────────────┐
              │         Hub VNet           │
              └─────────────────────────────┘
                       /        \
              Spoke A UDR       Spoke B UDR
              0/0 → 10.0.0.4    0/0 → 10.0.0.4
              ┌──────────┐      ┌──────────┐
              │ Spoke A  │      │ Spoke B  │
              └──────────┘      └──────────┘
```

### Deployment steps

**1. Keep existing hub-spoke-with-firewall pattern intact:**
- All spoke subnets already have `0.0.0.0/0 → Firewall private IP` UDRs.
- Firewall handles all inspection and policy enforcement.

**2. Deploy NAT Gateway and attach to `AzureFirewallSubnet`:**
```
NAT Gateway:   StandardV2 (zone-redundant)
Public IPs:    As many as needed (up to 16 per NAT GW)
               Use a /28 prefix for management simplicity
Subnet:        AzureFirewallSubnet (where Azure Firewall is deployed)
```

**3. Verify Firewall SNAT behavior change:**
- After NAT GW attachment, Firewall outbound traffic uses NAT Gateway IPs for SNAT instead of Firewall's own public IPs.
- Firewall's own public IPs remain available for DNAT rules (inbound) and management.
- Monitor: `SNATPortUtilization` metric on NAT Gateway (not on Firewall) is now the port exhaustion indicator.

**4. DDoS consideration:**
> ⚠️ Azure DDoS Protection plans cannot protect public IPs attached to NAT Gateway. If DDoS coverage for outbound/egress IPs is required, use Firewall-owned public IPs for egress and protect those IPs with DDoS Network Protection.

---

## Comparison of sub-patterns

| Dimension | A: NAT GW on hub | B: NAT GW per spoke | C: NAT GW on AzureFirewallSubnet |
|---|---|---|---|
| Firewall required | ❌ No | ❌ No | ✅ Yes |
| Traffic inspection | ❌ No | ❌ No | ✅ Yes (via Firewall) |
| SNAT pool shared | ✅ All spokes share | ❌ Each spoke isolated | ✅ All spokes share (via FW) |
| IP management | One set of IPs | One set per spoke | One set (scales FW SNAT) |
| UDR changes needed | ✅ Yes (route spoke → hub) | ❌ No (direct attachment) | ❌ No (spokes already UDR → FW) |
| Isolation between workloads | ❌ Shared pool | ✅ Fully isolated | ❌ Shared via Firewall |
| Max SNAT ports | ~1M per NAT GW | ~1M per spoke | ~1M via NAT GW on FW subnet |
| IPv6 support | ✅ (StandardV2) | ✅ (StandardV2) | ✅ (StandardV2) |
| Cost | 1 NAT GW + IPs | N NAT GWs + IPs | 1 NAT GW + IPs + Firewall |

---

## Key operational notes

- A subnet can only be associated with **one** NAT Gateway at a time.
- NAT Gateway takes precedence over Load Balancer outbound rules and instance-level public IPs on the same subnet.
- NAT Gateway is **not** supported in Azure Virtual WAN hubs.
- Use **IP prefixes** (/28 = 16 IPs, /29 = 8 IPs) for cleaner management — single resource to manage, same port math.
- Idle TCP timeout: increase beyond the default 4 minutes only for applications with known long-idle connections; longer timeouts consume port slots.
- StandardV2 NAT Gateway is **zone-redundant** — no zone pinning needed; recommended for all new deployments.

---

## Source pages

| Source | Notes |
|---|---|
| [NAT Gateway](../services/nat-gateway.md) | SNAT port math, SKU comparison (StandardV2 vs. Standard), monitoring metrics, subnet constraints, coexistence with Firewall |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | Hub architecture, UDR patterns, peering configuration, routing mechanics |
| [Azure Firewall](../services/azure-firewall.md) | SNAT port limits per public IP, NAT Gateway coexistence on AzureFirewallSubnet |
| [Network Security Design](../concepts/network-security-design.md) | DDoS protection caveat for NAT Gateway public IPs; SNAT exhaustion Zero Trust note |