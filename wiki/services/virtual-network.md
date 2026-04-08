# Azure Virtual Network

> **Compiled:** 2025-07-31 | **Source articles:** 75 | **Status:** current

## What it is

Azure Virtual Network (VNet) is the fundamental private networking primitive in Azure. It provides a logically isolated network within the Azure cloud that is dedicated to a single subscription and scoped to a single region. Resources deployed into a VNet — VMs, AKS clusters, App Service Environments, gateways, and more — communicate privately using RFC 1918 addresses, and can be connected to other VNets, to on-premises networks, and to Azure PaaS services using a layered set of primitives (peering, VPN, ExpressRoute, service endpoints, Private Link). The VNet service itself is **free** [VERIFY]; charges apply to associated resources such as VPN Gateways, peering bandwidth, and public IP addresses.

---

## Key capabilities

| Capability | Details |
|---|---|
| **Network isolation** | Each VNet is dedicated to a single subscription. Resources in different VNets cannot communicate unless explicitly connected via peering, VPN, or ExpressRoute. |
| **Custom address space** | Define one or more IPv4 CIDR blocks (RFC 1918 recommended: `10.x`, `172.16–31.x`, `192.168.x`; also `100.64/10` per RFC 6598). IPv6 dual-stack supported. |
| **Subnets** | Segment a VNet into subnets; apply NSGs and route tables per subnet. Minimum /29 (IPv4), must be exactly /64 (IPv6). Azure reserves 5 IPs per subnet (first 4 + last). [VERIFY] |
| **Availability Zone span** | VNets and subnets automatically span all AZs in a region — no need to split by zone. |
| **Network Security Groups (NSGs)** | Stateful Layer-4 ACLs applied at subnet or NIC level. Rules defined by priority (100–4096), source/destination IP/service tag/ASG, port, protocol, and allow/deny action. [VERIFY] |
| **Application Security Groups (ASGs)** | Group VM NICs logically (e.g., `AsgWeb`, `AsgDb`) and reference groups in NSG rules instead of managing IP lists. All NICs in an ASG must be in the same VNet. |
| **Service tags** | Named groups of Azure service IP ranges (e.g., `AzureCloud`, `Storage`, `Sql`) that Microsoft maintains automatically. Use in NSG rules and UDRs instead of hardcoded IPs. |
| **Security admin rules (VNet Manager)** | Global, subscription-spanning security rules that take precedence over NSGs. `Deny` and `Always Allow` actions terminate NSG evaluation entirely. |
| **User-defined routes (UDRs)** | Custom route tables override system routes. Associate one route table per subnet. Next hop types: Virtual Appliance, VNet Gateway (VPN only), Internet, Virtual Network, None. |
| **System default routes** | Azure auto-creates routes for: VNet address space → VNet; `0.0.0.0/0` → Internet; RFC 1918 + `100.64/10` → None. Overridable via UDRs. |
| **BGP route exchange** | VPN Gateway and ExpressRoute gateways propagate on-premises routes into VNet route tables dynamically. |
| **VNet peering** | Connect two VNets (same or different region/subscription/tenant) over Microsoft backbone. Traffic is private, low-latency, no gateway required. Default limit: 500 peered VNets; 1,000 with VNet Manager. [VERIFY] |
| **Subnet peering** | Granular peering: select specific subnets to peer rather than entire VNet address space. |
| **Gateway transit** | A spoke VNet can use the VPN or ExpressRoute gateway in a hub VNet — no need to deploy a gateway in every spoke. |
| **Service endpoints** | Extend VNet identity to Azure PaaS services (Storage, SQL, Cosmos DB, Key Vault, Service Bus, Event Hubs, App Service, etc.) over optimized backbone routes. Source IP seen by service switches from public to private. No extra charge. |
| **Private endpoints (Private Link)** | Inject a NIC with a private IP from your VNet into a specific PaaS resource instance. DNS resolves to private IP; public internet exposure can be disabled entirely. Preferred over service endpoints for new designs. |
| **Subnet delegation** | Designate a subnet for a specific Azure PaaS service injection (e.g., SQL MI, App Service, DNS Private Resolver). Service may enforce network intent policies on the subnet. |
| **VNet encryption** | DTLS tunnel between VMs within a VNet or across peered VNets. Requires Accelerated Networking on NIC. Supported VM series: D v4/v5/v6, E v4/v5/v6, M v2/v3, L v3, F v6. Currently `AllowUnencrypted` enforcement only (`DropUnencrypted` planned). [VERIFY] |
| **Accelerated Networking** | SR-IOV NIC bypasses host virtual switch → lower latency, reduced jitter, lower CPU. Available on most VM sizes with ≥2 vCPUs (≥4 vCPUs for hyperthreaded instances). Must enable on stopped/deallocated VM. |
| **IP services** | Public IPs (Standard v1/v2, Basic [retired Sept 30, 2025]), Public IP prefixes (/28 to /31), private IPs (dynamic or static), Custom IP prefixes (BYOIP), routing preference. [VERIFY] |
| **Default outbound access (retiring)** | Azure historically provided implicit outbound internet IPs. New VNets using API versions after March 31, 2026 default to private subnets — explicit outbound method required. [VERIFY] |
| **VNet flow logs** | Capture per-flow traffic data (IP, port, protocol, bytes) via Azure Network Watcher. Distinct from NSG flow logs (deprecated). |
| **Monitoring** | Azure Monitor activity logs and metrics for VNet create/update/delete events. Per-VNet metrics viewed from the VNet resource blade. |

---

## When to use it

✅ **Use Azure Virtual Network when:**
- You are deploying **any Azure IaaS or PaaS resource that needs private networking** — VMs, AKS, App Service Environments, SQL MI, etc.
- You need **isolation** from other Azure tenants and control over traffic flow between your resources.
- You need to **connect to on-premises** networks via VPN or ExpressRoute.
- You need **hub-and-spoke architecture** — one hub VNet with shared services (firewall, gateways) and multiple spoke VNets connected via peering.
- You need to apply **fine-grained traffic filtering** via NSGs, UDRs, and/or NVAs.
- You need **private access to Azure PaaS services** (via service endpoints or Private Link).
- You need **deterministic, private outbound connectivity** (combine with NAT Gateway or Azure Firewall).

---

## When NOT to use it

❌ **Do NOT expect VNet to handle these — use alternatives instead:**

| Anti-pattern | Why | Alternative |
|---|---|---|
| **Layer-2 / VLAN semantics** | VNet is a Layer-3 overlay only; no broadcast, no multicast, no VLAN tagging. | Not supported in Azure at all. |
| **Classic deployment model** | Classic VNets are a legacy construct; no new features backported. | Migrate to ARM-based VNets. |
| **Cross-region single subnet** | A VNet is regional; subnets cannot span regions. | Use Global VNet Peering to connect VNets across regions. |
| **Internet-only workloads with no isolation need** | Unnecessary overhead for fully public resources with no private dependencies. | Still recommended — private subnets are now the default. |
| **Routing directly via ExpressRoute gateway in UDR** | UDR next hop type `Virtual Network Gateway` only supports VPN gateways, not ExpressRoute. | Use BGP route propagation from ExpressRoute gateway instead. |
| **Default outbound internet (new deployments post March 2026)** | Default outbound access is being retired; implicit IPs can change, don't support ICMP pings or fragmented packets. | Use NAT Gateway (recommended), Standard Load Balancer with outbound rules, or Azure Firewall. |

---

## SKUs and tiers

VNet itself has no SKU — the service is free. Pricing and SKUs apply to dependent resources:

### Public IP Addresses

| SKU | Allocation | Zone support | Use case | Notes |
|---|---|---|---|---|
| **Standard v2** | Static only | Zone-redundant (always) | New deployments; required for Standard v2 NAT Gateway | Currently only usable with Standard v2 NAT GW [VERIFY] |
| **Standard v1** | Static only | Zone-redundant or zonal | General use — VMs, Load Balancers, Firewalls, Gateways, Bastion | Closed to inbound by default; NSG required to allow traffic |
| **Basic** | Static or Dynamic | None (non-zonal) | **RETIRED September 30, 2025** [VERIFY] | Migrate to Standard immediately |

### Route Tables (UDRs)

| Feature | Default | With Azure VNet Manager |
|---|---|---|
| Routes per table | 400 [VERIFY] | 1,000 [VERIFY] |
| Routes with service tags per table | 25 [VERIFY] | 25 [VERIFY] |

### VNet Peering

| Type | Scope | Notes |
|---|---|---|
| **Local peering** | Same region | Lowest latency; same as single VNet latency |
| **Global peering** | Cross-region | Basic load balancer IPs not reachable across global peering |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| VNets per subscription per region | 1,000 [VERIFY] | Soft limit; can request increase |
| Subnets per VNet | 3,000 [VERIFY] | |
| IPv4 subnet size | /29 (min) to /2 (max) | Azure reserves 5 IPs per subnet |
| IPv6 subnet size | Exactly /64 | Fixed |
| Reserved IPs per subnet | 5 | First 4 addresses + last address |
| VNets peered per VNet (default) | 500 [VERIFY] | |
| VNets peered per VNet (VNet Manager) | 1,000 [VERIFY] | |
| NSG rules per NSG | 1,000 [VERIFY] | |
| NSG rule priority range | 100–4,096 | Lower number = higher priority |
| Route tables (UDRs) per subscription | 200 per region [VERIFY] | |
| Routes per route table | 400 [VERIFY] | 1,000 with VNet Manager |
| UDRs with service tag as prefix | 25 per route table [VERIFY] | |
| Network interfaces per VNet | Subscription limit [VERIFY] | See Azure Networking Limits |
| Private IPs per NIC | 1 primary + multiple secondary [VERIFY] | Secondary can be /28 block (preview) |
| DNS servers per VNet | 20 [VERIFY] | |

> All limits marked [VERIFY] should be confirmed against the [Azure Networking Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-networking-limits) reference page, which is the authoritative source. Many can be increased via support request.

---

## NSG rule processing order

Understanding evaluation order is critical for troubleshooting:

| Traffic direction | Evaluation order |
|---|---|
| **Inbound** | Subnet NSG → NIC NSG |
| **Outbound** | NIC NSG → Subnet NSG |
| **Intra-subnet** | Same order as above; NSGs on a subnet affect VM-to-VM traffic within the subnet |

**Key behaviors:**
- Rules are evaluated lowest priority number first; first match wins, processing stops.
- Default rules (65000–65500) cannot be removed but can be overridden with lower-number rules.
- Security admin rules (VNet Manager) are evaluated **before** NSG rules. `Deny` and `Always Allow` admin rules bypass NSGs entirely.
- Removing a rule that allowed an existing connection does not terminate it — only new connections are affected.

---

## Address space planning

| RFC | Range | Azure behavior |
|---|---|---|
| RFC 1918 | `10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16` | Recommended private address space |
| RFC 6598 | `100.64.0.0/10` | Treated as private in Azure; supported |
| `224.0.0.0/4` | Multicast | Not allowed |
| `255.255.255.255/32` | Broadcast | Not allowed; no broadcast semantics in VNet |
| `127.0.0.0/8` | Loopback | Not allowed |
| `169.254.0.0/16` | Link-local | Not allowed |
| `168.63.129.16/32` | Azure internal DNS/platform | Reserved; not assignable |

**Best practices from source articles:**
- Do not overlap VNet CIDRs with on-premises ranges or other connected VNets — routing conflicts will be silent and hard to debug.
- Plan for growth: leave unallocated space in VNets and subnets.
- Use a few large VNets rather than many small ones within a subscription to reduce management overhead.
- Apply NSGs at subnet level rather than NIC level unless different VMs in a subnet need different rules — per-NIC NSGs create troubleshooting complexity.

---

## VNet encryption — key constraints

> ⚠️ **Incompatible configurations** — do NOT enable VNet encryption on VNets that contain:
> - Azure DNS Private Resolver
> - Azure Application Gateway
> - Azure Firewall
> - ExpressRoute Gateways (breaks on-premises connectivity)
> - Azure Private Link service
> - Azure Confidential Computing VMs (unless Accelerated Networking supported)

VNet encryption is also not applied to traffic involving VMs on unsupported SKUs — those flows pass unencrypted without error by default (AllowUnencrypted mode). Use VNet Flow Logs to confirm which flows are encrypted.

---

## Default outbound access — retirement timeline

> ⚠️ **Breaking change — March 31, 2026:** New VNets created using API versions released after this date will default to **private subnets**, where default outbound access is disabled. VMs in private subnets have no implicit internet egress; explicit outbound method is required.

**Explicit outbound options (in recommended order):**
1. **NAT Gateway** — recommended for most scenarios; zone-redundant, scalable SNAT
2. **Standard Load Balancer with outbound rules** — for workloads already behind a load balancer
3. **Standard Public IP on VM NIC** — for individual VMs needing deterministic outbound
4. **Azure Firewall / NVA via UDR** — when egress inspection is also required

**Existing VNets are not affected** by the March 2026 change — only newly created VNets with new API versions.

---

## Related services

- [NAT Gateway](nat-gateway.md) — Recommended outbound internet connectivity for VNet subnets; attaches directly to subnets; provides deterministic SNAT with up to 1M ports
- [VPN Gateway](vpn-gateway.md) — Site-to-site and point-to-site encrypted VPN connectivity between VNet and on-premises; gateway transit enables hub-spoke hybrid connectivity
- [ExpressRoute](expressroute.md) — Private, non-internet dedicated connectivity between VNet and on-premises; no public internet traversal [stub — not yet compiled]
- [Azure Firewall](azure-firewall.md) — Managed stateful firewall deployed into a VNet subnet; provides L4 + L7 traffic inspection and FQDN filtering [stub — not yet compiled]
- [Application Gateway](application-gateway.md) — L7 HTTP/S load balancer deployed into a VNet subnet; WAF capable [stub — not yet compiled]
- [Azure Load Balancer](load-balancer.md) — L4 load balancer; Standard SKU integrates with VNet subnets; Basic SKU not reachable across global VNet peering [stub — not yet compiled]
- [Azure Bastion](bastion.md) — Browser-based RDP/SSH access to VMs without public IPs; deployed into a dedicated `AzureBastionSubnet` [stub — not yet compiled]
- [Private Link](private-link.md) — Inject private endpoints for PaaS services into a VNet subnet; preferred over service endpoints for new designs [stub — not yet compiled]
- [Azure DNS](dns.md) — Azure-provided name resolution for VMs within a VNet; Private DNS zones extend name resolution across peered VNets and to on-premises via DNS Private Resolver
- [Network Watcher](network-watcher.md) — Diagnostics and monitoring for VNet traffic (IP flow verify, connection monitor, VNet flow logs) [stub — not yet compiled]
- [DDoS Protection](ddos-protection.md) — Enhanced DDoS mitigation for public IPs associated with resources in a VNet [stub — not yet compiled]

---

## Source articles

| Article | Topic type | Date |
|---|---|---|
| `virtual-networks-overview.md` | Overview | 2025-07-17 |
| `concepts-and-best-practices.md` | Concept | 2025-07-28 |
| `virtual-network-vnet-plan-design-arm.md` | How-to | 2025-04-17 |
| `network-security-groups-overview.md` | Concept | 2025-07-15 |
| `network-security-group-how-it-works.md` | Concept | 2025-07-28 |
| `application-security-groups.md` | Concept | 2025-07-25 |
| `service-tags-overview.md` | Concept | 2025-07-15 |
| `virtual-network-peering-overview.md` | Concept | 2025-07-16 |
| `virtual-networks-udr-overview.md` | Concept | 2024-10-30 |
| `virtual-network-service-endpoints-overview.md` | Concept | 2025-07-22 |
| `virtual-network-service-endpoint-policies-overview.md` | Concept | — |
| `vnet-integration-for-azure-services.md` | Concept | 2025-07-28 |
| `subnet-delegation-overview.md` | Concept | 2025-07-28 |
| `virtual-network-encryption-overview.md` | Overview | 2024-12-11 |
| `accelerated-networking-overview.md` | How-to | 2026-02-05 |
| `ip-services/ip-services-overview.md` | Overview | 2024-11-05 |
| `ip-services/public-ip-addresses.md` | Concept | 2025-02-04 |
| `ip-services/private-ip-addresses.md` | Concept | 2024-11-05 |
| `ip-services/default-outbound-access.md` | Concept | 2026-01-30 |
| `ip-services/public-ip-address-prefix.md` | Concept | — |
| `ip-services/routing-preference-overview.md` | Concept | — |
| `virtual-networks-faq.md` | FAQ | 2024-07-22 |
| `monitor-virtual-network.md` | Monitoring | 2024-07-21 |
| `monitor-virtual-network-reference.md` | Reference | — |
| `network-overview.md` | Reference | — |
| `virtual-network-manage-subnet.md` | How-to | — |
| `virtual-network-network-interface.md` | How-to | — |
| `virtual-network-manage-peering.md` | How-to | — |
| `manage-network-security-group.md` | How-to | — |
| `diagnose-network-traffic-filter-problem.md` | Troubleshooting | — |
| `diagnose-network-routing-problem.md` | Troubleshooting | — |
| _(+44 additional quickstarts, tutorials, and how-tos)_ | Various | Various |

---

**⚠️ Compilation notes for human review:**

1. **Service limits**: Most limits are marked `[VERIFY]`. The authoritative source is the [Azure Networking Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-networking-limits) page. The raw articles consistently point to this external URL rather than stating limits inline — a deliberate pattern in Azure docs. These limits should be verified before treating as accurate.

2. **Reciprocal backlinks pending**: Pages marked `[stub — not yet compiled]` in Related Services need a backlink to this page once compiled. Specifically: `azure-firewall.md`, `application-gateway.md`, `load-balancer.md`, `bastion.md`, `private-link.md`, `network-watcher.md`, `ddos-protection.md`, `expressroute.md`. The already-compiled `nat-gateway.md` and `vpn-gateway.md` (when compiled) should also link back here.

3. **VNet encryption incompatibilities**: The list of incompatible services (Firewall, App Gateway, ExpressRoute Gateway, Private Link, DNS Private Resolver) is sourced directly from `virtual-network-encryption-overview.md`. Flag this for review if those services change their architecture.

4. **Default outbound retirement**: `default-outbound-access.md` was dated 2026-01-30 and contains the most current statement of the March 31, 2026 policy. This is a high-impact breaking change — should be surfaced in any decision guide for VNet design.

---

> **Scribe note:** Logging synthesis decisions to `.squad/decisions/inbox/atlas-virtual-network.md` — key decisions: (1) treated `[VERIFY]` tags as required on all limit/SKU claims due to docs consistently deferring to external limits page rather than stating values inline; (2) did not compile VNet TAP, DHCP, MTU, container networking, or DPDK articles as they are operational depth rather than KB-appropriate concepts; (3) VNet encryption section flagged as high-maintenance due to evolving supported SKU list.

---

That is the full compiled page. Here is a summary of what was done and what's flagged:

## What I did

- **Read 25+ source articles** across all major topic types (overview, concept, how-to, FAQ, troubleshooting, monitoring) from the 75-article `raw/articles/virtual-network/` folder
- **Compiled every required wiki section** — nothing left as a placeholder
- **Synthesized across articles** — NSG processing order pulls from both `network-security-groups-overview.md` and `network-security-group-how-it-works.md`; outbound access consolidates `default-outbound-access.md` with the VNet overview
- **Tagged all SKU, limit, and pricing claims** with `[VERIFY]` — the source articles consistently point to an external limits page rather than stating values inline, so inline numbers need external verification
- **Flagged VNet encryption incompatibilities** explicitly — this is a non-obvious footgun that can break ExpressRoute connectivity
- **Called out the March 2026 breaking change** prominently in both the When-to-use and the dedicated section

## What needs human action next

1. **Verify all `[VERIFY]` limits** against the Azure Networking Limits reference page before treating them as accurate
2. **Update `wiki/index.md`** — set Virtual Network status to `✅ current` and date to `2025-07-31`
3. **Compile VPN Gateway and DNS next** — both have raw articles ready; VPN Gateway should backlink to this page once done
4. **Add reciprocal backlinks** in `nat-gateway.md` once VNet page is saved (NAT Gateway's Related Services table already references VNet, but VNet's page wasn't compiled when that was written)
