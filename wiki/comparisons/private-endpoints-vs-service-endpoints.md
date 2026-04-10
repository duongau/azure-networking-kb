# Private Endpoints vs Service Endpoints vs Both

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Azure offers two primary mechanisms to access PaaS services (Storage, SQL, Key Vault, etc.) from a VNet without using the public internet path. They are architecturally different, with different security guarantees, DNS requirements, and cost profiles. Microsoft explicitly recommends Private Endpoints for all new designs.

---

## Core comparison

| Dimension | Service Endpoint | Private Endpoint |
|---|---|---|
| **What it does** | Extends VNet identity to Azure service — source IP seen by service switches from public to private; traffic routes over Azure backbone | Injects a NIC with a private IP from your VNet subnet, mapped to a **specific PaaS resource instance** |
| **Private IP in your VNet** | ❌ No — DNS still resolves to public IP of service | ✅ Yes — a `/32` private IP assigned for the PE's lifetime |
| **DNS change required** | ❌ No — application uses existing public FQDN; no DNS change | ✅ Yes — **mandatory**; must override public DNS to resolve to private IP; misconfiguration silently breaks connectivity |
| **Resource scope** | All instances of the service type (e.g., all Azure Storage for all customers) | Single specific resource instance (e.g., only `mystorageaccount.blob.core.windows.net`) |
| **Data exfiltration protection** | ❌ No — policy can't prevent writing to another customer's storage account via SE path | ✅ Yes — PE is scoped to one instance; cannot reach other instances via private path |
| **Public endpoint disable** | ❌ No — service still has public IP; you can restrict access but public IP exists | ✅ Yes — service public access can be fully disabled once PE is configured |
| **On-premises access (ER / VPN)** | ❌ No — on-premises traffic still arrives as public IP; SE benefit doesn't apply | ✅ Yes — PE is a private IP reachable from on-premises via ER private peering or VPN |
| **Cross-region** | ❌ Not directly — SE is regional | ✅ Yes — PE in one region can connect to PaaS in another |
| **Cross-tenant** | ❌ No | ✅ Yes — PEs work across different Microsoft Entra tenants |
| **Cost** | ✅ Free — no extra charge | 💰 Per-PE hourly charge + per-GB data processing [VERIFY] |
| **Setup complexity** | Low — enable toggle on subnet per service type | Medium — deploy PE resource, configure DNS zone, link zone to VNet, verify connection approval |
| **NSG / UDR support on subnet** | Limited — NSG applies but traditional NSG rules don't filter SE traffic directly | ✅ Full — NSG, UDR, ASG all supported (with regional caveats — not available in West India, Brazil Southeast, South Africa West, Australia Central 2) |
| **BGP propagation / routing** | Uses Azure backbone; no custom routing needed | Uses Azure backbone; UDR may be needed to route PE traffic through NVA |
| **Supported services** | ~20 services (Storage, SQL, Cosmos DB, Key Vault, Service Bus, Event Hubs, App Service, Container Registry, Synapse, MySQL, PostgreSQL, MariaDB, others) | 60+ services — superset of SE-supported services; also includes Redis, AKS API, Bot Service, AI Search, Azure OpenAI, and more |
| **Approval workflow** | None — SE is enabled on subnet | Auto-approve (RBAC-permissioned) or manual request → approve / reject / disconnect |
| **Connection direction** | Outbound from VNet to service | Consumer-initiated only; service cannot initiate back |

---

## DNS — the critical difference

Private Endpoints require DNS configuration. Without it, the client resolves to the public IP and either bypasses the private path or fails entirely.

### How it works

```
Client resolves: mystorageaccount.blob.core.windows.net
    │
    ├── PUBLIC resolution (no PE): → 20.x.x.x (public Azure IP)
    │
    └── PRIVATE resolution (PE + Private DNS Zone):
            CNAME: mystorageaccount.blob.core.windows.net
                → mystorageaccount.privatelink.blob.core.windows.net
                → 10.1.0.5 (private IP of PE in your VNet)
```

### DNS options

| Scenario | Approach |
|---|---|
| VNet-only access | Azure Private DNS Zone linked to the VNet; auto-registration on PE creation (recommended zone names) |
| Hybrid — on-premises resolvers | Azure DNS Private Resolver with inbound/outbound endpoints; conditional forwarding from on-premises DNS |
| Testing only | Host file override on individual VMs |

### Selected DNS zone names (commercial cloud)

| Service | Private DNS Zone |
|---|---|
| Azure Blob Storage | `privatelink.blob.core.windows.net` |
| Azure Files | `privatelink.file.core.windows.net` |
| Azure SQL Database | `privatelink.database.windows.net` |
| Azure Cosmos DB (SQL) | `privatelink.documents.azure.com` |
| Azure Key Vault | `privatelink.vaultcore.azure.net` |
| Event Hubs / Service Bus | `privatelink.servicebus.windows.net` |
| Azure Container Registry | `privatelink.azurecr.io` |

> Use the **recommended zone names** exactly — auto-integration only works with the canonical zone name. Do not share one zone across multiple PaaS service types.

---

## When to use Service Endpoints

Service Endpoints are acceptable in these scenarios (but Private Endpoints are still preferred):
- You have a simple VNet-only access restriction requirement with no on-premises or cross-region needs
- Cost sensitivity: Private Endpoints charge per hour + per GB; Service Endpoints are free
- Your service is not exposed to on-premises clients
- You are using legacy designs that predate Private Endpoint support for that service

**Do not use Service Endpoints if:**
- Data exfiltration protection is required (cannot scope to a specific resource instance)
- On-premises workloads need to access the PaaS service via ER or VPN
- You need to fully disable the public endpoint on the PaaS resource

---

## When to use Private Endpoints

Use Private Endpoints for all new designs — this is the Microsoft-recommended default:
- Any regulated workload (financial, healthcare, government) where data must not traverse public internet
- On-premises access to PaaS via ExpressRoute or VPN
- Preventing data exfiltration to other resource instances of the same service
- Fully disabling public access to the PaaS resource
- Cross-tenant private access (partner/customer scenarios)

---

## When to use both

Use **Service Endpoint policies** alongside Private Endpoints for defense-in-depth:

| Scenario | What to do |
|---|---|
| VNet has PE for `mystorageaccount` but you want to prevent all other storage access via SE path | Add a Service Endpoint policy to the subnet — limits SE to allowed storage accounts only |
| Mixed environment where some legacy services only support SE | Apply SE for legacy services; PE for new services |

---

## Network Security Perimeter (NSP) — the third option

NSP controls **public internet access** to PaaS resources, complementing Private Endpoints:

| Pattern | What it controls | Use for |
|---|---|---|
| Private Endpoint | VNet-to-PaaS private path | Eliminating public internet path for VNet consumers |
| Service Endpoint | VNet identity on Azure backbone | Simple VNet-to-service traffic optimization (legacy) |
| NSP (enforced mode) | Public internet access to PaaS | Restricting which public IPs / subscriptions can reach a PaaS resource |

NSP **does not replace** Private Endpoints — a resource can have both a PE and an NSP simultaneously.

---

## Decision table

| Requirement | Service Endpoint | Private Endpoint |
|---|---|---|
| Free with no extra charges | ✅ | ❌ |
| Restrict PaaS access to a specific VNet subnet | ✅ | ✅ |
| Prevent data exfiltration to other instances | ❌ | ✅ |
| On-premises access via ER / VPN | ❌ | ✅ |
| Fully disable PaaS public IP | ❌ | ✅ |
| Cross-tenant or cross-subscription access | ❌ | ✅ |
| No DNS changes required | ✅ | ❌ (mandatory) |
| Low setup complexity | ✅ | ⚠️ Medium |
| 60+ supported services | ❌ (~20) | ✅ (60+) |
| Microsoft-recommended for new designs | ❌ | ✅ |

---

## Key limits [VERIFY all]

| Limit | Value |
|---|---|
| Private Endpoints per VNet (standard) | 1,000 |
| Private Endpoints per VNet (High Scale opt-in) | 5,000 |
| Peered-VNet PE aggregate (standard) | 4,000 (silent degradation if exceeded) |
| Peered-VNet PE aggregate (High Scale) | 20,000 |
| ASG members per NSG on PE subnet | 50 (exceeding silently breaks PE connections) |
| PLS idle timeout | ~300 seconds — implement TCP keepalives |
| Service Endpoints per VNet | No documented limit |

---

## Source pages

| Source | Notes |
|---|---|
| [Private Link](../services/private-link.md) | PE mechanics, PLS, DNS zones, NSP, High Scale, known limitations |
| [Virtual Network](../services/virtual-network.md) | Service Endpoints, NSG/UDR support on PE subnets, subnet delegation |
| [Private Access to PaaS](../concepts/private-access-to-paas.md) | Four patterns, side-by-side comparison, DNS config, NSP |