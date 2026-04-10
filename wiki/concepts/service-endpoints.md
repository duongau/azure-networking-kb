# Service Endpoints in Azure

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** current

## Overview

Azure Virtual Network service endpoints extend your VNet's private identity to Azure PaaS services, enabling those services to restrict access to traffic originating from your VNet. Service endpoints provide optimal routing over the Azure backbone but do **not** assign private IP addresses — the PaaS service still has a public IP, but access is restricted.

> **Microsoft recommendation:** Use **Private Endpoints** for all new designs. Service Endpoints are acceptable for legacy scenarios or when cost is the primary concern.

---

## What service endpoints do

| Capability | Detail |
|---|---|
| **Optimal routing** | Traffic takes shortest path over Azure backbone; removes hairpinning through on-premises |
| **Source IP switch** | PaaS service sees traffic from VNet private IP instead of public IP |
| **Service firewall rules** | PaaS resource can restrict access to specific VNets/subnets |
| **No private IP** | DNS still resolves to public IP; traffic routes optimally but endpoint remains public |
| **No extra cost** | Free — no per-hour or per-GB charges |

### How it works

```
VM (10.0.1.5) → Service Endpoint on subnet → Azure backbone → Storage (public IP)
                                                              ↓
                                    Storage sees source: 10.0.1.5 (VNet private IP)
                                    Storage firewall allows VNet X only
```

---

## Supported services

| Service | Notes |
|---|---|
| Azure Storage | Blob, Files, Queue, Table, Data Lake Gen2 |
| Azure SQL Database | Including SQL Managed Instance |
| Azure Cosmos DB | All APIs |
| Azure Key Vault | |
| Azure Service Bus | |
| Azure Event Hubs | |
| Azure App Service | Web Apps, Functions |
| Azure Container Registry | |
| Azure Cognitive Services | |
| Azure Web PubSub | |
| Azure MariaDB / MySQL / PostgreSQL | |
| Azure Synapse Analytics | |

---

## Configuration

### Subnet delegation vs service endpoint

| Mechanism | Purpose | Configuration |
|---|---|---|
| **Service Endpoint** | Extends VNet identity to PaaS; enables service firewall rules | Enable per service type on subnet |
| **Subnet Delegation** | Reserves subnet for specific PaaS service injection (e.g., SQL MI, App Service Env) | Delegate subnet to specific service |

Service endpoints are enabled per **subnet** and per **service type**:

```azurecli
az network vnet subnet update \
  --resource-group myRG \
  --vnet-name myVNet \
  --name mySubnet \
  --service-endpoints Microsoft.Storage Microsoft.Sql
