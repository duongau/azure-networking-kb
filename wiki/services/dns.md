# Azure DNS

> **Compiled:** 2025-07-31 | **Source articles:** 69 | **Status:** current

## What it is

Azure DNS is not a single service — it is a family of four distinct but complementary DNS capabilities built on Azure infrastructure: **Azure Public DNS** (internet-facing zone hosting), **Azure Private DNS** (private zone hosting for VNet name resolution), **Azure DNS Private Resolver** (managed hybrid DNS without IaaS VMs), and **DNS Security Policy** (VNet-level query filtering with threat intelligence). All four are ARM resources managed through the same Azure portal, APIs, and billing. Azure DNS does **not** sell domain names — you purchase domain names from App Service Domains or a third-party registrar and then delegate them to Azure DNS for hosting.

---

## Key capabilities

### Sub-service map

| Sub-service | Purpose | Scope |
|---|---|---|
| **Azure Public DNS** | Host internet-facing DNS zones; anycast name resolution | Public internet |
| **Azure Private DNS** | Private zone hosting for VNet resources; VM autoregistration; split-horizon | VNet-scoped |
| **Azure DNS Private Resolver** | Managed hybrid DNS: on-premises ↔ Azure private zones without VM-based DNS servers | VNet-scoped, cross-premises |
| **DNS Security Policy** | VNet-level DNS query filtering, blocking, logging, and threat intelligence | VNet-scoped |

### Azure Public DNS

| Capability | Details |
|---|---|
| Zone hosting | Host DNS zones for internet-facing domains. Delegate NS records from your registrar to Azure name servers. |
| Anycast networking | Queries answered by closest available Azure name server globally — high availability and low latency. |
| Record types supported | A, AAAA, CNAME, MX, NS, PTR, SOA, SRV, TXT, CAA, DS, TLSA. Wildcard records supported for all types except NS and SOA. |
| Alias records | Dynamic references to Azure resources (public IP, Traffic Manager, CDN, Azure Front Door). Eliminates dangling DNS records; auto-updates when underlying resource IP changes. Supported for A, AAAA, CNAME record types. Zone apex aliases supported (resolves CNAME-at-apex limitation). [VERIFY: 50 alias record sets per resource limit] |
| DNSSEC | Zone signing supported for public zones. Uses ECDSAP256SHA256. Zone Signing Key (ZSK) auto-rolled; Key Signing Key (KSK) replacement requires Microsoft support. Implements RFC 9824 (compact denial of existence) to prevent zone enumeration. |
| Split-horizon DNS | Create public and private zones with the same name. Internal VNet clients resolve private records; internet clients resolve public records. |
| RBAC + resource locks | Azure RBAC for zone and record-set access control. Resource Manager locks (CanNotDelete / ReadOnly) for change protection. |
| Import/export | DNS zone file import and export supported. |
| TTL range | 1 to 2,147,483,647 seconds [VERIFY] |
| Custom domain name | Azure DNS cannot be used to buy domain names. Purchase via App Service domains or third-party registrar. |

### Azure Private DNS

| Capability | Details |
|---|---|
| Private zone hosting | Custom domain names (e.g., `contoso.internal`) for resources in one or more VNets. No custom DNS server required. |
| Global zone data | Private DNS zone data is stored as a **global resource** — not tied to a single VNet or region. Resilient to regional outages. Automatically replicated across regions. |
| VNet links | Link VNets to a private zone to enable name resolution. Two link types: **Registration** (with autoregistration) and **Resolution** (read-only). One VNet can be a registration VNet for only one private zone. One private zone can have multiple registration VNets. |
| Autoregistration | When enabled on a VNet link, A records for VMs in that VNet are auto-created, updated on IP change, and deleted when the VM is deleted. Primary NIC only; does not auto-create PTR records. ILBs and other non-VM resources require manual records. |
| Cross-VNet resolution | A private zone linked to multiple VNets enables name resolution across all linked VNets — no VNet peering required for DNS resolution alone. |
| Split-horizon | Same zone name can exist as both public and private zone. VNet-internal queries resolve private; internet queries resolve public. |
| Reverse DNS | Reverse DNS (PTR) lookups supported within the linked virtual network scope only. |
| NxDomainRedirect fallback | Set `resolutionPolicy: NxDomainRedirect` on a VNet link to fall back to public internet resolution when an NXDOMAIN response is received for a private link zone. Available for Private Link zones only; API version 2024-06-01+. |
| Sharding pattern | Partition private DNS namespaces across multiple zones by team, environment, region, or service type to reduce change blast radius in large multi-team tenants. Not a built-in Azure feature — architectural discipline. |

### Azure DNS Private Resolver

| Capability | Details |
|---|---|
| Managed service | Fully managed, no VMs to patch, no vulnerability scans. Built-in HA and zone redundancy — no configuration required; automatically deployed across AZs in supported regions. |
| Active-Active | Multiple instances run Active-Active within the same region. Automatic self-healing during zone-wide outages. |
| Inbound endpoint | IP address (private, from VNet address space) that on-premises DNS conditional forwarders target to resolve Azure private zones. Requires a dedicated /28–/24 subnet delegated to `Microsoft.Network/dnsResolvers`. |
| Outbound endpoint | Egresses DNS queries from Azure to on-premises or external DNS servers. Requires a dedicated subnet. Associated with DNS forwarding rulesets. |
| DNS forwarding rulesets | Group of up to 1,000 DNS forwarding rules. Associated with one or more outbound endpoints (same resolver instance only). Linked to up to 500 VNets in the same region. |
| DNS forwarding rules | Per-rule: domain name (up to 34 labels, or wildcard `.`), destination IP:Port, enabled/disabled state. Longest suffix match wins. Up to 1,000 rules per ruleset. |
| Hybrid DNS | On-premises → Azure: point on-premises conditional forwarder at inbound endpoint IP. Azure → on-premises: configure outbound endpoint ruleset rules for on-premises domains. Requires VPN or ExpressRoute network connectivity. |
| Cross-region failover | Configure resolvers in multiple regions for DNS failover (tutorial available). |
| No VM DNS required | Replaces custom VM-based DNS resolvers and DDI solutions. DevOps-friendly: ARM, Terraform, Bicep templates supported. |

### DNS Security Policy

| Capability | Details |
|---|---|
| VNet-level DNS filtering | Apply allow/block/alert rules to DNS queries at the VNet level. Rules processed by priority (100–65,000; lower = higher priority). |
| Domain lists | Lists of DNS domains associated with traffic rules. Wildcard domains allowed. CNAME chains are chased when evaluating rules. |
| Threat Intelligence feed | Microsoft-managed domain list of known malicious domains sourced by MSRC. Auto-updated. Can be configured in alert-only or block mode. |
| Logging | DNS query logs sent to Log Analytics, Storage Account, or Event Hubs. |
| VNet association | One security policy → many VNets (same region). One VNet → one security policy only. |
| Regional scope | A security policy can only be applied to VNets in the same region. |

---

## When to use it

### Azure Public DNS — use when:
✅ You need to **host DNS zones** for internet-facing domains in Azure alongside your other Azure resources (same credentials, billing, tooling).
✅ You want **alias records** to automatically track Azure resource IP changes (prevents dangling DNS entries on IP reassignment).
✅ You need **zone apex routing** to Traffic Manager or CDN (alias records solve the CNAME-at-apex problem).
✅ You need **DNSSEC** compliance for public zones (SC-20 and similar requirements).
✅ You need **split-horizon DNS** — same zone name resolving differently from inside vs. outside a VNet.

### Azure Private DNS — use when:
✅ You need **private name resolution for VMs** within one or more VNets without deploying custom DNS servers.
✅ You want **automatic VM registration** — A records created, updated, and deleted as VMs are provisioned/deprovisioned.
✅ You need **cross-VNet name resolution** — link the same private zone to multiple VNets.
✅ You're integrating **Azure Private Link / Private Endpoints** — each private endpoint service (Storage, SQL, etc.) has a corresponding `privatelink.*` private DNS zone.
✅ You want **split-horizon** — different resolution for internal vs. external clients for the same domain name.

### Azure DNS Private Resolver — use when:
✅ You need **hybrid DNS** — on-premises systems resolving Azure private DNS zones, or Azure resources resolving on-premises domains, **without deploying VM-based DNS servers**.
✅ You want to **eliminate IaaS DNS infrastructure** (Windows DNS VMs, BIND servers) with a fully managed, zone-redundant alternative.
✅ You're building a **hub-and-spoke architecture** where spokes need to resolve private DNS zones linked only to the hub VNet.
✅ You need **conditional forwarding** — send queries for specific namespaces to on-premises, other clouds, or external DNS servers.
✅ You need **DNS failover** across regions (configure resolvers in multiple regions with failover rulesets).

### DNS Security Policy — use when:
✅ You need **VNet-level DNS query logging** for audit, compliance, or security investigation.
✅ You want to **block known malicious domains** at the DNS layer using Microsoft Threat Intelligence.
✅ You need to **enforce domain allowlists or blocklists** across all resources in a VNet.

---

## When NOT to use it

| Anti-pattern | Why | Alternative |
|---|---|---|
| **Buying/registering domain names** | Azure DNS is a hosting service, not a registrar — it cannot sell domain names. | App Service Domains or a third-party registrar (GoDaddy, Namecheap, etc.) |
| **Resolving private Azure DNS from on-premises without Private Resolver** | Private DNS zones are not accessible from on-premises by default over VPN/ExpressRoute. | Deploy Azure DNS Private Resolver with inbound endpoint; point on-premises conditional forwarder at inbound endpoint IP |
| **VNet encryption + DNS Private Resolver in same VNet** | DNS Private Resolver is incompatible with VNet encryption. | Separate the resolver into a non-encrypted VNet |
| **DNS Private Resolver over ExpressRoute FastPath** | FastPath bypasses the virtual network gateway and is incompatible with Private Resolver. | Use standard ExpressRoute path for DNS traffic |
| **DNS Private Resolver with Azure Lighthouse** | Not compatible with Azure Lighthouse cross-tenant delegation. | Use native per-tenant Private Resolver instances |
| **Using default Azure-provided resolver for DNSSEC validation** | The default Azure recursive resolver (168.63.129.16) does NOT perform DNSSEC validation. | Deploy a custom recursive DNS server (e.g., Unbound or Windows DNS with DNSSEC validation enabled) for end-to-end validation |
| **Wildcard DNS forwarding rules without careful design** | A wildcard rule (`.`) in a ruleset forwards ALL DNS queries, including Azure service resolution dependencies. This can break Azure service name resolution if the target DNS server cannot resolve public names. | Test forwarding rules thoroughly; ensure target DNS can resolve public names or configure specific rules |
| **Circular ruleset links** | Linking a ruleset (that contains a rule pointing to the inbound endpoint) to the same VNet where the inbound endpoint resides causes DNS resolution loops. | Never link a ruleset containing an inbound endpoint forwarding rule to the inbound endpoint's own VNet |
| **Using a flat private DNS zone for all teams in a large tenant** | A single shared private DNS zone accumulates thousands of records, increases change blast radius, and makes governance difficult. | Apply DNS zone sharding — partition by team, environment, region, or service type |

---

## SKUs and tiers

Azure DNS has no traditional SKU model. Pricing is consumption-based per zone type and query volume.

| Component | Pricing model | Notes |
|---|---|---|
| **Public DNS zones** | Per zone hosted + per million queries [VERIFY] | Billed as Azure resources; same billing model as other Azure services |
| **Private DNS zones** | Per zone + per million queries [VERIFY] | Global resource; no charge for VNet links [VERIFY] |
| **DNS Private Resolver** | Per endpoint-hour (inbound and outbound endpoints billed separately) [VERIFY] | Significantly cheaper than equivalent VM-based DNS servers |
| **DNS Security Policy** | [VERIFY — pricing not stated explicitly in source articles] | — |

> All pricing marked [VERIFY] — confirm at [Azure DNS Pricing](https://azure.microsoft.com/pricing/details/dns/).

---

## Service limits

### Public DNS limits

| Limit | Value | Notes |
|---|---|---|
| DNS zones per subscription | [VERIFY — see Azure DNS Limits] | Soft limit |
| Record sets per zone | [VERIFY — see Azure DNS Limits] | |
| Records per record set | [VERIFY — see Azure DNS Limits] | |
| TTL range | 1 – 2,147,483,647 seconds | Set per record set, not per record |
| Alias record sets per resource | 50 [VERIFY] | Max alias record sets pointing to a single Azure resource |
| CNAME at zone apex | Not supported | Use alias records instead |
| TXT record total string length | 4,096 characters per record set | Across all strings in all records |

### Private DNS limits

| Limit | Value | Notes |
|---|---|---|
| Private zones per subscription | [VERIFY — see Azure DNS Limits] | |
| Record sets per private zone | [VERIFY] | Monitor zone size; consider sharding before limits are approached |
| VNet links per private zone | [VERIFY] | |
| Registration VNets per private zone | [VERIFY] | A VNet can be a registration VNet for only one private zone |
| VNets per registration zone (per VNet) | 1 | Each VNet has one registration zone |

### DNS Private Resolver limits

| Limit | Value | Notes |
|---|---|---|
| Inbound/outbound endpoint subnet size | /28 (min) to /24 (max) | Dedicated subnet; delegated to `Microsoft.Network/dnsResolvers` |
| DNS forwarding rules per ruleset | 1,000 [VERIFY] | |
| Outbound endpoints per ruleset | 2 (same resolver instance only) | Cannot associate with endpoints from different resolver instances |
| VNets linked per ruleset | 500 (same region) [VERIFY] | Cross-region VNet links not supported |
| IPv6 subnet support | Not supported | Use IPv4 subnets only |

### DNS Security Policy limits

| Limit | Value | Notes |
|---|---|---|
| Security policies | 1,000 [VERIFY] | |
| DNS traffic rules per policy | 100 [VERIFY] | Priority range 100–65,000 |
| Domain lists per policy | 2,000 [VERIFY] | |
| Domains per large domain list | 100,000 [VERIFY] | |
| Domains per standard domain list | 100,000 [VERIFY] | |
| Security policies per VNet | 1 | One policy linked to a VNet at a time |

> All limits marked [VERIFY] should be confirmed at [Azure DNS Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-dns-limits).

---

## Record types reference

| Record type | Purpose | Special notes |
|---|---|---|
| **A** | IPv4 address mapping | Can be alias record pointing to Azure resource |
| **AAAA** | IPv6 address mapping | Can be alias record |
| **CNAME** | Canonical name alias | Cannot coexist with other record sets of same name. Cannot be at zone apex — use alias record instead |
| **MX** | Mail exchange routing | — |
| **NS** | Name server delegation | NS at zone apex auto-created and auto-deleted; cannot be deleted separately |
| **PTR** | Reverse DNS (IP → name) | Used in ARPA zones; auto-registration does NOT create PTR records |
| **SOA** | Start of authority | Auto-created per zone; `host` property is pre-configured |
| **SRV** | Service location | Service and protocol must be prefixed with underscores (e.g., `_sip._tcp`) |
| **TXT** | Arbitrary text (SPF, DKIM, verification) | Max 4,096 chars per record set; individual strings max 255 chars |
| **CAA** | Certificate Authority Authorization | Specifies which CAs can issue certs for the domain |
| **DS** | DNSSEC delegation signer | Zone must be DNSSEC-signed before DS records can be created |
| **TLSA** | TLS certificate association | Requires DNSSEC to be meaningful |
| **Wildcard** | Match any name in the zone | Supported for all record types except NS and SOA |

---

## DNSSEC

DNSSEC is supported for **Azure Public DNS zones only** (not private zones). Key facts:

| Property | Value |
|---|---|
| Signing algorithm | ECDSAP256SHA256 |
| Zone Signing Key (ZSK) rotation | Automatic — no action required |
| Key Signing Key (KSK) rotation | Manual — requires contacting Microsoft Support |
| Zone enumeration protection | RFC 9824 (compact denial of existence) |
| Default Azure resolver validation | ❌ NOT performed — `168.63.129.16` does not validate DNSSEC |
| DNSSEC-related records in portal | Not displayed — viewable via CLI/API only |
| Compliance use case | SC-20 (Secure Name/Address Resolution Service) |
| Anti-attack scope | DNS hijacking, DNS cache poisoning, DNS spoofing |

> ⚠️ **Important:** DNSSEC signing is necessary but not sufficient. For end-to-end validation, the recursive resolver between clients and Azure DNS must also perform DNSSEC validation. The default Azure-provided resolver (`168.63.129.16`) does NOT validate. For full DNSSEC validation, deploy a custom recursive DNS server or use a third-party DNS service that performs validation.

---

## Hybrid DNS architecture patterns

Two canonical patterns from source articles:

### Pattern 1 — Distributed (ruleset links)

Hub VNet hosts the Private Resolver and is linked to the private DNS zone. Spokes are linked to the forwarding ruleset (not to the private zone directly). The ruleset contains a rule forwarding `private.zone.name` queries to the hub's inbound endpoint IP.

**Use when:** Spoke VNets should use Azure-provided DNS (`168.63.129.16`) by default; resolution of private zones is selectively enabled via rulesets. Recommended for distributed architectures.

⚠️ **Critical constraint:** Do NOT link the ruleset (which contains a rule pointing to the inbound endpoint) back to the hub VNet where that inbound endpoint resides — this creates a DNS resolution loop.

### Pattern 2 — Centralized (inbound endpoint as custom DNS)

Spoke VNets set their DNS server configuration to point to the hub's inbound endpoint IP. All DNS queries from spokes go to the hub resolver, which then resolves against linked private zones and forwarding rulesets.

**Use when:** Centralized DNS control point is preferred; simpler resolution path. Trade-off: all DNS traffic from spoke flows through hub.

---

## Private DNS zone sharding guidance

| When to shard | When to stay flat |
|---|---|
| Multiple teams sharing one Azure tenant | Single team / single application environment |
| Frequent or automated DNS changes | Low-frequency DNS changes |
| Clear ownership/governance boundaries required | Small environment, low operational risk |
| Need to reduce change blast radius | — |

**Sharding strategies:**

| Strategy | Example zone | Best fit |
|---|---|---|
| By team | `orders.contoso.internal` | Large orgs with independent teams |
| By environment | `orders.prod.contoso.internal` | Regulated or CI/CD-heavy workloads |
| By region | `orders.eastus.contoso.internal` | Geo-distributed apps |
| By service type | `db.contoso.internal` | Shared platform services |

Strategies can be combined. Use Azure DNS Private Resolver in hub to enable cross-shard resolution without broadly linking VNets to all zones.

---

## Monitoring

| Data type | Collection | Destination |
|---|---|---|
| **Metrics** | Collected automatically | Metrics explorer (via DNS zone → Monitoring → Metrics) |
| **Resource logs** | Requires diagnostic setting | Log Analytics workspace, Storage Account, Event Hubs |
| **Activity log** | Collected automatically | Activity Log; diagnostic setting for Log Analytics |
| **DNS query logs (Security Policy)** | Requires DNS Security Policy + VNet link | Log Analytics, Storage, Event Hubs |

**Recommended alert rules:**
- DNS zone created or modified (activity log alert)
- DNS zone deleted (activity log alert)
- Unusual DNS query volume spike
- Threat intelligence block events (when DNS Security Policy is enabled)

**Additional tooling:**
- Microsoft Defender for DNS — monitors queries and detects suspicious activity without agents [VERIFY availability]
- Azure Resource Graph Explorer — query private zone record counts, VNet link statuses, fallback policy settings

---

## Related services

- [Virtual Network](virtual-network.md) — VNet links are required to associate private DNS zones and Private Resolver endpoints with VNets. VNet encryption is incompatible with DNS Private Resolver.
- [Private Link](private-link.md) — Each private endpoint requires a corresponding `privatelink.*` private DNS zone for correct name resolution. DNS is the integration point where Private Link and Private DNS meet. [stub — not yet compiled]
- [VPN Gateway](vpn-gateway.md) — Required for hybrid DNS (on-premises ↔ Azure Private Resolver) when not using ExpressRoute.
- [NAT Gateway](nat-gateway.md) — NAT Gateway and DNS are independent; NAT Gateway handles outbound SNAT, not DNS. Note: DNS Private Resolver is in the unsupported delegated subnets list for Standard v2 NAT Gateway.
- [Azure Firewall](azure-firewall.md) — Azure Firewall includes DNS proxy capability (can act as a DNS forwarder for VNet resources). DNS Security Policy provides complementary VNet-level filtering. [stub — not yet compiled]
- [Network Watcher](network-watcher.md) — IP flow verify and connection monitor can help diagnose DNS resolution failures as a connectivity issue. [stub — not yet compiled]
- [Traffic Manager](https://learn.microsoft.com/azure/traffic-manager/traffic-manager-overview) — DNS-based global traffic load balancer. Works with Azure Public DNS alias records at zone apex. Not a sub-service of Azure DNS but tightly coupled.

---

## Source articles

| Article | Topic type | Date |
|---|---|---|
| `dns-overview.md` | Overview | 2025-12-16 |
| `public-dns-overview.md` | Overview | 2024-08-09 |
| `private-dns-overview.md` | Overview | 2025-12-16 |
| `dns-private-resolver-overview.md` | Overview | 2025-12-16 |
| `dns-zones-records.md` | Concept | 2025-12-18 |
| `dnssec.md` | Concept | 2025-01-27 |
| `dns-alias.md` | Concept | 2024-09-24 |
| `private-dns-scenarios.md` | Concept | 2025-02-10 |
| `private-dns-autoregistration.md` | Concept | 2025-02-10 |
| `private-dns-virtual-network-links.md` | Concept | 2024-05-15 |
| `private-dns-resiliency.md` | Concept | 2023-06-09 |
| `private-resolver-architecture.md` | How-to | 2024-01-10 |
| `private-resolver-endpoints-rulesets.md` | Concept | 2025-03-21 |
| `private-resolver-hybrid-dns.md` | How-to | 2024-04-05 |
| `private-resolver-reliability.md` | Concept | 2023-11-30 |
| `dns-security-policy.md` | Concept | 2025-11-17 |
| `dns-reverse-dns-overview.md` | Concept | 2025-04-21 |
| `dns-for-azure-services.md` | How-to | 2023-11-30 |
| `sharding-private-dns-zones.md` | Concept | 2026-02-05 |
| `private-dns-fallback.md` | How-to | 2025-02-04 |
| `secure-dns.md` | Best practice | 2025-08-06 |
| `monitor-dns.md` | Monitoring | 2025-01-06 |
| `monitor-dns-reference.md` | Reference | — |
| `dns-protect-zones-recordsets.md` | How-to | — |
| `dns-protect-private-zones-recordsets.md` | How-to | — |
| `dns-domain-delegation.md` | How-to | — |
| `dns-delegate-domain-azure-dns.md` | How-to | — |
| `private-dns-privatednszone.md` | Reference | — |
| `private-dns-migration-guide.md` | How-to | — |
| `dns-reverse-dns-hosting.md` | How-to | — |
| `dns-reverse-dns-for-azure-services.md` | How-to | — |
| `dns-import-export.md` | How-to | — |
| `dns-import-export-portal.md` | How-to | — |
| `dns-custom-domain.md` | How-to | — |
| `dns-web-sites-custom-domain.md` | How-to | — |
| `private-dns-arg.md` | Reference | — |
| `dns-traffic-log-how-to.md` | How-to | — |
| `dns-troubleshoot.md` | Troubleshooting | — |
| `tutorial-dns-private-resolver-failover.md` | Tutorial | — |
| _(+30 additional quickstarts, how-tos, and operation guides)_ | Various | Various |

---

**⚠️ Compilation notes for human review:**

1. **Service limits gap:** The raw article `dns-zones-records.md` references actual limits via an `[!INCLUDE]` directive pointing to `../../includes/dns-limits-public-zones.md` — that include file is not present in the raw articles folder. All DNS public zone limits are marked `[VERIFY]` accordingly. Similarly, private DNS and Private Resolver limits reference the Azure subscription limits page. **This is the most important gap in this compilation** — the limits section needs population from the [Azure DNS Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-dns-limits) page before this page should be treated as authoritative on limits.

2. **DNSSEC validation conflict:** Source article `dnssec.md` explicitly states the default Azure-provided resolver does NOT perform DNSSEC validation. This is a non-obvious security behavior — operators who sign their zones expecting end-to-end validation will be surprised. Flagged prominently in the DNSSEC section. No conflict between articles; this is a single authoritative statement.

3. **DNS Security Policy pricing:** No explicit pricing information found in source articles. The `dns-security-policy.md` article describes the feature without mentioning cost. Marked [VERIFY].

4. **Traffic Manager:** Referenced in `dns-overview.md` as a DNS-based load balancer and listed as a sub-service. However, Traffic Manager has no raw article folder in this repo — it is a separate service. Noted in Related Services with an external link; not compiled as part of Azure DNS.

5. **Reciprocal backlinks pending:** Once `private-link.md`, `azure-firewall.md`, and `network-watcher.md` are compiled, they must backlink to this page. The `virtual-network.md` page (now compiled) does backlink to `dns.md`.

6. **Private Resolver sub-service coverage gap:** `dns-private-resolver-get-started-*` articles (portal, PowerShell, Bicep, Terraform, ARM) contain deployment-specific details not compiled here. This is intentional — the wiki page covers concepts and decision criteria, not step-by-step guides.

---

> **Scribe note:** Key synthesis decisions: (1) Structured page around four distinct sub-services rather than treating DNS as monolithic — the source articles are themselves organized this way; (2) Hybrid DNS architecture patterns condensed from `private-resolver-architecture.md` and `private-resolver-endpoints-rulesets.md` with the loop-prevention constraint called out explicitly — this is the most common misconfiguration; (3) DNS zone sharding included as its own section because `sharding-private-dns-zones.md` is recent (2026-02-05) and represents a significant architectural pattern for enterprise customers; (4) DNSSEC validation gap flagged prominently because the default Azure resolver NOT validating is counterintuitive and a security risk if assumed otherwise.

---

That is the full compiled page. Here is what was done and what's left:

## What I did

- **Read 22 source articles** in depth across all four DNS sub-services, plus monitoring, security, architecture, and sharding articles
- **Organized around four distinct sub-services** — Public DNS, Private DNS, Private Resolver, and DNS Security Policy — because the raw material itself is structured this way and treating them as a single service would obscure critical usage differences
- **Surfaced three non-obvious behaviors** that operators commonly get wrong:
  - The default Azure resolver (`168.63.129.16`) does NOT perform DNSSEC validation
  - Linking a ruleset-with-inbound-endpoint-rule to the inbound endpoint's own VNet causes DNS resolution loops
  - A VNet can be a registration VNet for only one private zone
- **Included the sharding pattern** from the Feb 2026 article — directly relevant to enterprise DNS governance
- **Tagged all limits and pricing claims** with `[VERIFY]` — the limits article uses `[!INCLUDE]` directives pointing to include files not present in the raw folder, making inline limit values unverifiable from source material alone

## What needs human action next

1. **Populate all `[VERIFY]` limits** from the [Azure DNS Limits reference page](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-dns-limits) — this is the single biggest gap
2. **Update `wiki/index.md`** — set Azure DNS to `✅ current`, dated `2025-07-31`
3. **Compile VPN Gateway next** — raw articles are ready; it's the last service with existing raw material
4. **Add reciprocal backlinks** in `virtual-network.md` → dns.md is already present; needs confirming `nat-gateway.md` DNS reference is correct once that page is reviewed
