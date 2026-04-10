# Private Access to PaaS

> **Compiled:** 2026-04-10 | **Source articles:** 8 | **Status:** current

## What it is

"Private access to PaaS" is not a single Azure service — it is the design problem of connecting to Azure PaaS services (Storage, SQL, Cosmos DB, Key Vault, etc.) from within a virtual network, from on-premises, or across organizational boundaries, without exposing traffic to the public internet. Azure offers four distinct patterns to solve this, each with different tradeoffs in complexity, security strength, scope, and cost.

---

## The Four Patterns

| Pattern | Mechanism | Recommended for |
|---|---|---|
| **Private Endpoint** | NIC with private VNet IP mapped to a specific PaaS resource instance | All new designs; data exfiltration protection required; on-premises access needed |
| **Service Endpoint** | Extends VNet identity to Azure service; optimizes routing; no private IP | Simple VNet-to-service restriction; legacy designs; lower cost priority |
| **VNet-injected deployment** | Service deployed directly into your VNet subnet (e.g., AKS, App Service Env, SQL MI) | Services that require full VNet membership (dedicated subnet delegation) |
| **Network Security Perimeter (NSP)** | Logical public-access boundary around PaaS resources outside VNets | Controlling public internet access; data exfiltration prevention at public layer |

> Microsoft explicitly recommends **Private Endpoints** over Service Endpoints for all new designs.
> Source: `vnet-integration-for-azure-services.md`, `virtual-network-service-endpoints-overview.md`

---

## Key capabilities

### Private Endpoint

| Capability | Details |
|---|---|
| Private IP assignment | Static private IP from your subnet; assigned for lifecycle of PE |
| Resource scope | Maps to a **specific instance** — not the whole service. Prevents data exfiltration to other resource instances. |
| Connection direction | Consumer-initiated only; service provider cannot initiate connections back |
| Cross-region | Consumer VNet in region A can connect to PaaS resource in region B |
| Cross-tenant | Works across different Microsoft Entra tenants |
| On-premises access | Reachable via ExpressRoute private peering or VPN tunnels |
| NSG/UDR/ASG support | All supported on PE subnets (with regional caveats — see Limitations) |
| Approval workflow | Auto-approve (RBAC-permissioned) or manual request/approve/reject |
| Public IP on service | Can be fully disabled after PE is configured |
| DNS requirement | **Mandatory** — must override public DNS to resolve to private IP |
| Deployment requirement | PE must be in same region and subscription as its VNet; backing PaaS resource can be in different region |

### Service Endpoint

| Capability | Details |
|---|---|
| How it works | Extends VNet private IP identity to Azure service over Azure backbone. Source IP seen by service switches from public to private. |
| Resource scope | Applies to **all instances** of the target service (e.g., all SQL Servers, all Storage accounts for all customers) |
| No private IP | DNS still resolves to public IP; traffic takes optimized backbone path but no NIC injected |
| DNS change required | No |
| On-premises access | Not natively — on-premises traffic still comes from public IPs |
| Data exfiltration protection | No — scope is entire service type, not specific instance |
| Cost | No extra charge |
| Setup complexity | Simple — single subnet toggle |
| Supported services | Storage, SQL Database, Cosmos DB, Key Vault, Service Bus, Event Hubs, App Service, Cognitive Services, Container Registry, Synapse, MariaDB, MySQL, PostgreSQL, others |

### VNet-Injected Deployment

Services deployed directly into a VNet subnet with subnet delegation. Full VNet membership — reachable by private IP, subject to NSGs and UDRs.

| When to use | Services |
|---|---|
| Service requires full VNet residence | AKS, SQL Managed Instance, App Service Environment, Azure Container Instances, Redis Cache (Premium), HDInsight, Azure Database for MySQL/PostgreSQL Flexible Server, Databricks, API Management (internal mode) |

Some services require a dedicated subnet (`Dedicated: Yes`) that cannot host customer VMs alongside them.

### Network Security Perimeter (NSP)

Controls **public internet access** to PaaS resources that live outside your VNet. Complementary to Private Link — NSP governs public traffic; Private Link governs VNet-to-PaaS traffic.

| Component | Description |
|---|---|
| Perimeter resource | Top-level logical boundary scoping PaaS resources |
| Profiles | Collections of access rules applied to associated resources |
| Access rules | Inbound: subscription-based or IP-based. Outbound: FQDN-based |
| Access modes | **Transition** (observe/learn existing patterns) → **Enforced** (deny all public traffic except explicit allow rules) |
| Intra-perimeter traffic | Resources within same NSP communicate freely without explicit rules |

**Onboarded NSP services (GA):** Azure Monitor (Log Analytics, App Insights), AI Search, Event Hubs, Key Vault, Service Bus, Storage, Microsoft Foundry

**Onboarded NSP services (Preview):** Cosmos DB, SQL DB, Azure OpenAI [VERIFY]

---

## When to use it

| Requirement | Recommended pattern |
|---|---|
| Prevent data exfiltration to other PaaS instances | Private Endpoint |
| Access PaaS from on-premises via ER or VPN | Private Endpoint |
| Access PaaS from a VNet with private IP required | Private Endpoint |
| Restrict PaaS access to specific VNet subnet (simple) | Service Endpoint (legacy) or Private Endpoint (preferred) |
| Service must be fully inside your VNet (e.g., AKS, SQL MI) | VNet injection / dedicated deployment |
| Control which public IP ranges / subscriptions can reach a PaaS resource | Network Security Perimeter |
| Prevent lateral movement between PaaS services via public internet | Network Security Perimeter (enforced mode) |
| Multi-tenant private access (consumers in different Entra tenants) | Private Link Service + Private Endpoint |

---

## When NOT to use it

| Anti-pattern | Notes |
|---|---|
| Private Endpoint without DNS configuration | Connections will resolve to the public IP and either fail or bypass the private path. DNS setup is mandatory. |
| Service Endpoint when data exfiltration protection is needed | Service Endpoints apply to entire service type — cannot scope to a specific resource instance |
| Service Endpoint for on-premises access | On-premises traffic via ER/VPN does not benefit from service endpoints; use Private Endpoint instead |
| NSP in Enforced mode without testing in Transition mode first | Enforced mode denies all public traffic by default — test in Transition mode to understand existing access patterns first |
| Private Endpoint for Bastion | Explicitly not supported |
| Private Link for IPv6-only traffic | Private Link Service supports IPv4 traffic only [VERIFY] |

---

## DNS Configuration for Private Endpoints

DNS is the most common failure point for Private Endpoint deployments.

| Scenario | Recommended approach |
|---|---|
| VNet-only access | Azure Private DNS Zone linked to the VNet; auto-registration via zone creation during PE provisioning |
| Hybrid (on-premises resolvers) | Azure DNS Private Resolver with inbound/outbound endpoints; forward private DNS zone queries from on-premises DNS servers |
| Testing only | Override host file on individual VMs (not for production) |

**How it works:** Azure creates a CNAME on the public DNS that redirects to the private domain name (e.g., `storageaccount.blob.core.windows.net` → `storageaccount.privatelink.blob.core.windows.net`). The Private DNS Zone resolves the `privatelink.*` name to the private IP. The client application URL does not change.

**Selected Private DNS Zone names:**

| Service | Private DNS Zone |
|---|---|
| Azure Storage (blob) | `privatelink.blob.core.windows.net` |
| Azure SQL Database | `privatelink.database.windows.net` |
| Azure Key Vault | `privatelink.vaultcore.azure.net` |
| Azure Event Hubs / Service Bus | `privatelink.servicebus.windows.net` |
| Azure Monitor (Log Analytics) | `privatelink.oms.opinsights.azure.com` / `privatelink.ods.opinsights.azure.com` |

> Full zone name list: see `raw/articles/private-link/private-endpoint-dns.md`

---

## Comparing Private Endpoints vs Service Endpoints

| Consideration | Service Endpoints | Private Endpoints |
|---|---|---|
| **Resource scope** | All instances of service type | Single specific resource instance |
| **Data exfiltration protection** | ❌ No | ✅ Yes |
| **On-premises access** | ❌ No (public IPs required) | ✅ Yes (via ER or VPN) |
| **Service can disable public IP** | ❌ No | ✅ Yes |
| **DNS changes required** | ❌ No | ✅ Yes |
| **Extra cost** | ❌ No | ✅ Yes — charged per hour + data processed [VERIFY] |
| **Setup complexity** | Low | Medium (DNS config required) |
| **Azure backbone routing** | ✅ Yes | ✅ Yes |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Private Endpoints per VNet (default) | 1,000 [VERIFY] | Subject to Azure Private Link limits |
| Private Endpoints per VNet (High Scale, opt-in) | 5,000 [VERIFY] | Peered-VNet aggregate: 20,000 |
| NAT IPs per Private Link Service | 8 (max) [VERIFY] | Minimum 1 must be maintained |
| PLS idle timeout | ~5 minutes (300 seconds) [VERIFY] | Configure TCP keepalives below this threshold |
| PLS: IPv4 only | No IPv6 support [VERIFY] | |
| Service Endpoints per VNet | No limit [VERIFY] | Individual services may limit subnet count |

---

## Related services

- [Private Link](../services/private-link.md) — the service implementing Private Endpoints and Private Link Service; detailed PE and PLS reference
- [Azure DNS](../services/dns.md) — Private DNS Zones and Private Resolver are required infrastructure for Private Endpoint DNS configuration
- [Azure Virtual Network](../services/virtual-network.md) — Service Endpoints configured at subnet level; Private Endpoints deploy as NICs into VNet subnets
- [Connectivity options](../decisions/connectivity-options.md) — hybrid connectivity patterns that feed into private PaaS access from on-premises
- [Network security design](network-security-design.md) — NSP, Zero Trust, and defense-in-depth patterns

---

## Source articles

- [What is Azure Private Link?](../../raw/articles/private-link/private-link-overview.md)
- [What is a private endpoint?](../../raw/articles/private-link/private-endpoint-overview.md)
- [What is Azure Private Link service?](../../raw/articles/private-link/private-link-service-overview.md)
- [What is a network security perimeter?](../../raw/articles/private-link/network-security-perimeter-concepts.md)
- [Azure virtual network service endpoints](../../raw/articles/virtual-network/virtual-network-service-endpoints-overview.md)
- [Integrate Azure services with virtual networks for network isolation](../../raw/articles/virtual-network/vnet-integration-for-azure-services.md)
- [What is Azure Private DNS?](../../raw/articles/dns/private-dns-overview.md)
- [Azure Private Endpoint private DNS zone values](../../raw/articles/private-link/private-endpoint-dns.md)
