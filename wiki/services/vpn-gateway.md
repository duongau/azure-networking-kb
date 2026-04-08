# Azure VPN Gateway

> **Compiled:** 2025-11-25 | **Source articles:** 107 (16 directly read) | **Status:** current

## What it is

Azure VPN Gateway is a managed virtual network gateway that sends **encrypted traffic** between Azure virtual networks and on-premises locations over the public internet (using IPsec/IKE), or between Azure virtual networks over the Microsoft backbone. It is one of three Azure Hybrid Connectivity services alongside ExpressRoute and Virtual WAN. A single VPN gateway can host multiple connection types (S2S, P2S, VNet-to-VNet) simultaneously, sharing aggregate bandwidth across all tunnels.

---

## Key capabilities

| Capability | Details |
|---|---|
| **Site-to-site (S2S)** | IPsec/IKE VPN tunnel to on-premises VPN device over public internet. IKEv1 and IKEv2 supported. |
| **Point-to-site (P2S)** | Individual client connections via OpenVPN (TLS 1.2/1.3), SSTP (Windows only), or IKEv2. Requires route-based VPN type. |
| **VNet-to-VNet** | IPsec/IKE tunnel between two Azure VPN gateways — same or different regions/subscriptions. |
| **ExpressRoute coexistence** | VPN gateway (type=Vpn) and ExpressRoute gateway (type=ExpressRoute) can coexist on the same VNet. VPN acts as encrypted failover or extends reach to non-ER sites. |
| **BGP dynamic routing** | Optional BGP support (route-based gateways only). Enables automatic prefix updates, multi-tunnel failover, and transit routing across networks. |
| **Active-active mode** | Both gateway VM instances maintain simultaneous S2S tunnels. Higher throughput + zero-interruption failover (vs. 10–15 s for planned, 1–3 min for unplanned in active-standby). Requires route-based VPN + 2× Standard SKU static public IPs. |
| **NAT (SNAT)** | Static and dynamic IngressSNAT/EgressSNAT rules to connect overlapping IP address spaces. Internet breakout and NAT64 are **not** supported. |
| **Custom IPsec/IKE policy** | Per-connection custom cryptographic algorithm selection (IKE DH group, cipher, integrity, PFS). Supported on all Gen1/Gen2 non-Basic SKUs. |
| **Availability Zones** | AZ SKUs (VpnGw1AZ–5AZ) deploy gateway instances across zones for zone-level redundancy. |
| **Customer-controlled maintenance** | Schedule Guest OS and service updates during a preferred maintenance window (GA Nov 2023). |
| **IPv6** | Dual-stack IPv6 support in preview (May 2025). Not supported on Basic SKU. |
| **Always On VPN** | Persistent device and user tunnels for Windows 10+ clients using IKEv2. |

---

## When to use it

| Scenario | Use VPN Gateway |
|---|---|
| Connect on-premises network to Azure over internet | ✅ S2S — cost-effective, encrypted, widely supported |
| Remote workers or small branch offices (few clients) | ✅ P2S — no VPN device needed, per-client auth |
| Azure VNet–to–VNet across regions or subscriptions | ✅ VNet-to-VNet connection (or VNet peering if no gateway features needed) |
| Encrypted failover for ExpressRoute | ✅ ER + VPN coexistence pattern |
| Connect branches not on ExpressRoute to ER-connected hub | ✅ ER + VPN Gateway (mixed connectivity) |
| Overlapping on-premises address spaces | ✅ Use NAT rules (VpnGw2–5 / VpnGw2AZ–5AZ only) |
| Compliance requiring specific crypto algorithms | ✅ Custom IPsec/IKE policy (all non-Basic SKUs) |
| High-availability hybrid connectivity | ✅ Active-active mode + BGP + dual on-premises VPN devices |

---

## When NOT to use it

| Anti-pattern | Better alternative |
|---|---|
| Need >100 S2S tunnels from a single gateway | Use [Virtual WAN](../services/virtual-wan.md) — supports thousands of branch connections |
| VNet-to-VNet in same region, no transit routing needed | Use **VNet Peering** — lower latency, no gateway overhead, free intra-region transfer |
| Private, dedicated, sub-10ms latency to Azure | Use **ExpressRoute** — not over public internet |
| Large-scale remote workforce (thousands of P2S users) | Consider **Azure Virtual WAN** P2S (scales beyond single gateway limits) |
| Basic SKU for production | ❌ Basic is dev-test only: no RADIUS, no IKEv2 for P2S, no IPv6, limited support SLA |
| Policy-based VPN for any new workload | ❌ Policy-based is legacy (1 tunnel only, no P2S, portal creation blocked since Oct 2023) |

---

## SKUs and tiers

### Current SKUs (use these for all new deployments)

| SKU | Generation | Zone redundant | Key use case | Max S2S tunnels | Notes |
|---|---|---|---|---|---|
| **Basic** | Legacy/Gen1 | ❌ | Dev/test only | 10 (route-based), 1 (policy-based) | No RADIUS, no IKEv2 P2S, no IPv6, no active-active, PowerShell/CLI only |
| **VpnGw1 / VpnGw1AZ** | Gen1 / Gen2 [VERIFY] | ✅ (AZ variant) | Entry production | 30 [VERIFY] | P2S: 128 SSTP + 250 IKEv2 connections |
| **VpnGw2 / VpnGw2AZ** | Gen1 / Gen2 [VERIFY] | ✅ (AZ variant) | Mid-range; NAT supported | 30 [VERIFY] | Minimum SKU for NAT |
| **VpnGw3 / VpnGw3AZ** | Gen1 / Gen2 [VERIFY] | ✅ (AZ variant) | Higher throughput | 30 [VERIFY] | — |
| **VpnGw4 / VpnGw4AZ** | Gen2 | ✅ (AZ variant) | Large enterprise | 100 [VERIFY] | — |
| **VpnGw5 / VpnGw5AZ** | Gen2 | ✅ (AZ variant) | Highest performance | 100 [VERIFY] | — |

> ⚠️ **[VERIFY]** Exact per-SKU tunnel counts, P2S connection limits, and aggregate throughput figures (Mbps/Gbps) are defined in the `vpn-gateway-table-gwtype-aggtput-include.md` and `vpn-gateway-table-sku-performance.md` include files which were not directly readable. Consult [About gateway SKUs](../../raw/articles/vpn-gateway/about-gateway-skus.md) and the [Azure pricing page](https://azure.microsoft.com/pricing/details/vpn-gateway) for current values.

**Confirmed from FAQ:** VpnGw1 supports 128 SSTP connections **and** 250 IKEv2 connections (these limits are independent per protocol).

### Legacy SKUs (being retired — do not use for new deployments)

| SKU | Throughput | Max tunnels | Retirement date | Migrates to |
|---|---|---|---|---|
| Standard | 100 Mbps | 10 | March 31, 2026 | VpnGw1AZ |
| High Performance | 200 Mbps | 30 | March 31, 2026 | VpnGw2AZ |

### SKU selection guidance

| Workload type | Recommended SKU |
|---|---|
| Production / critical | Any Gen1 or Gen2 except Basic |
| Dev-test / proof of concept | Basic (PowerShell/CLI only; no portal creation of policy-based post Oct 2023) |
| Need NAT for overlapping address spaces | VpnGw2 or higher |
| Zone-redundant HA | Any AZ SKU (VpnGw1AZ–5AZ) |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Max S2S tunnels per gateway | 100 [VERIFY] | Use Virtual WAN if >100 needed |
| Max S2S tunnels – Basic SKU (route-based) | 10 | — |
| Max S2S tunnels – Basic SKU (policy-based) | 1 | — |
| Gateway subnet minimum size | /29 (Basic only), /27 or larger (all others) | Recommend /27 or larger for future growth; ExpressRoute coexist needs even more space |
| Gateway creation time | 45 minutes or more | Varies by SKU |
| Active-standby failover – planned maintenance | 10–15 seconds | S2S and VNet-to-VNet only; P2S clients must reconnect |
| Active-standby failover – unplanned disruption | 1–3 minutes (worst case) | — |
| P2S connections – VpnGw1 (SSTP) | 128 | Independent from IKEv2 limit |
| P2S connections – VpnGw1 (IKEv2) | 250 | Independent from SSTP limit |
| P2S connections – all SKUs (higher tiers) | [VERIFY] | See include table in about-gateway-skus.md |
| Public IP SKU required | Standard SKU, Static allocation | Basic SKU public IPs retiring end of June 2026 |
| Active-active: public IPs required | 2× Standard SKU static | Same cost as active-standby + 1 additional IP charge |
| VPN gateways per VNet | 1 VPN gateway + 1 ExpressRoute gateway | Each VNet can have at most these two |
| NAT supported SKUs | VpnGw2–5, VpnGw2AZ–5AZ | S2S connections only; not VNet-to-VNet or P2S |
| Dynamic NAT rules per connection | 1 rule per connection | — |
| Max BGP APIPA addresses per active-active instance | Multiple (GA Jan 2022) | Non-APIPA BGP peer IPs must be excluded from NAT range |

> Full subscription-level limits: [Azure VPN Gateway limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-vpn-gateway-limits)

---

## Connection types and topology reference

| Connection type | Gateway type | Protocol | On-premises device needed? | Cross-subscription? |
|---|---|---|---|---|
| Site-to-site (S2S) | Route-based or policy-based | IPsec/IKE (IKEv1 or IKEv2) | ✅ Yes (public IPv4 required) | N/A |
| Point-to-site (P2S) | Route-based only | OpenVPN, SSTP, IKEv2 | ❌ No | N/A |
| VNet-to-VNet | Route-based | IPsec/IKE | ❌ No | ✅ Yes |
| ExpressRoute coexist | Both (separate gateways) | ER (private) + IPsec (encrypted failover) | ✅ Yes (ER circuit) | N/A |

### P2S authentication options

| Auth type | Tunnel protocol | Client |
|---|---|---|
| Certificate (Azure-managed or enterprise CA) | OpenVPN, SSTP, IKEv2 | Native OS client or Azure VPN Client |
| Microsoft Entra ID (Conditional Access, MFA) | OpenVPN only | Azure VPN Client required |
| RADIUS + Active Directory | OpenVPN, SSTP, IKEv2 | Native OS client or Azure VPN Client |

### High availability patterns

| Pattern | Tunnels | Azure HA | On-prem HA | Requirement |
|---|---|---|---|---|
| Active-standby (default) | 1 per on-prem device | ✅ Automatic failover | ❌ | None |
| Active-active | 2 (one per gateway instance) | ✅ No interruption | ❌ | Route-based + 2 public IPs |
| Multiple on-prem devices | N tunnels to N devices | ✅ Active-standby | ✅ | BGP + ECMP required |
| Dual redundancy (max HA) | 4 tunnels (2×2 full mesh) | ✅ Active-active | ✅ Active-active | BGP + ECMP + 2 LNGs + 2 connections |

---

## VPN types

| VPN type | When to use | New gateway creation (portal) | Key constraint |
|---|---|---|---|
| **Route-based** | All production scenarios; required for P2S, BGP, active-active, multi-site | ✅ Supported | — |
| **Policy-based** | Legacy single-tunnel S2S only | ❌ Blocked since Oct 1, 2023 (PowerShell/CLI only) | Max 1 tunnel, no P2S, Basic SKU only |

Cannot convert policy-based → route-based without deleting and recreating the gateway (~60 min; IP address is not retained).

---

## Key components

| Component | Description |
|---|---|
| **Virtual network gateway** | The Azure-managed PaaS resource representing the VPN gateway (2+ VMs in GatewaySubnet). |
| **GatewaySubnet** | Dedicated subnet named exactly `GatewaySubnet`. Must be /29+ (Basic) or /27+ (all others). No other resources allowed in this subnet. |
| **Local network gateway (LNG)** | Azure resource representing the on-premises network and VPN device. Holds device public IP (or FQDN) + address prefixes (or BGP ASN/peer IP). |
| **Connection** | Links a VPN gateway to an LNG (S2S/P2S) or to another VPN gateway (VNet-to-VNet). Types: `IPsec`, `Vnet2Vnet`, `VPNClient`, `ExpressRoute`. |
| **Public IP address** | Standard SKU, Static required. Active-active requires 2. Basic SKU public IPs retiring June 2026. |

---

## Cryptography

### Default IKE/IPsec behavior

Azure applies default IPsec/IKE proposals optimized for broad VPN device interoperability. For compliance or security requirements, custom per-connection policies can override defaults.

### Custom IPsec/IKE policy — supported algorithms

| Parameter | Options (representative, not exhaustive) |
|---|---|
| IKE encryption | AES256, AES192, AES128, DES3, DES, GCM_AES256 |
| IKE integrity / PRF | SHA384, SHA256, SHA1, MD5 |
| DH group | Group2 (1024-bit), Group14 (2048-bit), Group24, ECP256 (Group19), ECP384 (Group20) |
| IPsec encryption | GCM_AES256, AES256, AES192, AES128, DES3, DES, None |
| IPsec integrity | GCM_AES256, SHA256, SHA1, MD5 |
| PFS group | None, Group2, Group14, Group24, ECP256, ECP384 |

> [VERIFY] Full supported algorithm list: [New-AzVpnClientIpsecParameter cmdlet](https://learn.microsoft.com/powershell/module/az.network/new-azvpnclientipsecparameter) and [ipsec-ike-policy-howto.md](../../raw/articles/vpn-gateway/ipsec-ike-policy-howto.md)

### IKEv1 note

IKEv1 is now supported on all SKUs except Basic. VPN gateways using IKEv1 may experience reconnects during Main Mode rekeys.

---

## BGP

- **Optional** feature on route-based gateways.
- Enables dynamic prefix advertisement, automatic failover across multiple tunnels, and transit routing.
- BGP peer IP: Configure on both Azure VPN gateway and on-premises device.
- APIPA addresses (169.254.x.x) supported for BGP peer IPs on active-active gateways (all SKUs, GA since Jan 2022).
- APIPA addresses are **not** supported with NAT.
- For BGP + NAT: exclude BGP peer IPs from NAT address ranges (non-APIPA only).
- Azure VPN Gateway default ASN: 65515 [VERIFY].
- Required for: multiple on-premises VPN device HA, dual-redundancy pattern, transit routing.

---

## NAT on VPN Gateway

- Supported on **VpnGw2–5 and VpnGw2AZ–5AZ** SKUs only.
- S2S cross-premises connections only (not VNet-to-VNet, not P2S).
- Two rule types: **IngressSNAT** (on-prem → VNet) and **EgressSNAT** (VNet → on-prem).
- Two NAT modes: **Static** (fixed 1:1 mapping, bidirectional) and **Dynamic** (NAPT, traffic-flow initiated from Internal Mapping side only — unidirectional).
- Each dynamic NAT rule can be assigned to a single connection only.
- BGP route translation: enable "BGP Route Translation" to auto-convert learned/advertised routes when NAT rules are applied.
- Use case: connect multiple branch offices with identical RFC 1918 address spaces to the same Azure VNet.

---

## Pricing model

| Component | Charge |
|---|---|
| Gateway compute (hourly) | Per SKU, per hour. Active-active is same hourly rate as active-standby. |
| Egress data transfer (to on-premises) | Internet egress rate |
| Egress data transfer (VNet-to-VNet, cross-region) | Based on region pair |
| Egress data transfer (VNet-to-VNet, same region) | Free |
| Additional public IP (active-active) | Standard IP address pricing |

> [VERIFY] Current pricing: [Azure VPN Gateway pricing page](https://azure.microsoft.com/pricing/details/vpn-gateway)

---

## SKU migration and deprecation timeline

| Event | Date | Impact |
|---|---|---|
| Portal creation of policy-based gateways blocked | Oct 1, 2023 | PowerShell/CLI only for policy-based |
| Non-AZ SKUs (VpnGw1–5) — new creations blocked | Nov 1, 2025 | All new gateways must use AZ SKUs |
| Non-AZ SKUs — migration period | Sep 2025 – Sep 2026 | Manual upgrade recommended, no downtime |
| Non-AZ SKUs (VpnGw1–5) retirement | Sep 16, 2026 | Auto-migrated if not manually upgraded |
| Legacy Standard SKU retirement | March 31, 2026 | Auto-migrates to VpnGw1AZ via Basic IP migration |
| Legacy High Performance SKU retirement | March 31, 2026 | Auto-migrates to VpnGw2AZ via Basic IP migration |
| Basic SKU public IP retirement (non-Basic-SKU gateways) | End of June 2026 | Migrate to Standard SKU public IP |
| Classic VPN gateway decommission | Aug 2024–Aug 2025 | Migrate to ARM-based gateway |

---

## Security best practices

| Area | Recommendation |
|---|---|
| Authentication (P2S) | Prefer Microsoft Entra ID (supports Conditional Access + MFA) or certificate-based over RADIUS/password alone |
| Gateway redundancy | Use active-active mode to eliminate single points of failure |
| Crypto policy | Use custom IPsec/IKE policy for compliance environments; prefer AES-256 + SHA-256/384 + Group14/24/ECP |
| VPN type | Always use route-based; policy-based is legacy |
| Admin access | RBAC with least privilege; use Privileged Access Workstations |
| DNS in VNet | Custom DNS must forward to Azure DNS (168.63.129.16) — failure can block Azure from performing gateway maintenance (security risk) |
| DDoS | Enable Azure DDoS Standard on VNets hosting gateway workloads |
| Firewall | Deploy Azure Firewall alongside VPN Gateway for centralized traffic filtering |
| SKUs | Do not use Basic SKU for production; no SLA, no RADIUS, no IKEv2 P2S |

---

## Related services

- [ExpressRoute](../services/expressroute.md) — private, non-internet-routed connectivity to Azure; VPN Gateway can coexist as encrypted failover or extend to non-ER sites
- [Virtual WAN](../services/virtual-wan.md) — use when >100 S2S tunnels needed, or for managed global hub-spoke networking
- [Azure Virtual Network](../services/virtual-network.md) — VPN Gateway is deployed into a VNet's GatewaySubnet
- [Azure Firewall](../services/azure-firewall.md) — recommended alongside VPN Gateway for traffic inspection and filtering
- [NAT Gateway](../services/nat-gateway.md) — outbound SNAT for VMs (different from VPN Gateway NAT, which is for overlapping address spaces on S2S connections)
- [Azure Bastion](../services/bastion.md) — alternative secure remote access method (no VPN client required, browser-based RDP/SSH)

---

## Source articles

| Article | Path |
|---|---|
| What is Azure VPN Gateway? | [vpn-gateway-about-vpngateways.md](../../raw/articles/vpn-gateway/vpn-gateway-about-vpngateways.md) |
| VPN Gateway topology and design | [design.md](../../raw/articles/vpn-gateway/design.md) |
| About gateway SKUs | [about-gateway-skus.md](../../raw/articles/vpn-gateway/about-gateway-skus.md) |
| VPN Gateway configuration settings | [vpn-gateway-about-vpn-gateway-settings.md](../../raw/articles/vpn-gateway/vpn-gateway-about-vpn-gateway-settings.md) |
| About BGP and VPN Gateway | [vpn-gateway-bgp-overview.md](../../raw/articles/vpn-gateway/vpn-gateway-bgp-overview.md) |
| About Point-to-Site VPN | [point-to-site-about.md](../../raw/articles/vpn-gateway/point-to-site-about.md) |
| Design highly available gateway connectivity | [vpn-gateway-highlyavailable.md](../../raw/articles/vpn-gateway/vpn-gateway-highlyavailable.md) |
| About active-active mode VPN gateways | [about-active-active-gateways.md](../../raw/articles/vpn-gateway/about-active-active-gateways.md) |
| About NAT on Azure VPN Gateway | [nat-overview.md](../../raw/articles/vpn-gateway/nat-overview.md) |
| VPN Gateway FAQ | [vpn-gateway-vpn-faq.md](../../raw/articles/vpn-gateway/vpn-gateway-vpn-faq.md) |
| What's new in Azure VPN Gateway? | [whats-new.md](../../raw/articles/vpn-gateway/whats-new.md) |
| VPN Gateway SKU consolidation and migration | [gateway-sku-consolidation.md](../../raw/articles/vpn-gateway/gateway-sku-consolidation.md) |
| Work with VPN Gateway legacy SKUs | [vpn-gateway-about-skus-legacy.md](../../raw/articles/vpn-gateway/vpn-gateway-about-skus-legacy.md) |
| Cryptographic requirements and Azure VPN gateways | [vpn-gateway-about-compliance-crypto.md](../../raw/articles/vpn-gateway/vpn-gateway-about-compliance-crypto.md) |
| About VPN devices and IPsec/IKE parameters | [vpn-gateway-about-vpn-devices.md](../../raw/articles/vpn-gateway/vpn-gateway-about-vpn-devices.md) |
| Secure your VPN Gateway deployment | [secure-vpn-gateway.md](../../raw/articles/vpn-gateway/secure-vpn-gateway.md) |

---

## Gaps and items needing human input

| Gap | Reason | Action |
|---|---|---|
| Per-SKU throughput table (Mbps/Gbps) | Defined in unreadable include files (`vpn-gateway-table-gwtype-aggtput-include.md`, `vpn-gateway-table-sku-performance.md`) | Human: transcribe table from [About gateway SKUs](../../raw/articles/vpn-gateway/about-gateway-skus.md) after rendering includes |
| Per-SKU P2S connection limits (VpnGw2–5) | Same include file dependency | Human: transcribe from rendered SKU table |
| Per-SKU S2S tunnel counts (exact) | Same include file dependency | Human: confirm values (VpnGw1–3 appear to be 30, VpnGw4–5 appear to be 100 — [VERIFY]) |
| Azure default BGP ASN | Not stated in any directly-read article | Human: confirm (believed to be 65515) |
| 91 source articles not directly read | Scope: how-to guides, client config articles, migration guides, monitoring, specific device configs | Low risk for concept accuracy; primarily procedural content |

---

## Index update

The `wiki/index.md` entry for VPN Gateway should be updated to:

```
| VPN Gateway | [vpn-gateway.md](services/vpn-gateway.md) | ✅ current | 2025-11-25 |
```

---

**Done.** Here's the status summary:

| Item | Status |
|---|---|
| Wiki page compiled | ✅ — full page above, all sections populated |
| Articles read | 16 of 107 (remaining 91 are primarily how-to/client-config procedural guides — not needed for concept accuracy) |
| `[VERIFY]` tags | 3 clusters: SKU throughput table, per-SKU tunnel/P2S limits (include file dependency), default BGP ASN |
| `[CONFLICT]` tags | None found — articles are internally consistent |
| Gaps flagged | 4 items in the gaps table above |
| Index update needed | Yes — `wiki/index.md` row for VPN Gateway → `✅ current` / `2025-11-25` |
| Decision log needed | No novel synthesis decisions; standard compile. No Scribe entry warranted. |

**Biggest watch-out:** The SKU performance table is entirely in Azure Docs include files I couldn't render — the `[VERIFY]` tags on throughput/tunnel numbers are genuine. A human should open `about-gateway-skus.md` in a browser and transcribe the rendered table into the `## SKUs and tiers` section before this page goes authoritative.
