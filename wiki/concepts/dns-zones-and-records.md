# DNS Zones and Records in Azure

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** current

## Overview

Azure DNS provides both public and private DNS zone hosting, plus a managed DNS resolver for hybrid name resolution. This page covers zone types, record types, the Azure DNS Private Resolver, Private Endpoint auto-registration, and key operational considerations.

---

## Zone types

| Zone type | Scope | Use case |
|---|---|---|
| **Public DNS zone** | Internet | Host DNS records for domains accessible from the public internet |
| **Private DNS zone** | VNet-scoped | Custom domain names for VNet resources; split-horizon; Private Link integration |

### Public DNS zones

- Host zones for domains you own (purchase domain separately from App Service Domains or third-party registrar)
- Delegate NS records from registrar to Azure name servers
- Anycast networking ensures queries answered by closest Azure name server
- **DNSSEC supported** (ECDSAP256SHA256); ZSK auto-rolled; KSK replacement requires Microsoft support

### Private DNS zones

- Custom domain names (e.g., `contoso.internal`) for VNet resources
- Global resource — data replicated across regions automatically
- VNet links connect zones to VNets (Registration or Resolution link type)
- **Autoregistration**: when enabled, VM A records auto-created, updated on IP change, deleted with VM (primary NIC only)
- One VNet can be a registration VNet for only **one** private zone

---

## Record types

| Type | Purpose |
|---|---|
| **A** | Maps hostname to IPv4 address |
| **AAAA** | Maps hostname to IPv6 address |
| **CNAME** | Alias to another hostname (cannot be at zone apex) |
| **MX** | Mail exchange server with priority |
| **TXT** | Arbitrary text (SPF, DKIM, domain verification) |
| **PTR** | Reverse DNS (IP to hostname) |
| **SRV** | Service location with port and priority |
| **NS** | Name server delegation |
| **SOA** | Zone authority and metadata (serial, refresh, retry, expire, TTL) |
| **CAA** | Certificate Authority Authorization |
| **DS / TLSA** | DNSSEC and DANE records |

### Alias records

- Dynamic references to Azure resources (public IP, Traffic Manager, CDN, Front Door)
- Auto-updates when underlying resource IP changes — prevents dangling DNS
- **Solves zone apex CNAME limitation**: A/AAAA/CNAME alias records supported at apex
- Limit: 50 alias record sets per Azure resource [VERIFY]

### TTL

- Range: 1 to 2,147,483,647 seconds
- Set per record set, not per individual record
- Lower TTL = faster DNS propagation but more queries

---

## Azure DNS Private Resolver

A fully managed service that enables hybrid DNS resolution without VM-based DNS servers.

### Components

| Component | Purpose |
|---|---|
| **Inbound endpoint** | IP address (from dedicated /28+ subnet) that on-premises DNS conditional forwarders target to resolve Azure private zones |
| **Outbound endpoint** | Egresses DNS queries from Azure to on-premises or external DNS servers; associated with forwarding rulesets |
| **DNS forwarding ruleset** | Group of up to 1,000 forwarding rules; linked to up to 500 VNets in the same region |
| **DNS forwarding rule** | Domain name (up to 34 labels, or wildcard `.`), destination IP:port, enabled/disabled |

### Hybrid DNS patterns

| Direction | Configuration |
|---|---|
| **On-premises → Azure** | Point on-premises conditional forwarder at inbound endpoint IP |
| **Azure → on-premises** | Configure outbound endpoint ruleset rules for on-premises domains |

### Requirements and limitations

- Requires VPN or ExpressRoute network connectivity
- Requires dedicated subnet delegated to `Microsoft.Network/dnsResolvers`
- Built-in HA and zone redundancy — no configuration required
- **Not compatible with VNet encryption** — deploy resolver in non-encrypted VNet
- **Not compatible with ExpressRoute FastPath** — FastPath bypasses virtual network gateway
- **Not compatible with Azure Lighthouse** cross-tenant delegation

---

## Private Endpoint DNS auto-registration

When creating a Private Endpoint with integration to a Private DNS Zone:
1. Azure creates a CNAME on public DNS pointing to `privatelink.*` subdomain
2. Private DNS Zone resolves the `privatelink.*` name to the PE private IP
3. Client applications continue using the original FQDN — no URL changes needed

### Selected Private DNS Zone names

| Service | Private DNS Zone |
|---|---|
| Azure Blob Storage | `privatelink.blob.core.windows.net` |
| Azure SQL Database | `privatelink.database.windows.net` |
| Azure Key Vault | `privatelink.vaultcore.azure.net` |
| Azure Event Hubs / Service Bus | `privatelink.servicebus.windows.net` |
| Azure Container Registry | `privatelink.azurecr.io` |

### NxDomainRedirect fallback

- For Private Link zones: set `resolutionPolicy: NxDomainRedirect` on VNet link
- Falls back to public internet resolution when NXDOMAIN response received
- Available for Private Link zones only (API version 2024-06-01+)

---

## Split-horizon DNS

Same zone name can exist as both public and private zone:
- VNet-internal clients resolve private records
- Internet clients resolve public records
- Common pattern for hybrid environments with consistent naming

---

## DNSSEC

| Aspect | Detail |
|---|---|
| Support | Zone signing for public zones |
| Algorithm | ECDSAP256SHA256 |
| ZSK rotation | Automatic |
| KSK replacement | Requires Microsoft support |
| RFC 9824 | Compact denial of existence (prevents zone enumeration) |
| Azure recursive resolver | 168.63.129.16 does **NOT** perform DNSSEC validation |

> To enforce end-to-end DNSSEC validation, deploy a custom recursive DNS server (e.g., Unbound or Windows DNS with DNSSEC enabled).

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| DNS zones per subscription | See Azure DNS Limits [VERIFY] | Soft limit |
| Record sets per zone | See Azure DNS Limits [VERIFY] | |
| TTL range | 1 – 2,147,483,647 seconds | |
| Alias record sets per resource | 50 [VERIFY] | |
| DNS forwarding rules per ruleset | 1,000 | |
| VNets linked per ruleset | 500 | Same region only |
| DNS servers per VNet | 20 [VERIFY] | |

---

## Related pages

- [Azure DNS](../services/dns.md) — full service reference
- [Private Link](../services/private-link.md) — Private Endpoint DNS integration
- [Private access to PaaS](private-access-to-paas.md) — DNS configuration guidance
- [Hybrid DNS resolution pattern](../patterns/dns-hybrid-resolution.md)
