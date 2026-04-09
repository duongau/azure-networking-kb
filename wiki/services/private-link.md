# Azure Private Link

> **Compiled:** 2025-07-30 | **Source articles:** 48 | **Status:** current

## What it is

Azure Private Link delivers private connectivity from a virtual network to Azure PaaS services, customer-owned services, and partner services — without traversing the public internet. It has two consumer-facing primitives: a **Private Endpoint** (a NIC with a VNet-private IP mapped to a specific PaaS resource instance) and a **Private Link Service** (your own service exposed behind a Standard Load Balancer so consumers can reach it via their own private endpoints). Traffic flows exclusively over the Microsoft backbone. Both primitives are GA.

> **Note:** A companion feature, **Network Security Perimeter (NSP)**, wraps PaaS resources that don't live inside a VNet with a logical public-access control boundary (enforced-mode deny-by-default). NSP is in GA for selected services and Public Preview for others — see the NSP section below.

---

## Key capabilities

| Capability | Details |
|---|---|
| **Private Endpoint** | NIC assigned a static private IP from a subnet; maps to one PaaS resource instance. Connections are consumer-initiated only (unidirectional). |
| **Private Link Service (PLS)** | Expose your own service behind a Standard LB to consumers across VNets, subscriptions, and Entra tenants. Uses NAT IP addresses to prevent IP conflicts. |
| **PLS Direct Connect** | Public Preview. Connects to any privately routable destination IP — no LB required. Available in limited regions. |
| **Cross-region reach** | Consumer VNet can be in any region; PaaS resource can be in a different region. |
| **Multi-tenant support** | PLS and private endpoints work across different Microsoft Entra tenants. |
| **Approval workflow** | Auto-approve (RBAC-permissioned) or manual request → approve/reject/disconnect. |
| **Alias-based sharing** | PLS generates a globally unique alias (`Prefix.{GUID}.{region}.azure.privatelinkservice`) for offline sharing. |
| **Network policy support** | NSG, UDR, ASG all supported on PE subnets (with regional and feature caveats — see limits). |
| **High Scale Private Endpoints** | Opt-in feature raising per-VNet limit from 1,000 → 5,000 PEs, and peered-VNet aggregate from 4,000 → 20,000. |
| **SNAT disable for NVA traffic** | Tag NVA NIC (`disableSnatOnPL=true`) to bypass SNAT requirement for PE-destined traffic through an NVA. |
| **TCP Proxy v2** | PLS can surface consumer source IP + LinkID to the backend via proxy protocol v2 header. |
| **Azure Monitor integration** | Metrics: Bytes In / Out (PE and PLS), NAT port availability (PLS). Logs via diagnostic settings. |
| **Network Security Perimeter (NSP)** | Public-access control boundary for PaaS resources outside VNets; inbound (IP/subscription) and outbound (FQDN) rules. |
| **Zone resilience** | Private Link and VNets span Availability Zones; zone resilience of the backing resource determines end-to-end HA. |

---

## When to use it

| Scenario | Use |
|---|---|
| Access Azure PaaS (Storage, SQL, Key Vault, etc.) without public internet exposure | Private Endpoint to the PaaS resource |
| Expose your internal service to partner/customer tenants or subscriptions privately | Private Link Service behind Standard LB |
| On-premises workloads need private access to Azure PaaS over ExpressRoute / VPN | Private Endpoint (no need for ExpressRoute Microsoft peering) |
| Prevent data exfiltration: isolate to a specific resource instance (not the whole service) | Private Endpoint (mapped to instance, not service) |
| Regulatory / compliance requirement to never traverse public internet for sensitive data | Private Endpoint + private DNS zone |
| Restrict public internet access to PaaS resources not inside a VNet | Network Security Perimeter (enforced mode) |
| Inspection / logging of PE traffic through an NVA without SNAT asymmetry | `disableSnatOnPL` tag on NVA NIC |

---

## When NOT to use it

| Anti-pattern | Why | Alternative |
|---|---|---|
| You need to expose a service publicly with optional private channel | PE is private-only; public access is a separate concern | Service-level firewall rules + PE together |
| Basic Load Balancer backs your service | PLS requires **Standard** LB only | Upgrade LB SKU first |
| IPv6-only or mixed IPv6 workloads | PLS supports IPv4 only | N/A — IPv6 not supported by PLS |
| You need NSG flow logs for PE inbound traffic | Not supported | Azure Monitor metrics (Bytes In/Out) |
| Backend pool configured by IP address on Standard LB | PLS only supports NIC-based backend pools | Reconfigure LB to NIC-based backend |
| Applications with long-lived idle TCP connections through PLS (>5 min) | PLS idle timeout ~300 s | Implement TCP keepalives < 300 s in the application |
| You only need to control public internet access to PaaS (not private VNet access) | NSP is the right tool, not PE | Network Security Perimeter |

---

## SKUs and tiers

Private Link has no traditional SKU tiers — it is a flat GA service. Relevant tier dependencies:

| Component | Requirement / Note | Key limit |
|---|---|---|
| **Private Endpoint** | Any VNet subnet; PE must be in same region+subscription as VNet | 1,000 PEs per VNet [VERIFY]; 1,000 PEs per subscription [VERIFY] |
| **Private Link Service** | Standard Load Balancer (NIC-based backend) only | Up to 8 NAT IP addresses per PLS [VERIFY] |
| **High Scale Private Endpoints (opt-in)** | Set `privateEndpointVNetPolicies=Basic` on VNet; triggers one-time connection reset | 5,000 PEs per VNet; 20,000 across peered VNets [VERIFY] |
| **Network Security Perimeter** | GA for selected services; Public Preview for Cosmos DB, SQL DB, Azure OpenAI | See NSP section |
| **PLS Direct Connect** | Public Preview; limited region availability | See availability.md |
| **Azure Container Registry** | Requires Premium tier for PE support | [VERIFY] |
| **Azure Service Bus** | Requires Premium tier for PE support | [VERIFY] |
| **Azure SignalR** | Requires Standard tier or above for PE support | [VERIFY] |
| **Azure App Service** | Requires Basic, Standard, Premium v2/v3, Isolated v2, or Functions Premium plan | [VERIFY] |
| **Azure DB for PostgreSQL Single Server** | Requires General Purpose or Memory Optimized pricing tier | [VERIFY] |
| **Azure Storage** | GPv2 account only (not GPv1, Blob storage) | [VERIFY] |

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| Private endpoints per VNet (standard) | 1,000 [VERIFY] | Upgrade to High Scale to raise limit |
| Private endpoints per VNet (High Scale) | 5,000 [VERIFY] | Opt-in; one-time connection reset on enable/disable |
| Private endpoints across peered VNets (standard, silent limit) | 4,000 [VERIFY] | Exceeding silently degrades connection health |
| Private endpoints across peered VNets (High Scale) | 20,000 [VERIFY] | |
| NAT IP addresses per Private Link Service | 8 [VERIFY] | Each NAT IP adds more TCP port capacity |
| PLS per Standard Load Balancer | See Azure limits reference [VERIFY] | Multiple PLS per LB via different frontend IPs |
| ASG members per NSG on PE subnet | 50 [VERIFY] | Exceeding 50 causes connection failures |
| NSG destination port ranges product | ≤ 250,000 (sources × destinations × port ranges) | e.g., 100×100×100 = 1M → invalid |
| PLS idle timeout | ~300 seconds (5 minutes) [VERIFY] | Use TCP keepalives < 300 s |
| PLS alias format | `Prefix.{GUID}.{region}.azure.privatelinkservice` | Immutable once created |
| Connection states | Approved, Pending, Rejected, Disconnected | Only Approved state sends traffic |
| Monitoring Bytes In/Out | Unavailable for High Scale PEs | Use other observability channels |
| On-premises PE billing (High Scale) | Aggregate billed on gateway VNet | No total-cost change, cost center shifts |

**Limits reference:** `../azure-resource-manager/management/azure-subscription-service-limits#azure-private-link-limits` [VERIFY — external link]

---

## DNS configuration

DNS is the most operationally complex aspect of Private Link. Getting this wrong silently breaks connectivity.

| DNS option | Use case | Notes |
|---|---|---|
| **Host file override** | Testing only | Not scalable |
| **Azure Private DNS Zone** | Production standard | Link zone to VNet; auto-generates A records on PE creation when recommended zone name is used |
| **Azure Private DNS Resolver** | Hybrid / custom DNS topology | Forwards conditional queries to private zones from on-premises |

**Key rules:**
- Every Azure service has a recommended private DNS zone name (e.g., `privatelink.blob.core.windows.net`). Use the recommended names or auto-integration won't work.
- Azure creates a CNAME on public DNS → override it by pointing the FQDN to the PE private IP via private zone.
- Do **not** share one private DNS zone across multiple PaaS service types.
- Do **not** use a zone that's also resolving public endpoints without configuring DNS fallback (`privatelink` subdomain zones return NXDOMAIN for resources without a PE).
- Azure File Shares must be remounted if switching from public endpoint.
- The network interface on a PE carries the FQDN and private IP — use this as the source of truth.

**Selected DNS zone names** (commercial cloud):

| Service | Subresource | Private DNS Zone |
|---|---|---|
| Azure Blob Storage | blob | `privatelink.blob.core.windows.net` |
| Azure Files | file | `privatelink.file.core.windows.net` |
| Azure SQL Database | sqlServer | `privatelink.database.windows.net` |
| Azure Cosmos DB | SQL | `privatelink.documents.azure.com` |
| Azure Key Vault | vault | `privatelink.vaultcore.azure.net` |
| Azure Event Hubs / Service Bus | namespace | `privatelink.servicebus.windows.net` |
| Azure Container Registry | registry | `privatelink.azurecr.io` |
| Azure Kubernetes Service | management | `privatelink.{regionName}.azmk8s.io` |
| Azure Machine Learning workspace | amlworkspace | `privatelink.api.azureml.ms`, `privatelink.notebooks.azure.net` |
| Foundry Tools | account | `privatelink.cognitiveservices.azure.com`, `privatelink.openai.azure.com` |
| Azure Synapse Analytics | Sql / SqlOnDemand | `privatelink.sql.azuresynapse.net` |

> Full DNS zone table: see `raw/articles/private-link/private-endpoint-dns.md` (43 KB — not fully read; partial read covers commercial cloud).

---

## Network Security Perimeter (NSP)

NSP is a logical public-access control boundary around PaaS resources **outside** VNets. It complements (not replaces) private endpoints.

| Component | Description |
|---|---|
| Profile | Collection of inbound/outbound access rules |
| Resource association | Attaches a PaaS resource to the perimeter |
| Access modes | **Transition** (default, audit/learning) → **Enforced** (deny-all public by default) |
| Inbound rule types | Subscription-based, IP-based |
| Outbound rule types | FQDN-based |
| Diagnostic logs | Perimeter-scoped; Log Analytics workspace must be in supported Azure Monitor region |

**NSP-onboarded services (GA):** Azure Monitor, Azure AI Search, Event Hubs, Key Vault, Service Bus, Storage, Microsoft Foundry  
**NSP-onboarded services (Public Preview — not for production):** Cosmos DB, SQL DB, Azure OpenAI  

> [!IMPORTANT] NSP SAS token authentication is not supported for intra-perimeter or subscription-based inbound rules. Use alternative auth methods.  
> Azure Backup is **not supported** with Storage Accounts associated to NSP.

---

## Supported PaaS services (abbreviated)

Over 60 Azure services support private endpoints. Key categories:

| Category | Notable services |
|---|---|
| **Databases** | Azure SQL DB, SQL Managed Instance, Cosmos DB (SQL/Mongo/Cassandra/Gremlin/Table), PostgreSQL Flexible/Single, MySQL, MariaDB, Redis Cache |
| **Storage** | Blob (GPv2 only), Files, Queues, Tables, Data Lake Gen2, Azure File Sync |
| **Compute / Containers** | AKS (API), Container Registry (Premium), Azure Batch, Container Apps (Preview) |
| **Security** | Key Vault, Key Vault HSM, App Configuration, Application Gateway |
| **Integration / Messaging** | Event Hubs, Service Bus (Premium), Event Grid, API Management, Logic Apps, Relay |
| **AI / ML** | Azure Machine Learning, Azure AI Search, Foundry Tools, Azure OpenAI, Azure Bot Service |
| **Analytics** | Synapse Analytics, Data Factory, HDInsight, Data Explorer, Databricks, Power BI |
| **DevOps / Management** | Azure Automation, Azure Backup, Azure Monitor Private Link Scope, Microsoft Purview |
| **IoT** | IoT Hub, Device Provisioning Service, Digital Twins |
| **Web** | App Service, Static Web Apps, SignalR, Azure Functions |
| **Identity / Governance** | Resource Management Private Links |
| **Custom** | Private Link Service (your own service behind Standard LB) |

Full table with resource types and sub-resources: `raw/articles/private-link/private-endpoint-overview.md` lines 70–136.

---

## RBAC permissions

| Role | Scope |
|---|---|
| Owner / Contributor / Network Contributor | Sufficient for PE and PLS deployment |

**Minimum custom permissions for Private Endpoint:**
`Microsoft.Network/virtualNetworks/read`, `subnets/read`, `subnets/join/action`, `privateEndpoints/read`, `privateEndpoints/write`, `locations/availablePrivateEndpointTypes/read`

**Minimum custom permissions for Private Link Service:**
All PE permissions + `privateLinkServices/read`, `privateLinkServices/write`, `privateLinkServices/privateEndpointConnections/read+write`, `networkSecurityGroups/join/action`, `loadBalancers/read+write`

**Approval auto vs. manual:**

| Method | Required permission |
|---|---|
| Automatic | Includes `Microsoft.[ServiceProvider]/[resourceType]/privateEndpointConnectionsApproval/action` |
| Manual | Does not require approval action — resource owner approves in portal |

> Also register `Microsoft.Network` and the specific resource provider (e.g., `Microsoft.Sql`) at the subscription level.

---

## Known limitations

### NSG
- Effective routes and security rules not visible in portal for PE NIC.
- NSG flow logs not supported for inbound PE traffic.
- Max 50 ASG members per NSG on PE subnet.
- NSG destination port ranges product capped at 250,000.
- **Unavailable in:** West India, Australia Central 2, South Africa West, Brazil Southeast, all Government regions, all China regions.

### UDR
- SNAT recommended when routing PE traffic through NVA (use `disableSnatOnPL=true` tag to opt out).
- **UDR unavailable in:** West India, Australia Central 2, South Africa West, Brazil Southeast.

### ASG
- **ASG unavailable in:** West India, Australia Central 2, South Africa West, Brazil Southeast.

### Static IP on Private Endpoint
- Static IP configuration not supported for: AKS, Application Gateway, HDInsight, Recovery Services Vaults, third-party PLS.

### Private Link Service
- Standard LB only (not Basic). NIC-based backend pools only (not IP-based).
- IPv4 only. TCP + UDP only.
- Idle timeout ~300 s — applications must use TCP keepalives.
- TCP Proxy v2 activates for all LBs/backend VMs sharing the LB; configure on all PLS resources sharing a backend pool.

### High Scale Private Endpoints
- Bytes In/Out metrics unavailable.
- Baremetal subnet access from HSPE-enabled peered VNet not supported.
- Not supported in Mooncake (China) or Azure Government regions.
- Downgrade requires reducing PE count below standard limit first.
- Enable/disable triggers one-time connection reset — use a maintenance window.

---

## Cost model

| Billing component | Model |
|---|---|
| Private Endpoint | Per endpoint, per hour [VERIFY — see pricing page] |
| Data processing | Per GB processed through PE [VERIFY] |
| Cross-region traffic | Per GB transferred between regions [VERIFY] |
| Private Link Service | Per service, per hour [VERIFY] |

**Cost optimization highlights:**
- Use hub-and-spoke to share PEs across workloads (one PE per hub for common services).
- Clean up unused/Disconnected PEs — you pay per hour regardless of traffic.
- High Scale PEs change on-premises billing to gateway VNet aggregate (no total cost change).
- Azure Monitor integration included at no extra charge.

> **VERIFY:** All prices — source: [Azure Private Link pricing](https://azure.microsoft.com/pricing/details/private-link/)  
> **SLA:** [SLA for Azure Private Link](https://azure.microsoft.com/support/legal/sla/private-link/v1_0/) [VERIFY]

---

## Monitoring and troubleshooting

| Signal | Source | Notes |
|---|---|---|
| Bytes In / Out (PE) | Azure Monitor Metrics | ~10 min delay |
| Bytes In / Out (PLS) | Azure Monitor Metrics | |
| NAT port availability (PLS) | Azure Monitor Metrics | |
| Resource logs | Diagnostic settings → Log Analytics / Storage / Event Hub | |
| Activity log | Azure Monitor (auto-collected) | Subscription-level events |
| NSP access logs | Diagnostic settings on NSP resource | Log Analytics workspace must be in supported region |

**Troubleshooting checklist:**
1. Confirm connection state = **Approved** in Private Link Center.
2. Verify FQDN resolves to PE private IP (not public IP).
3. Check DNS: private zone linked to correct VNet; correct zone name used.
4. Use Azure Monitor Metrics (Bytes In/Out) to confirm traffic flow.
5. Use Network Watcher **Connection Troubleshoot** → Test by FQDN (port 443 for Storage/Cosmos, 1336 for SQL).
6. For NVA path issues: check SNAT symmetry; consider `disableSnatOnPL=true` tag.
7. For PLS issues: confirm TCP Proxy v2 configured on all PLS sharing the same LB backend.

---

## Related services

- [Azure Virtual Network](../services/virtual-network.md) — PE must be deployed in a VNet subnet; hub-spoke topologies share PEs.
- [Azure DNS](../services/dns.md) — Private DNS zones are the standard mechanism for PE DNS resolution; Azure Private DNS Resolver handles hybrid scenarios.
- [Azure Load Balancer](../services/load-balancer.md) — Standard LB is required to front your service for Private Link Service.
- [Azure Firewall](../services/azure-firewall.md) — Use with UDR to inspect PE traffic; SNAT required unless `disableSnatOnPL` tag applied.
- [ExpressRoute](../services/expressroute.md) — On-premises access to PEs via private peering; no Microsoft peering needed.
- [VPN Gateway](../services/vpn-gateway.md) — On-premises access to PEs via VPN tunnels.
- [Azure Bastion](../services/bastion.md) — Related in that both eliminate public internet exposure; Bastion is for VM RDP/SSH, PE is for PaaS.

---

## Source articles

| Article | Path |
|---|---|
| What is Azure Private Link? | `raw/articles/private-link/private-link-overview.md` |
| What is a private endpoint? | `raw/articles/private-link/private-endpoint-overview.md` |
| What is Azure Private Link service? | `raw/articles/private-link/private-link-service-overview.md` |
| Azure Private Link availability | `raw/articles/private-link/availability.md` |
| Private Endpoint DNS zone values | `raw/articles/private-link/private-endpoint-dns.md` |
| What is a network security perimeter? | `raw/articles/private-link/network-security-perimeter-concepts.md` |
| Azure Private Link cost optimization | `raw/articles/private-link/private-link-cost-optimization.md` |
| Azure RBAC permissions for Private Link | `raw/articles/private-link/rbac-permissions.md` |
| Monitor Azure Private Link | `raw/articles/private-link/monitor-private-link.md` |
| Troubleshoot Private Endpoint connectivity | `raw/articles/private-link/troubleshoot-private-endpoint-connectivity.md` |
| Increase Private Endpoint VNet limits | `raw/articles/private-link/increase-private-endpoint-vnet-limits.md` |
| Disable SNAT for PE traffic through NVA | `raw/articles/private-link/private-link-disable-snat.md` |
| Private endpoint DNS integration | `raw/articles/private-link/private-endpoint-dns-integration.md` |
| Monitor Private Link reference | `raw/articles/private-link/monitor-private-link-reference.md` |
| *(34 additional articles — how-tos, tutorials, NSP creation, cross-subscription approval, Firewall inspection, etc.)* | `raw/articles/private-link/` |
```

---

## Index update

Update `wiki/index.md` row for Private Link:

| Service | Wiki page | Status | Last compiled |
|---|---|---|---|
| Private Link | [private-link.md](services/private-link.md) | ✅ current | 2025-07-30 |

---

## Decision log — `.squad/decisions/inbox/atlas-private-link.md`

```markdown
# Atlas decisions — private-link compilation
Date: 2025-07-30

## D1 — DNS section depth
Decision: Included abbreviated DNS zone table (commercial cloud only) rather than full 43 KB
file. Full file was too large to read in one pass; partial read (120 lines) covered AI/ML,
Analytics, Compute, Containers, Databases. Remaining categories (Security, Storage, Web,
Integration, Gov cloud, China cloud) not included in the table.
Action needed: Human to verify completeness of DNS table, or run a second read pass on
private-endpoint-dns.md lines 120-end.

## D2 — NSP limits include file not expanded
Decision: network-security-perimeter-concepts.md line 148 references an include file
`../../includes/network-security-perimeter-limits.md` that is not in the raw/ directory.
NSP limits table therefore not compiled. Marked as gap.
Action needed: Ingest `includes/network-security-perimeter-limits.md` into raw/ and recompile
NSP limits section.

## D3 — 34 articles not read
Decision: Compiled from 14 of 48 articles (core conceptual + limits + DNS + NSP + cost +
RBAC + monitoring + troubleshooting). Remaining 34 are tutorials, how-tos, and procedural
guides (create-private-endpoint-*, create-private-link-service-*, tutorial-*, nsp-creation-*).
These do not contain additional conceptual facts beyond what was captured.
Action: No action needed unless a specific tutorial contains a limit or constraint not found
in the overview articles.

## D4 — Numeric limits tagged [VERIFY]
All numeric limits (per-VNet PE counts, NAT IPs, ASG members, etc.) sourced from article
text and tagged [VERIFY]. Authoritative source is the Azure subscription limits page
(external, not in raw/).
