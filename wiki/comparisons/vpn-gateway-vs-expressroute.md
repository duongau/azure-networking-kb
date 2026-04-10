# VPN Gateway vs ExpressRoute

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Both services connect on-premises networks to Azure virtual networks. They differ in path (public internet vs. private fiber), encryption posture, bandwidth ceiling, latency consistency, provisioning time, and cost. This page forces the decision and documents the coexistence pattern.

---

## Side-by-side comparison

| Dimension | VPN Gateway | ExpressRoute |
|---|---|---|
| **Transport path** | Public internet (IPsec/IKE tunnel) | Private dedicated connection via provider or ExpressRoute Direct |
| **Encryption** | ✅ Always encrypted — IPsec/IKE mandatory | ❌ Not encrypted by default — traffic is private but plaintext at L3 |
| **Encryption options** | IPsec/IKE (default); custom cipher policy (all non-Basic SKUs) | MACsec (L2, ExpressRoute Direct only); IPsec over ER private peering (not ErGwScale) |
| **Max bandwidth** | ~10 Gbps (VpnGw5AZ aggregate) [VERIFY] | 50 Mbps – 400 Gbps (ExpressRoute Direct) |
| **Latency** | Variable — internet congestion, packet loss possible | Consistent, predictable — dedicated path, no internet routing |
| **SLA** | 99.9% (active-standby) [VERIFY] | 99.95% [VERIFY] |
| **Setup time** | Hours — gateway creation ~45 min; VPN device config | Weeks — provider circuit provisioning; peering configuration |
| **Cost tier** | $ (gateway hourly + egress) | $$$ (port/circuit fee + gateway hourly + optional premium add-ons) |
| **BGP support** | Optional (route-based only) | Required (AS 12076; 16-bit and 32-bit ASN supported) |
| **Active-active redundancy** | Optional — requires 2 public IPs; eliminates planned failover interruption | Required by best practice — both primary and secondary ER links must be active-active |
| **Failover behavior (active-standby)** | Planned: 10–15 s; Unplanned: 1–3 min | Failure detection: ~3 min BGP hold (reduce to <1 s with BFD) |
| **Max S2S tunnels (single gateway)** | 100 [VERIFY] (VpnGw4/5); 30 (VpnGw1–3); 10 (Basic) | Up to 4 circuits from same peering location; 16 from different locations per VNet |
| **Coexistence** | ✅ Can coexist with ER gateway on same VNet | ✅ Can coexist with VPN gateway on same VNet |
| **VNet-to-VNet** | ✅ Yes — IPsec between Azure VPN gateways | Not recommended — use VNet Peering instead |
| **Multi-site / branch scale** | Up to 100 tunnels per gateway; use Virtual WAN beyond that | Not designed for branch-office-per-circuit scale |
| **On-premises hardware required** | Public IPv4 VPN device (route-based recommended) | Provider cross-connect or ExpressRoute Direct physical port |
| **Microsoft 365 / Azure PaaS public services** | Traffic exits Azure to internet; not via VPN | ✅ Microsoft Peering (Premium add-on required for M365) |
| **ExpressRoute Global Reach** | N/A | ✅ Link two ER circuits for on-prem-to-on-prem private routing |

---

## SKU comparison

### VPN Gateway SKUs

| SKU | Generation | AZ redundant | Max S2S tunnels | Key capability | Retirement note |
|---|---|---|---|---|---|
| **Basic** | Legacy | ❌ | 10 (route), 1 (policy) | Dev/test only; no RADIUS, no IKEv2 P2S, no IPv6 | No portal creation of policy-based since Oct 2023 |
| **VpnGw1AZ** | Gen2 | ✅ | 30 [VERIFY] | Entry production; 128 SSTP + 250 IKEv2 P2S | Required for all new prod (non-AZ blocked Nov 2025) |
| **VpnGw2AZ** | Gen2 | ✅ | 30 [VERIFY] | NAT supported (minimum SKU for overlapping spaces) | — |
| **VpnGw3AZ** | Gen2 | ✅ | 30 [VERIFY] | Higher throughput | — |
| **VpnGw4AZ** | Gen2 | ✅ | 100 [VERIFY] | Large enterprise | — |
| **VpnGw5AZ** | Gen2 | ✅ | 100 [VERIFY] | Highest performance | — |
| **Standard** (legacy) | Legacy | ❌ | 10 | 100 Mbps | **Retiring March 31, 2026** → VpnGw1AZ |
| **High Performance** (legacy) | Legacy | ❌ | 30 | 200 Mbps | **Retiring March 31, 2026** → VpnGw2AZ |

> ⚠️ Non-AZ SKUs (VpnGw1–5 without AZ suffix) blocked for new creation since November 1, 2025. Auto-migrated September 16, 2026 if not manually upgraded.

### ExpressRoute Gateway SKUs

| Gateway SKU | Max ER circuit connections | Max throughput | FastPath support | VPN coexistence |
|---|---|---|---|---|
| **Standard / ERGw1Az** | 4 | [VERIFY — in include file] | ❌ | ✅ |
| **High Performance / ERGw2Az** | 8 | [VERIFY] | ❌ | ✅ |
| **Ultra Performance / ErGw3Az** | 16 | [VERIFY] | ✅ | ✅ |
| **ErGwScale** | 4–16 (scales with SUs) | Up to 40 Gbps (40 SU) | ✅ (≥10 scale units) | ✅ (IPsec over ER not supported) |

### ExpressRoute Circuit SKUs

| Circuit SKU | Regional scope | Billing model | VNets per circuit | Notes |
|---|---|---|---|---|
| **Local** | 1–2 regions near peering location | Data transfer included in port charge [VERIFY] | [VERIFY] | No Global Reach |
| **Standard** | Same geopolitical area | Metered or Unlimited | 10 [VERIFY] | — |
| **Premium** | All Azure regions globally | Metered or Unlimited | Up to 100 [VERIFY] | Required for M365; required for cross-geopolitical Global Reach |

---

## When to use VPN Gateway only

- Budget is the primary constraint — VPN is 10–100× cheaper than ER for equivalent bandwidth
- Connectivity needed quickly — can provision in hours; ER requires weeks of provider coordination
- Bandwidth requirement is <1 Gbps and sustained high-bandwidth workloads are not needed
- You need P2S (remote workforce / small branch) rather than S2S
- Compliance requires encryption in transit — IPsec is always-on vs. ER's unencrypted default
- Temporary / burst connectivity (dev, disaster recovery test, proof-of-concept)
- Connecting many branch offices (hundreds of sites) → consider **Virtual WAN** with S2S VPN

---

## When to use ExpressRoute only

- Consistent, predictable sub-10ms latency is required for production workloads (databases, SAP, trading)
- Bandwidth requirement exceeds 1 Gbps sustained — VPN cannot deliver this reliably
- Regulatory mandate prohibits any public internet path for data (financial services, healthcare, government)
- Large-scale data ingestion to Azure Storage, Cosmos DB — ER Unlimited billing caps transfer costs
- Microsoft 365 requires private path (Premium add-on + Microsoft peering)
- Physical network isolation is a compliance requirement (ExpressRoute Direct provides dedicated ports)

---

## When to use both (coexistence)

The most resilient hybrid architecture uses ExpressRoute as the primary path and a VPN Gateway as an encrypted internet failover:

```
On-premises
    │
    ├── ExpressRoute (primary — private, high-bandwidth, consistent latency)
    │       └── ER VNet Gateway (ERGw2Az or higher)
    │
    └── VPN Gateway S2S (failover — encrypted, internet path)
            └── VPN VNet Gateway (VpnGw1AZ or higher)
            └── BGP preferred path: ER advertises longer prefix or lower MED
                VPN advertises same prefix with AS path prepend (less preferred)
```

**Coexistence routing rule:** Both gateways deploy in the same `GatewaySubnet`. BGP controls path preference. Prefix length and AS path determine which path is primary — do not set both paths as equal-cost unless ECMP is desired.

**Coexistence constraints:**
- Shared `GatewaySubnet` — size `/27` or larger (both gateways share the subnet)
- IPsec over ExpressRoute private peering: requires VPN gateway configured with ER connection type; not supported on ErGwScale
- P2S not supported on the same gateway used for ER coexistence

---

## Decision guide

| Scenario | Recommendation |
|---|---|
| Dev/test, temporary, or budget-constrained | VPN Gateway |
| Production with <1 Gbps sustained bandwidth and encryption required | VPN Gateway |
| Production with >1 Gbps, latency-sensitive, or regulatory isolation | ExpressRoute |
| Need both reliability and encryption in transit | ExpressRoute (primary) + VPN Gateway (failover) |
| Hundreds of branch offices needing VPN | Virtual WAN (manages scale beyond standalone VPN Gateway) |
| Connecting two on-premises datacenters via Microsoft backbone | ExpressRoute Global Reach |
| Bandwidth >10 Gbps | ExpressRoute Direct (10/100/400 Gbps) |
| Rapid provisioning (<24 hours) with moderate bandwidth | VPN Gateway |

---

## Key operational notes

| Topic | VPN Gateway | ExpressRoute |
|---|---|---|
| **Encryption key management** | Azure-managed per IPsec SA | Customer-managed MACsec keys (Direct only); key mismatch = complete outage |
| **BFD (fast failover)** | Supported for S2S (BGP peers) | Critical — reduces detection from ~3 min to <1 s on private peering |
| **Maintenance windows** | Customer-controlled scheduling (GA Nov 2023) | Customer-controlled scheduling (GA 2025); use Resiliency Validation |
| **Monitoring** | Tunnel Bandwidth, BGP peer status, MMSA/QMSA counts | Circuit QoS metrics, Resiliency Insights score (0–100), Traffic Collector |
| **Default outbound access retirement** | March 31, 2026 (VMs in VNets need explicit outbound method) | Not applicable — ER is inbound/egress between on-prem and Azure |

---

## Source pages

| Source | Notes |
|---|---|
| [VPN Gateway](../services/vpn-gateway.md) | SKUs, S2S/P2S/VNet-to-VNet, BGP, NAT, crypto, retirements |
| [ExpressRoute](../services/expressroute.md) | Circuits, peering, gateway SKUs, FastPath, encryption, resiliency |
| [Hybrid Connectivity](../concepts/hybrid-connectivity.md) | Options at-a-glance, BGP mechanics, coexistence patterns |