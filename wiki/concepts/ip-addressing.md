# IP Addressing in Azure

> **Compiled:** 2025-07-31 | **Type:** Concept | **Status:** ✅ current

This page synthesises IP addressing concepts across Azure Virtual Network, NAT Gateway, Load Balancer, and DNS. Read this before designing any VNet, before deploying outbound connectivity, and before sizing subnets.

---

## Public vs private IP addresses

Azure networking operates on a strict public/private boundary:

| Dimension | Private IP | Public IP |
|---|---|---|
| **Address space** | RFC 1918 (`10.0.0.0/8`, `172.16.0.0/12`, `192.168.0.0/16`) and RFC 6598 (`100.64.0.0/10`) | Globally routable addresses allocated from Azure's pool (or BYOIP / Custom IP Prefix) |
| **Scope** | VNet-internal; never leaves Microsoft backbone | Internet-reachable; assigned to a resource or floated on a Load Balancer frontend |
| **Assigned to** | VM NICs, internal Load Balancer frontends, Private Endpoints, service-injected PaaS NICs | VM NICs (instance-level), Public Load Balancer frontends, NAT Gateway, Application Gateway, Firewall, Bastion |
| **Allocation — dynamic** | Assigned by Azure DHCP on NIC attach; may change on stop/deallocate | Changes when resource is stopped/deallocated (Basic only; Standard v1/v2 are always static) |
| **Allocation — static** | Reserved from subnet address space; persists across stop/start cycles | Persists for lifetime of the Public IP resource regardless of attachment state |
| **DNS** | Azure-provided reverse DNS within a VNet; Private DNS for custom names | Forward/reverse DNS configurable on Public IP resource; Azure Public DNS for internet-facing zones |

**Key constraint:** Addresses in `224.0.0.0/4` (multicast), `255.255.255.255/32` (broadcast), `127.0.0.0/8` (loopback), and `169.254.0.0/16` (link-local) **cannot be assigned** to VNet address spaces. Azure reserves `168.63.129.16/32` — it is not assignable. [VERIFY]

---

## Public IP address SKUs

Basic public IP **retires September 30, 2025**. Migrate to Standard immediately.

| SKU | Allocation method | Zone support | Security default | Idle timeout | Notes |
|---|---|---|---|---|---|
| **Standard v2** | Static only | Zone-redundant (always — cannot be zonal) [VERIFY] | Closed to inbound; NSG required | Configurable [VERIFY] | Currently only usable with Standard v2 NAT Gateway [VERIFY]; not yet generally usable for VMs/LBs [VERIFY] |
| **Standard v1** | Static only | Zone-redundant or zonal (your choice) | Closed to inbound; NSG required to allow traffic | Configurable | General-purpose: VMs, Load Balancers, Firewalls, Gateways, Bastion |
| **Basic** *(retiring)* | Static or Dynamic | None (non-zonal only) | **Open to inbound by default** — no NSG required | Fixed 4 min [VERIFY] | **RETIRED September 30, 2025** [VERIFY] — migrate to Standard v1 now |

**Standard vs Basic — critical differences:**

- Standard is **closed to inbound by default** — traffic is blocked until an NSG explicitly permits it. Basic is open.
- Standard supports **zone redundancy** — survive AZ failures. Basic does not.
- Standard is required for **NAT Gateway, Standard Load Balancer, Application Gateway v2, Azure Firewall, and Bastion**.
- Standard uses **static allocation only** — the IP never changes while the resource exists.
- Basic must be migrated before September 30, 2025 [VERIFY]; after that date, Basic public IPs are decommissioned.

### Public IP prefixes

A contiguous block of Standard public IPs allocated together:

| Prefix size | IP count | Use case |
|---|---|---|
| /28 | 16 IPs | NAT Gateway (max scale), outbound allow-listing |
| /29 | 8 IPs | NAT Gateway mid-scale |
| /30 | 4 IPs | Small-scale deterministic outbound |
| /31 | 2 IPs | Minimal fixed-IP scenarios |

Prefixes simplify firewall allow-listing: one CIDR covers all outbound IPs instead of individual entries. [VERIFY: prefix sizes and availability]

---

## Outbound connectivity patterns

There are four ways a VM or VNet-integrated resource reaches the internet outbound, in descending order of recommendation:

### Pattern 1 — NAT Gateway (recommended)

A NAT Gateway attached to a subnet becomes that subnet's **default internet route automatically** — no UDR needed. All VMs in the subnet SNAT through the NAT Gateway's public IP(s).

```
VM (private IP) → [NAT Gateway SNAT] → Public IP → Internet
```

- **Scale:** Up to 16 public IPs × 64,512 SNAT ports per IP ≈ **1,032,192 SNAT ports total** [VERIFY]
- **Port allocation:** Dynamic, on-demand — no pre-configuration, no pre-allocation per VM
- **Precedence:** Takes precedence over Load Balancer outbound rules and instance-level public IPs when on the same subnet
- **Retirement-safe:** Explicitly satisfies the March 31, 2026 default outbound access retirement requirement

### Pattern 2 — Instance-level public IP on VM NIC

A public IP attached directly to a VM NIC. The VM performs 1:1 SNAT.

```
VM (private IP ↔ public IP 1:1) → Internet
```

- Deterministic outbound IP per VM
- **Does not scale** — one public IP per VM; no port sharing
- Exposes the VM directly to the internet (Standard: blocked by NSG; Basic: open by default)
- Use for individual VMs that need a dedicated fixed outbound IP; avoid for fleet deployments

### Pattern 3 — Load Balancer outbound rules (shared SNAT pool)

A Standard Public Load Balancer with explicit outbound rules shares its frontend IP(s) as a SNAT pool across all backend pool members.

```
VM (private IP) → [LB SNAT via frontend IP] → Internet
```

- **Port allocation:** Pre-allocated per VM based on backend pool size (see table below)
- **Risk:** Fixed port allocation means SNAT exhaustion is possible as pool grows
- **Mitigation:** Add more frontend IPs to the LB; tune port allocation in outbound rules
- NAT Gateway takes precedence if both are configured on the same subnet

**Default SNAT port allocation by backend pool size:** [VERIFY all values]

| Backend pool size | Ports allocated per VM |
|---|---|
| 1 – 50 VMs | 1,024 |
| 51 – 100 VMs | 512 |
| 101 – 200 VMs | 256 |
| 201 – 400 VMs | 128 |
| 401 – 800 VMs | 64 |
| 801 – 1,000 VMs | 32 |

Each public frontend IP on a Standard Load Balancer provides 64,000 [VERIFY] SNAT ports total to split across the pool.

### Pattern 4 — Default outbound access ⚠️ RETIRING

Azure historically gave VMs an implicit, system-managed public IP for outbound traffic when no other outbound method was configured.

> ⚠️ **Breaking change — March 31, 2026:** New virtual networks created after this date default to **private subnets** — default outbound access is disabled. VMs in private subnets have no implicit internet egress. **Existing VNets are not affected** — only newly created VNets with API versions released after this date. [VERIFY exact scope]

**Why default outbound is dangerous regardless of retirement:**
- The assigned IP is dynamic — it can change, breaking IP-based allow-lists
- Does not support ICMP or fragmented packets
- No SLA, no monitoring, no control
- Cannot be scaled

**Recommended replacement:** NAT Gateway (Pattern 1 above).

### Outbound priority when multiple methods coexist

| Priority | Method | Production-grade? |
|---|---|---|
| 1 (highest) | NAT Gateway on subnet | ✅ Yes |
| 2 | Instance-level Public IP on VM NIC | ✅ Yes (single VM only) |
| 3 | LB frontend via explicit outbound rules | ✅ Yes, with scale limits |
| 4 | LB frontend implicit (no outbound rules defined) | ❌ No — SNAT exhaustion risk |
| 5 (lowest) | Default outbound access | ❌ No — retiring; IPs subject to change |

---

## SNAT exhaustion: understanding and avoiding it

**What it is:** Source Network Address Translation (SNAT) maps a VM's private IP + ephemeral port to a public IP + port for outbound flows. Each unique outbound connection (same source + destination IP:port 5-tuple) consumes one SNAT port for the duration of the flow plus an idle timeout window. When the SNAT port inventory is exhausted, new outbound connections fail silently or with connection refused errors.

**Who is affected:**
- VMs using Load Balancer outbound rules (fixed, pre-allocated port pools per VM)
- VMs using default outbound access (extremely small implicit pool)
- NAT Gateway users are largely immune — ports are dynamically allocated on-demand from a shared pool up to ~1M total [VERIFY]

**How to diagnose:**

| Signal | Where to find it |
|---|---|
| `SNAT Connection Count` metric spiking | Load Balancer → Monitoring → Metrics |
| `Used SNAT Ports` approaching `Allocated SNAT Ports` | Load Balancer → Monitoring → Metrics |
| `Dropped Packets` | NAT Gateway → Monitoring → Metrics |
| Connection timeout errors in app logs | Application-level |
| `Datapath Availability` < 100% on NAT Gateway | NAT Gateway → Monitoring → Insights |

**How to fix it:**

| Fix | Applicable to | Effect |
|---|---|---|
| **Migrate to NAT Gateway** | Any subnet | Best fix — dynamic allocation, scales to ~1M ports per 16 IPs |
| **Add more public IPs to LB** | Load Balancer outbound rules | Each IP adds 64,000 [VERIFY] ports to the shared pool |
| **Tune LB outbound rule port allocation** | Load Balancer outbound rules | Manually override default per-VM allocation |
| **Add more public IPs to NAT Gateway** (up to 16) | NAT Gateway | Each IP adds 64,512 ports [VERIFY] |
| **Connection pooling in application code** | Any | Reuse connections; reduces port churn dramatically |
| **TCP keep-alives** | Any | Prevents idle timeout from recycling connections prematurely, reducing reconnect churn |
| **Multiple NAT Gateways on different subnets** | NAT Gateway | Isolates SNAT pools per subnet; avoids pool contention between workloads |
| **Private Link for Azure PaaS** | PaaS access | Eliminates SNAT entirely — private endpoint traffic doesn't SNAT |

**NAT Gateway SNAT scaling formula:** `Expected peak concurrent flows × 1.5 safety margin → number of required IPs`

---

## VNet address space planning

### RFC ranges and Azure behavior

| RFC | Range | Azure treatment |
|---|---|---|
| RFC 1918 | `10.0.0.0/8` | ✅ Recommended — large, unlikely to conflict |
| RFC 1918 | `172.16.0.0/12` | ✅ Recommended — medium; avoid if on-premises uses this range |
| RFC 1918 | `192.168.0.0/16` | ✅ Recommended — small; commonly used on-premises, verify first |
| RFC 6598 | `100.64.0.0/10` | ✅ Supported by Azure as private; often used for carrier-grade NAT overlaps |
| — | `224.0.0.0/4` | ❌ Multicast — not allowed in VNet address space |
| — | `255.255.255.255/32` | ❌ Broadcast — not allowed; Azure VNets have no broadcast |
| — | `127.0.0.0/8` | ❌ Loopback — not allowed |
| — | `169.254.0.0/16` | ❌ Link-local — not allowed; `169.254.169.254` (IMDS) is platform-only |
| — | `168.63.129.16/32` | ❌ Azure platform-reserved — not assignable [VERIFY] |

### Reserved IPs per subnet — the "5 tax"

Azure reserves **5 IP addresses** in every subnet regardless of size:

| Reserved address | Purpose |
|---|---|
| First address (x.x.x.0) | Network address |
| Second address (x.x.x.1) | Default gateway |
| Third address (x.x.x.2) | Azure DNS mapping |
| Fourth address (x.x.x.3) | Azure DNS mapping |
| Last address (x.x.x.255 for /24) | Broadcast address (reserved even though Azure has no broadcast) |

**Impact on small subnets:** [VERIFY]

| Subnet size | Total IPs | Usable IPs (after 5 reserved) |
|---|---|---|
| /29 | 8 | 3 |
| /28 | 16 | 11 |
| /27 | 32 | 27 |
| /26 | 64 | 59 |
| /24 | 256 | 251 |

### Minimum subnet sizes for Azure-managed services

| Service | Minimum subnet size | Notes |
|---|---|---|
| General VMs / resources | /29 | Gives 3 usable IPs after reserved |
| VPN Gateway (`GatewaySubnet`) | /29 [VERIFY] | Microsoft recommends /27 or larger for production |
| Azure Bastion (`AzureBastionSubnet`) | /26 [VERIFY] | Smaller sizes not supported |
| Azure Firewall (`AzureFirewallSubnet`) | /26 [VERIFY] | Smaller sizes not supported |
| Azure DNS Private Resolver (inbound/outbound) | /28 [VERIFY] | Dedicated delegated subnet required; `/28` to `/24` |
| Application Gateway v2 | /24 recommended [VERIFY] | Can autoscale; needs room to grow |

### Non-overlapping requirement

VNet address spaces **must not overlap** with:
- Any directly peered VNet address spaces (local or global peering)
- Any VNet connected via VPN Gateway in the same hub
- On-premises address ranges reachable via VPN or ExpressRoute

Overlapping CIDRs silently break routing — traffic may reach the wrong destination or be blackholed without an explicit error at configuration time.

### Address space expansion

Azure supports **adding non-contiguous CIDR blocks** to an existing VNet. You are not forced to use a single contiguous range. Best practice: plan a primary large range and expand with additional blocks as the environment grows rather than trying to upsize the original CIDR (which requires recreating subnets).

---

## IPv6 in Azure

Azure supports **dual-stack VNets**: a VNet can have both an IPv4 prefix and an IPv6 prefix (`/48` or larger; subnets must be exactly `/64` [VERIFY]).

### Service IPv6 support matrix

| Service | IPv6 support | Notes |
|---|---|---|
| Azure Virtual Network | ✅ Dual-stack | VNet + subnet must have both IPv4 and IPv6 prefixes |
| Azure Load Balancer (Standard) | ✅ Dual-stack | IPv4/IPv6 frontend IPs; IPv4/IPv6 backend pool members |
| NAT Gateway (Standard) | ❌ IPv4 only | — |
| NAT Gateway (StandardV2) | ✅ IPv4 + IPv6 | Up to 16 IPv4 + 16 IPv6 public IPs [VERIFY] |
| Application Gateway | ❌ [VERIFY] | Not confirmed in source articles — verify before relying on this |
| Azure Firewall | ❌ [VERIFY] | Not confirmed in source articles — verify before relying on this |
| VPN Gateway | ❌ [VERIFY] | Not confirmed in source articles |
| Azure Bastion | ❌ [VERIFY] | Not confirmed in source articles |
| NSGs | ✅ | IPv6 rules supported |

### IPv6 subnet constraints

- IPv6 subnets must be exactly `/64` — no other prefix length is valid [VERIFY]
- Each NIC in a dual-stack subnet gets both a private IPv4 and a private IPv6 address
- Azure-provided DNS (`168.63.129.16`) handles AAAA record resolution for VNet resources [VERIFY]
- IPv6 public IPs use Standard SKU only (no Basic IPv6)

### IPv6 prefix allocation

Public IPv6 prefixes can be allocated for outbound connectivity. NAT Gateway StandardV2 supports `/124` IPv6 prefixes [VERIFY].

---

## Private IP management

### Dynamic vs static

| Property | Dynamic | Static |
|---|---|---|
| Assignment | Azure DHCP assigns from subnet range on NIC attach | You specify the IP; Azure validates it's free and reserves it |
| Persistence | May change on stop/deallocate of VM | Persists across stop/start and deallocate cycles |
| Use case | Dev/test; any resource that doesn't need a fixed IP | DNS servers, domain controllers, NVAs, anything referenced by IP in firewall rules |
| How to change | Stop/deallocate and restart (IP may change) | Update via portal/CLI/API; brief connectivity interruption |

### Azure-provided DNS — `168.63.129.16`

Every VM in a VNet uses `168.63.129.16` as its default DNS resolver unless overridden. This address is:
- A **virtual IP** owned by Azure; not reachable from outside Azure
- Answers A/AAAA queries for Azure Private DNS zones linked to the VNet
- Answers reverse DNS (PTR) queries for resources in the VNet
- Also serves as the **health probe source IP** for Load Balancer (`168.63.129.16`) — **must be allowed in NSGs and host firewalls**
- Does **not** perform DNSSEC validation — if DNSSEC end-to-end validation is required, deploy a custom recursive resolver

### VNet DNS server customisation

| Option | Behaviour |
|---|---|
| **Default (Azure-provided)** | `168.63.129.16` — resolves Azure Private DNS zones + public internet |
| **Custom DNS servers** | Set per VNet; up to 20 DNS server IPs [VERIFY]; overrides the default for all VMs in the VNet |
| **Azure DNS Private Resolver** | Managed inbound/outbound endpoints replace custom VM-based DNS; supports hybrid resolution (on-premises ↔ Azure private zones) |

**Custom DNS + Private DNS zones:** If you set custom DNS servers on a VNet, those servers must forward Azure Private DNS zone names to `168.63.129.16` — otherwise Private DNS zone records won't resolve for VNet resources.

**DNS server limit per VNet:** 20 [VERIFY]

---

## Special Azure IP ranges

These addresses are reserved by the Azure platform and appear in traffic flows — understand them to avoid breaking NSG rules and health probes.

| Address | Name | Purpose | NSG impact |
|---|---|---|---|
| `168.63.129.16` | Azure platform / Azure DNS | Health probe source for Load Balancer; Azure DNS resolver for VNets; agent communication (extensions, platform metadata) | **Must be allowed inbound** in any NSG protecting backend VMs behind a Load Balancer — use `AzureLoadBalancer` service tag |
| `169.254.169.254` | Instance Metadata Service (IMDS) | REST endpoint for VM metadata (region, subscription, SKU, public IP, access tokens) — accessible from VM only, not routable in VNet | Not applicable — link-local, VM-only |
| `AzureLoadBalancer` | Service tag | Represents `168.63.129.16`; use in NSG rules to allow health probe traffic | Use `AzureLoadBalancer` as source in inbound NSG rules on backend VMs |
| `AzurePlatformDNS` | Service tag | Represents Azure DNS infrastructure IPs | Allow outbound in NSGs if custom DNS is not configured |
| `AzureCloud` | Service tag | All Azure datacenter IP ranges in a region | Broad; use for allowing outbound to Azure services when Private Link / service endpoints aren't used |

---

## Gotchas

| # | Gotcha | Impact | Fix |
|---|---|---|---|
| 1 | **Default outbound access retires March 31, 2026** | New VNets will have no internet egress for VMs — silent connectivity failure | Add NAT Gateway to all subnets needing outbound internet before creating new VNets |
| 2 | **Basic public IP retires September 30, 2025** | Resources using Basic public IPs will lose connectivity after retirement [VERIFY] | Migrate to Standard v1 now — use the Azure portal bulk migration tool |
| 3 | **SNAT port exhaustion with Load Balancer** | New outbound connections fail; appears as connection timeout with no server-side error | Move to NAT Gateway; or add more frontend IPs + tune outbound rule port allocation |
| 4 | **Subnet reserved IPs eating small subnets** | A `/29` only gives 3 usable IPs; an `/28` gives 11 — easy to run out with Azure-managed services | Size subnets generously; never go below `/28` for any service subnet |
| 5 | **IPv6 not supported by all services** | Dual-stack design may break at certain hops (Firewall, App Gateway) [VERIFY] | Verify IPv6 support for every service in the data path before committing to dual-stack design |
| 6 | **Overlapping address spaces break peering and VPN** | Routing is silently broken — traffic may route to wrong destination or drop | Plan address spaces centrally before peering; use a IPAM tool for large environments |
| 7 | **168.63.129.16 blocked by host firewall** | Load Balancer marks all backend VMs as unhealthy — no traffic forwarded | Allow `AzureLoadBalancer` service tag inbound in NSGs AND in OS-level firewalls |
| 8 | **Custom DNS server set without forwarding to 168.63.129.16** | Azure Private DNS zones stop resolving; Private Endpoints break | Configure conditional forwarder on custom DNS server to forward Azure private zones to `168.63.129.16` |
| 9 | **Standard public IP closed to inbound by default** | Assigning a Standard IP to a VM NIC does not allow any traffic — NSG required | Add NSG with explicit allow rules before assigning Standard public IP; or ensure LB rules handle traffic |
| 10 | **NAT Gateway cannot attach to gateway subnets** | VPN Gateway subnets cannot use NAT Gateway for outbound | Use Azure Firewall via UDR for internet egress from gateway subnet if needed [VERIFY] |

---

## Related pages

- [Azure Virtual Network](../services/virtual-network.md) — VNet is the container for all private IPs and subnets; address space planning, NSGs, UDRs, and peering all live here
- [NAT Gateway](../services/nat-gateway.md) — Recommended outbound connectivity; provides scalable SNAT from private subnets; 64,512 SNAT ports per public IP
- [Azure Load Balancer](../services/load-balancer.md) — Public frontend IPs as shared SNAT pool; SNAT port allocation by pool size; outbound rules configuration
- [Azure DNS](../services/dns.md) — Azure Private DNS zones for VNet name resolution; DNS Private Resolver for hybrid DNS; role of `168.63.129.16`

---

## Source articles

| Source | Used for |
|---|---|
| [`wiki/services/virtual-network.md`](../services/virtual-network.md) | RFC ranges, reserved IPs, subnet sizing, Public IP SKUs, default outbound retirement, address space planning |
| [`wiki/services/nat-gateway.md`](../services/nat-gateway.md) | Outbound patterns, SNAT port counts, NAT Gateway SKU comparison, SNAT exhaustion mitigations, StandardV2 IPv6 |
| [`wiki/services/load-balancer.md`](../services/load-balancer.md) | SNAT port allocation table, outbound rules, outbound priority order, LB outbound patterns, SNAT diagnostics |
| [`wiki/services/dns.md`](../services/dns.md) | `168.63.129.16` role, DNSSEC non-validation, Private DNS autoregistration, custom DNS configuration, DNS Private Resolver |
| [`raw/articles/networking/fundamentals/networking-overview.md`](../../raw/articles/networking/fundamentals/networking-overview.md) | Service landscape overview, NAT Gateway and VNet introductory framing |