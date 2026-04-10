# Private Access to PaaS Services: Decision Guide

> **Compiled:** 2025-07-31 | **Sources:** wiki/services/private-link.md, wiki/services/virtual-network.md, wiki/services/dns.md, wiki/services/nat-gateway.md, raw/articles/networking/fundamentals/networking-overview.md | **Status:** ✅ current

---

## The three patterns

Azure provides three distinct mechanisms for giving workloads private access to PaaS services. Each solves a different problem and carries different tradeoffs on cost, scope, DNS complexity, and on-premises reachability.

| Pattern | Core mechanism | Introduced for |
|---|---|---|
| **Private Endpoint** | Injects a NIC with a private IP from your VNet directly into a specific PaaS resource instance. DNS resolves the service FQDN to that private IP. | Full network-private access — traffic never leaves Microsoft backbone, public endpoint can be disabled. |
| **Service Endpoint** | Extends VNet identity over optimized backbone routes to an Azure service. Source IP at the service switches from public to VNet private. | Simpler, free route-optimization + ACL locking without DNS or IP address changes. |
| **VNet Integration (outbound)** | Delegates a subnet to a compute PaaS service (App Service, Container Apps, Functions) so that service can *originate* outbound connections into the VNet. | App-tier PaaS services calling backend PaaS — not for exposing a resource privately, but for letting an app *reach* a privately exposed resource. |

> **Preferred option for new designs:** Private Endpoints. Both the Azure Virtual Network wiki page and Azure docs state explicitly: "Preferred over service endpoints for new designs."

---

## Quick-pick matrix

| Requirement | Private Endpoint | Service Endpoint | VNet Integration |
|---|---|---|---|
| **Block all public internet access to PaaS** | ✅ Disable public endpoint on the PaaS resource + NSG on PE subnet | ⚠️ Can lock service to VNet via ACL, but the public IP still exists — endpoint not truly eliminated | ❌ Not applicable — this is outbound from compute, not inbound to PaaS |
| **On-premises access via ExpressRoute / VPN** | ✅ PE is a private IP in the VNet — reachable over ER private peering or VPN tunnel | ❌ VNet identity does not extend over ER/VPN — on-prem traffic arrives as public IP and is rejected | ❌ Not applicable |
| **Cross-region access** | ✅ Consumer VNet and PaaS resource can be in different regions | ⚠️ Service endpoint is regional — must be enabled per region; cross-region behavior varies by service | ⚠️ Regional subnet delegation only |
| **Cross-subscription / cross-tenant** | ✅ PE supports cross-subscription and cross-Entra-tenant (via manual approval workflow) | ❌ Tied to the VNet's subscription | ❌ Not applicable |
| **DNS resolution change required** | ✅ Yes — private DNS zone required (`privatelink.*`); split-horizon setup | ❌ No DNS change — service still resolves to public IP; routing + ACL enforced at service side | ❌ No DNS change for the integration itself |
| **NVA / firewall inspection of traffic** | ✅ Supported via UDR + SNAT (or `disableSnatOnPL=true` to skip SNAT) | ⚠️ Traffic goes directly to backbone — NVA inspection not in the path by default | ⚠️ Depends on how VNet routing is configured |
| **Cost-sensitive workload** | ⚠️ PE: per endpoint-hour + per-GB charge [VERIFY] | ✅ Free — no extra charge for service endpoints | ⚠️ No charge for integration itself; subnet and associated PE on destination incur normal costs |
| **Supported by all Azure PaaS services** | ⚠️ 60+ services supported — broadest coverage, but not 100% | ❌ ~10 service families supported — Storage, SQL, Cosmos DB, Key Vault, Service Bus, Event Hubs, App Service, Container Registry, PostgreSQL, MySQL | ⚠️ Limited to compute PaaS outbound (App Service, Container Apps, Functions, Logic Apps, API Management) |
| **Prevent data exfiltration to other tenants** | ✅ PE is bound to a specific resource instance — can't be redirected to another tenant's resource | ⚠️ Service endpoint + policies (Storage, SQL only) can restrict to specific resources — weaker than PE | ❌ Not applicable |
| **Hub-spoke shared access** | ✅ One PE in hub is reachable by all spokes (peering + DNS must be configured) | ❌ Must be enabled per subnet in each spoke | ❌ Per-app integration per spoke |

---

## Option deep dives

### Private Endpoints

**How it works:**

When you create a private endpoint for a PaaS resource, Azure provisions a NIC in a subnet you specify. That NIC gets a static private IP from your VNet address space. Azure creates a DNS A record mapping the service's FQDN to that private IP in the corresponding `privatelink.*` Private DNS Zone. All connections from your VNet (or any network that can reach the VNet) to that service FQDN now terminate at that private IP — never traversing the internet.

The connection is *consumer-initiated only* (unidirectional). The PaaS service cannot initiate connections back through the private endpoint.

**Key capabilities:**

| Capability | Detail |
|---|---|
| Cross-region | Consumer VNet and PaaS resource instance can be in different Azure regions |
| Cross-tenant | Works across Microsoft Entra tenants via manual approval workflow |
| On-premises accessible | PE private IP is routable over ExpressRoute private peering or VPN Site-to-Site — no Microsoft peering required |
| NSG/UDR/ASG support | Supported on PE subnets (with regional caveats — unavailable in West India, Australia Central 2, South Africa West, Brazil Southeast) |
| NVA inspection | Route PE traffic through NVA via UDR; SNAT is recommended to maintain flow symmetry; opt out with `disableSnatOnPL=true` tag on NVA NIC |
| High Scale (opt-in) | Set `privateEndpointVNetPolicies=Basic` on VNet to raise per-VNet limit from 1,000 → 5,000 [VERIFY]; triggers one-time connection reset |
| Resource instance isolation | PE maps to *one specific resource instance* — not the whole service; prevents lateral data exfiltration |
| Approval workflow | Auto-approve (requires RBAC `approval` action) or manual (resource owner approves in portal) |

**DNS requirements:**

Every private endpoint requires a corresponding Azure Private DNS Zone to function correctly. The FQDN continues to resolve to the public IP on the internet (Microsoft does not remove the public CNAME). Inside your VNet, the private zone overrides that resolution to return the PE's private IP. See the [DNS: the critical piece](#dns-the-critical-piece) section for full details.

**Limitations:**

- No transitive routing: a PE in VNet-A is not reachable from VNet-B unless VNet-B is peered to VNet-A (or connected via gateway/hub) — peering alone is not sufficient without also sharing DNS resolution
- One private IP per PE — high-cardinality deployments (many PaaS resources) require many PEs
- DNS complexity: each service type has its own private zone name; some services (AKS, Azure ML) require multiple zones per PE
- NSG flow logs not supported for inbound PE traffic
- High Scale PEs do not emit Bytes In/Out metrics
- Static IP not supported for: AKS, Application Gateway, HDInsight, Recovery Services Vaults, third-party PLS
- Cost: per-hour billing + per-GB data processing [VERIFY]

**Services requiring specific tiers to support PE:**

| Service | Minimum tier for PE |
|---|---|
| Azure Container Registry | Premium [VERIFY] |
| Azure Service Bus | Premium [VERIFY] |
| Azure SignalR | Standard or above [VERIFY] |
| Azure App Service | Basic, Standard, Premium v2/v3, Isolated v2, or Functions Premium [VERIFY] |
| Azure Storage | GPv2 accounts only (not GPv1, not classic Blob storage) [VERIFY] |
| Azure DB for PostgreSQL Single Server | General Purpose or Memory Optimized [VERIFY] |

---

### Service Endpoints

**How it works:**

Service endpoints add a route entry to the subnet's effective route table that sends traffic destined for the PaaS service's published IP ranges directly over the Azure backbone (optimized path) instead of through the default internet gateway. Simultaneously, the PaaS service sees the source IP of the connection change from the VNet's public outbound IP to the VNet's **private** RFC 1918 address. You then configure the PaaS service's firewall/network ACL to allow only connections originating from your VNet's private address space.

No NIC is injected. No DNS change occurs. The PaaS service continues to have a public FQDN resolving to a public IP. The restriction is enforced at the service's network ACL layer.

**Key capabilities:**

| Capability | Detail |
|---|---|
| Free | No extra charge — included in VNet |
| No DNS change | Service FQDN continues resolving to public IP; no private zone required |
| Simple to enable | Per-subnet toggle in portal, CLI, or policy |
| Service endpoint policies | Restrict access to specific storage accounts or SQL servers (Storage and SQL only) [VERIFY scope] |
| Backbone routing | Traffic stays on Microsoft backbone even though public IP is used |
| All regions | Works in all Azure regions without regional feature caveats |

**Supported services (from source articles):**

Storage, Azure SQL Database, Azure Cosmos DB, Azure Key Vault, Azure Service Bus, Azure Event Hubs, App Service, Azure Container Registry, Azure Database for PostgreSQL, Azure Database for MySQL, Azure Database for MariaDB

> ⚠️ This is an exhaustive list from source articles — Service Endpoints do not support the full 60+ services that Private Endpoints cover.

**Limitations — these are hard disqualifiers:**

- ❌ **Not accessible from on-premises.** VNet identity does not extend over ExpressRoute or VPN connections. On-premises traffic arrives at the PaaS service with a public IP and is blocked by the VNet-only ACL.
- ❌ **Not cross-tenant.** Service endpoint policies and ACLs are scoped to VNets within the same subscription.
- ❌ **Public IP still exists.** The PaaS service's public endpoint is not eliminated — it can still be reached by anyone with network access unless the ACL explicitly denies all other sources.
- ❌ **No resource-instance isolation.** You can lock to a VNet but not to a specific storage account (unless using Service Endpoint Policies — Storage + SQL only).
- ❌ **Not in the NVA traffic path by default.** The backbone routing bypasses NVAs unless UDRs are configured specifically to override the service endpoint route.
- ❌ **Must be enabled per subnet.** No hub-and-spoke sharing — every spoke subnet that needs access must enable the endpoint.

---

### VNet Integration (outbound)

**How it works:**

VNet Integration allows a compute PaaS service (primarily App Service, Container Apps, Azure Functions, Logic Apps Standard, API Management) to *originate* outbound connections into a delegated subnet. The compute service's outbound traffic appears to come from the VNet's private address space, enabling it to reach resources that are VNet-private — including other VMs, Private Endpoints on PaaS services, or NVAs.

VNet Integration is **outbound only**. It does not expose the App Service privately — that requires a Private Endpoint on the App Service itself (inbound). The two are independent and can be combined.

A dedicated subnet must be delegated to the compute service (e.g., `Microsoft.Web/serverFarms` for App Service). The subnet cannot be shared with other resources. Minimum subnet size requirements apply [VERIFY — /26 or /28 depending on service and plan].

**When to use vs Private Endpoint:**

| Scenario | Pattern |
|---|---|
| App Service needs to call Azure SQL privately | VNet Integration (outbound from App Service) + Private Endpoint on SQL |
| External clients need to reach App Service privately | Private Endpoint on App Service (inbound) |
| App Service needs outbound internet access | VNet Integration + NAT Gateway on the delegated subnet |
| App Service calls Storage, SQL, Key Vault privately | VNet Integration (outbound) + Private Endpoint on each PaaS resource |

> ⚠️ **Source coverage note:** VNet Integration specifics (subnet sizing, delegation names, regional VNet Integration vs. Gateway-required VNet Integration) are only briefly covered in the source articles read for this compilation. The `vnet-integration-for-azure-services.md` article is listed in the VNet wiki page source list but was not fully read. Details above are sourced from `virtual-network.md` (subnet delegation section), `nat-gateway.md` (App Service VNet-integrated workloads), and the networking overview. Verify subnet size requirements and plan tier prerequisites against the App Service VNet Integration documentation before implementation.

---

## Decision flowchart (text)

```
START: Do you need private access from a workload to a PaaS service?
│
├─ Does the access need to originate from on-premises (ER or VPN)?
│   └─ YES → Private Endpoint only. Service Endpoints don't work on-prem.
│
├─ Is the PaaS resource owned by a different tenant / third party?
│   └─ YES → Private Endpoint only. Cross-tenant supported; Service Endpoints are not.
│
├─ Do you need to completely eliminate the public endpoint?
│   └─ YES → Private Endpoint + disable public access on PaaS resource.
│             Service Endpoints leave the public IP in place.
│
├─ Is the workload App Service / Container Apps / Functions calling a PaaS backend?
│   └─ YES → VNet Integration (outbound from compute) + Private Endpoint on the PaaS
│             destination. These two work together; neither alone is sufficient.
│
├─ Is the PaaS service NOT on the Service Endpoint supported list?
│   (e.g., AKS, Azure ML, IoT Hub, Cosmos DB Gremlin, Azure OpenAI, etc.)
│   └─ YES → Private Endpoint. Service Endpoints don't support that service.
│
├─ Are you cost-sensitive AND the workload is intra-VNet only AND on-prem access
│  is not required AND the service is on the SE supported list?
│   └─ YES → Service Endpoint is viable. Consider PE for future-proofing.
│
└─ Default for new designs → Private Endpoint.
   Azure docs explicitly state PEs are "preferred over service endpoints for new designs."
```

---

## DNS: the critical piece

DNS is the hardest operational aspect of Private Endpoints. Getting it wrong produces silent failures: the service is reachable on the public endpoint while you believe traffic is going privately.

### Why it's complex

When Azure creates a Private Endpoint for a service, the service's public DNS record becomes a CNAME pointing to a `privatelink.*` subdomain:

```
mystorageaccount.blob.core.windows.net
  → mystorageaccount.privatelink.blob.core.windows.net  (CNAME, public DNS)
    → [public IP]                                         (A record, public DNS)
```

To redirect this to the PE's private IP, you create an Azure Private DNS Zone named exactly `privatelink.blob.core.windows.net`, link it to your VNet, and let Azure auto-create an A record:

```
mystorageaccount.privatelink.blob.core.windows.net → 10.1.0.5  (PE private IP, private zone)
```

When a client in the linked VNet resolves `mystorageaccount.blob.core.windows.net`, Azure DNS intercepts at the CNAME and looks up `mystorageaccount.privatelink.blob.core.windows.net` in the private zone — returning `10.1.0.5`. Internet clients still get the public IP. This is split-horizon DNS.

### Private DNS zone names by service

| Service | Subresource | Private DNS Zone Name |
|---|---|---|
| Azure Blob Storage | `blob` | `privatelink.blob.core.windows.net` |
| Azure Files | `file` | `privatelink.file.core.windows.net` |
| Azure Queue Storage | `queue` | `privatelink.queue.core.windows.net` |
| Azure Table Storage | `table` | `privatelink.table.core.windows.net` |
| Azure Data Lake Gen2 | `dfs` | `privatelink.dfs.core.windows.net` |
| Azure SQL Database | `sqlServer` | `privatelink.database.windows.net` |
| Azure Cosmos DB (SQL) | `Sql` | `privatelink.documents.azure.com` |
| Azure Key Vault | `vault` | `privatelink.vaultcore.azure.net` |
| Azure Event Hubs / Service Bus | `namespace` | `privatelink.servicebus.windows.net` |
| Azure Container Registry | `registry` | `privatelink.azurecr.io` |
| Azure Kubernetes Service | `management` | `privatelink.{regionName}.azmk8s.io` |
| Azure Machine Learning | `amlworkspace` | `privatelink.api.azureml.ms` + `privatelink.notebooks.azure.net` |
| Azure AI / Foundry Tools | `account` | `privatelink.cognitiveservices.azure.com` + `privatelink.openai.azure.com` |
| Azure Synapse Analytics | `Sql` / `SqlOnDemand` | `privatelink.sql.azuresynapse.net` |

> ⚠️ The full list contains 43+ zone names. The above covers the most common services. Source: `raw/articles/private-link/private-endpoint-dns.md` (partial read — commercial cloud only; Gov and China cloud zones not included here). [VERIFY completeness against full DNS zone reference]

### Rules for private DNS zones

1. **Use exact Microsoft-recommended zone names.** Auto-integration with PE creation only works with the exact recommended name. Custom names break the auto-A-record creation.
2. **One zone per service type.** Do not co-host multiple service types in one zone. Each `privatelink.*` zone is scoped to one service family.
3. **Link the zone to every VNet that needs resolution.** A zone not linked to a VNet is invisible to resources in that VNet — even if the VNet is peered to one that is linked.
4. **Do not share zones with public endpoints.** A `privatelink.*` zone returns NXDOMAIN for resources that have no PE — this breaks fallback to public resolution unless you configure `NxDomainRedirect` on the VNet link (API 2024-06-01+; Private Link zones only).
5. **Azure Files caveat:** If switching from public endpoint to PE, file shares must be remounted.

### On-premises resolution: the Private DNS Resolver requirement

Private DNS Zones are not accessible from on-premises DNS servers by default. On-prem DNS servers cannot query Azure's internal DNS (`168.63.129.16`) over VPN or ExpressRoute.

**The required pattern:**

```
On-premises DNS server
  └─ Conditional forwarder: privatelink.blob.core.windows.net → [Inbound Endpoint IP]
       └─ Azure DNS Private Resolver — Inbound Endpoint (private IP in /28 subnet, dedicated)
            └─ Resolves against Azure Private DNS Zone: privatelink.blob.core.windows.net
                 └─ Returns: 10.1.0.5 (PE private IP)
```

**Azure DNS Private Resolver requirements:**
- Deploy in a VNet (hub recommended for shared access)
- **Inbound endpoint:** dedicated subnet, /28–/24, delegated to `Microsoft.Network/dnsResolvers`
- **Zone link:** the Private DNS Zone must be linked to the resolver's VNet (or reachable via peering)
- On-premises DNS server must have a conditional forwarder rule per `privatelink.*` zone pointing to the inbound endpoint's private IP
- VPN Gateway or ExpressRoute must be in place for network connectivity; DNS Private Resolver requires standard ER path — **FastPath is incompatible with Private Resolver**
- Outbound endpoint + forwarding ruleset needed for Azure → on-prem DNS queries

### Split-horizon gotchas

| Gotcha | Detail |
|---|---|
| Zone not linked to VNet | PE exists but DNS resolves to public IP inside VNet — traffic goes to public endpoint, not PE |
| Zone linked to wrong VNet | Spoke VNets in peered topologies need the zone linked directly OR resolve via Private Resolver — peering alone does not share DNS zone resolution |
| Multiple PEs for same resource | Each PE gets an A record in the zone; clients get the PE for their VNet unless the zone is shared across VNets |
| NXDOMAIN on fallback | Private zone returns NXDOMAIN for services with no PE — can break wildcard lookups unless NxDomainRedirect is configured |
| Resolver loop | Do NOT link a DNS forwarding ruleset (that contains a rule pointing to an inbound endpoint) back to the same VNet where that inbound endpoint resides — this creates a DNS resolution loop |
| DNS Private Resolver + VNet encryption | Incompatible — do not deploy Private Resolver in a VNet with encryption enabled |

---

## Common patterns

### Pattern 1 — Hub-spoke with Private Endpoints in hub

**Problem:** Multiple spoke workloads need access to the same PaaS services (Storage, SQL, Key Vault). Creating a PE per spoke is expensive and operationally complex.

**Solution:**
- Deploy one PE per PaaS resource in the **hub VNet** (or a shared-services spoke)
- Link the corresponding `privatelink.*` Private DNS Zones to the hub VNet
- Spoke VNets resolve the FQDN via peering — but DNS zone resolution does NOT flow through peering automatically
- Deploy Azure DNS Private Resolver in the hub; configure spoke VNets to use the hub resolver's inbound endpoint IP as their DNS server (centralized pattern), OR link the forwarding ruleset to each spoke (distributed pattern)
- One PE in hub serves all spokes — cost-efficient; single management point

**DNS path (centralized):**
```
Spoke VM → queries hub inbound endpoint IP → resolver looks up private zone (linked to hub) → returns PE private IP
```

**DNS path (distributed):**
```
Spoke VM → Azure default DNS (168.63.129.16) → forwarding ruleset linked to spoke → forwards to hub inbound endpoint → returns PE private IP
```

> ⚠️ Do NOT use the distributed pattern if the forwarding ruleset contains a rule pointing to the hub inbound endpoint AND you link that ruleset to the hub VNet itself — this creates a loop.

---

### Pattern 2 — Private Endpoint with DNS Private Resolver for on-premises access

**Problem:** On-premises workloads need to resolve and reach Azure PaaS over ExpressRoute or VPN.

**Solution:**
1. Private Endpoint in hub VNet (private IP from VNet space)
2. Azure DNS Private Resolver with inbound endpoint in hub VNet (dedicated /28 subnet)
3. Private DNS Zone linked to hub VNet
4. On-premises DNS server: conditional forwarder for each `privatelink.*` zone → hub inbound endpoint IP
5. ExpressRoute or VPN provides network-layer reachability to both the PE IP and the inbound endpoint IP

**Key constraint:** Standard ExpressRoute path only. ExpressRoute FastPath bypasses the VNet gateway and is incompatible with Private Resolver queries.

---

### Pattern 3 — Service Endpoints for simple intra-VNet Storage or SQL access

**Problem:** A VM or compute workload in a VNet needs to reach Azure Storage or SQL Database. On-premises access is not needed. Budget is tight. DNS complexity is unwanted.

**Solution:**
- Enable Service Endpoint `Microsoft.Storage` or `Microsoft.Sql` on the subnet
- Configure the Storage Account or SQL Server network firewall to allow the VNet
- Optionally, add a Service Endpoint Policy (Storage/SQL) to restrict to specific resource instances

**When NOT to use this pattern:**
- ❌ If on-premises access is ever needed → migrate to PE
- ❌ If the PaaS resource must be completely private (no public endpoint) → PE required
- ❌ If the workload spans multiple tenants → PE required

---

### Pattern 4 — App Service calling PaaS privately (VNet Integration + Private Endpoint)

**Problem:** An App Service (or Function / Container App) needs to call Azure SQL, Storage, or Key Vault without traffic traversing the public internet.

**Solution:**
1. Enable **VNet Integration** on the App Service — delegates an outbound subnet so App Service traffic originates from the VNet
2. Deploy **Private Endpoints** on SQL, Storage, Key Vault in the same VNet (or peered hub VNet)
3. Link `privatelink.*` Private DNS Zones to the VNet containing the PEs
4. Configure App Service DNS to use Azure DNS (`168.63.129.16`) — this is the default
5. Optionally add **NAT Gateway** to the VNet Integration subnet for deterministic outbound internet SNAT (for calls that go public)

**To also expose the App Service privately (inbound):** Add a separate Private Endpoint on the App Service resource itself. This is independent of VNet Integration.

---

## Limits

| Limit | Value | Notes |
|---|---|---|
| **Private endpoints per VNet (standard)** | 1,000 [VERIFY] | Raise via High Scale opt-in |
| **Private endpoints per VNet (High Scale)** | 5,000 [VERIFY] | Set `privateEndpointVNetPolicies=Basic`; one-time connection reset on enable/disable |
| **Private endpoints across peered VNets (standard)** | 4,000 [VERIFY] | Silent degradation when exceeded |
| **Private endpoints across peered VNets (High Scale)** | 20,000 [VERIFY] | |
| **NAT IPs per Private Link Service** | 8 [VERIFY] | |
| **ASG members per NSG on PE subnet** | 50 [VERIFY] | Exceeding causes connection failures |
| **NSG destination port ranges product on PE subnet** | ≤ 250,000 (sources × destinations × port ranges) | e.g., 100×100×25 = 250,000 — at limit |
| **Private DNS zones per subscription** | [VERIFY — see Azure DNS Limits] | |
| **VNet links per private DNS zone** | [VERIFY — see Azure DNS Limits] | |
| **Registration VNets per private zone** | [VERIFY] | A VNet can be registration VNet for only one zone |
| **DNS Private Resolver inbound endpoint subnet** | /28 minimum, /24 maximum | Delegated to `Microsoft.Network/dnsResolvers`; IPv4 only |
| **DNS forwarding rules per ruleset** | 1,000 [VERIFY] | Longest suffix match wins |
| **VNets linked per DNS forwarding ruleset** | 500 (same region) [VERIFY] | Cross-region VNet links not supported |
| **Service Endpoint supported services** | ~10 service families | Storage, SQL, Cosmos DB, Key Vault, Service Bus, Event Hubs, App Service, Container Registry, PostgreSQL, MySQL, MariaDB |
| **Private Endpoint supported services** | 60+ services | Full list: `raw/articles/private-link/private-endpoint-overview.md` |

> All limits marked [VERIFY] — authoritative source: [Azure Networking Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-private-link-limits) and [Azure DNS Limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits#azure-dns-limits).

---

## Related pages

- [Private Link](../services/private-link.md) — Deep dive on Private Endpoints and Private Link Service; DNS zone table, NSP, High Scale, cost model, troubleshooting checklist
- [Virtual Network](../services/virtual-network.md) — VNet fundamentals; service endpoints, subnet delegation, NSG/UDR behavior, address space planning
- [DNS](../services/dns.md) — Azure DNS sub-services: Public DNS, Private DNS, DNS Private Resolver, DNS Security Policy; hybrid DNS patterns, zone sharding, DNSSEC
- [NAT Gateway](../services/nat-gateway.md) — Required for outbound internet access from VNet Integration subnets; does not apply to Private Endpoint traffic (which goes over backbone)

---

## Compilation notes

1. **VNet Integration depth gap:** Source articles do not contain a dedicated VNet Integration wiki page. The details in this guide are sourced from `virtual-network.md` (subnet delegation), `nat-gateway.md` (App Service VNet-integrated workloads), and the networking overview. Subnet sizing requirements, plan tier prerequisites, and regional VNet Integration vs. Gateway-required VNet Integration are not covered here. A dedicated `wiki/services/app-service-networking.md` page is recommended.

2. **Service Endpoint Policies:** Mentioned briefly — these restrict service endpoints to specific resource instances (Storage and SQL only per source articles). Not expanded here as source coverage is thin; verify against `virtual-network-service-endpoint-policies-overview.md` raw article.

3. **All limits `[VERIFY]`:** Source articles consistently defer to the Azure subscription limits reference page rather than stating values inline. Treat all numeric limits as approximate until verified.

4. **DNS zone list is partial:** The `raw/articles/private-link/private-endpoint-dns.md` file is 43 KB and was only partially read (commercial cloud, top services). Gov cloud and China cloud zone names are not included. Full zone reference must be verified for sovereign cloud deployments.