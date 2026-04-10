# Azure Network Function Manager

> **Compiled:** 2026-04-10 | **Source articles:** 8 | **Status:** ✅ current

> [!WARNING]
> **⚠️ END OF LIFE — Azure Network Function Manager was sunset on 2025-10-01.**
> This page is retained for reference. Do not design new solutions around this service.

---

## What it is

**Azure Network Function Manager (NFM)** is a fully managed, cloud-native orchestration service that deploys and provisions **network functions** — such as mobile packet core, SD-WAN edge, and VPN services — onto an **Azure Stack Edge Pro with GPU** appliance running in an on-premises or edge environment. It exposes an **Azure Marketplace** experience (via **Azure Managed Applications**) so that partner network functions can be selected, deployed, and lifecycle-managed directly from the Azure portal using familiar ARM tooling and RBAC. NFM is a component of the broader **Azure private MEC** (Multi-Access Edge Compute) solution.

Key behavior:
- NFM is a **regional control-plane service** — management operations are cloud-hosted, but the network functions themselves run as VMs on the on-premises ASE device.
- If the Azure region hosting NFM resources experiences an outage, **management operations are impacted** but **network functions already deployed on the device continue running unaffected**.
- If the ASE device loses connectivity to the cloud, **management operations (create, delete, monitor) are blocked**, but **deployed NF VMs continue operating** (partner-specific caveats may apply).
- NFM itself carries **no additional cost** — the ASE device and any partner NF licensing are billed separately. [VERIFY]
- **Resource provider:** `Microsoft.HybridNetwork` (must be registered on the subscription).

---

## Key capabilities

| Capability | Detail |
|---|---|
| **Azure Marketplace deployment** | Network functions deployed as Azure Managed Applications directly from Azure Marketplace or via the NFM device blade in the portal |
| **Consistent management plane** | Single Azure portal, ARM templates, SDK, and Azure RBAC for all partner NFs across the device fleet |
| **5G / LTE mobile packet core** | Deploy private mobile network solutions (e.g., Affirmed Private Network Service, Metaswitch Fusion Core) from Marketplace |
| **SD-WAN and VPN** | Deploy SD-WAN/VPN NFs (Versa, VMware) using the same Marketplace managed-app experience used in public cloud |
| **Network acceleration** | ASE Pro ports 5 & 6 support **SR-IOV** and **DPDK** for superior NF data-path performance [VERIFY] |
| **Static or dynamic IP allocation** | Configurable per virtual network interface on the NF VM; first 4 IPs per port range are reserved for ASE service |
| **Azure RBAC governance** | Custom roles control who can create devices, deploy NFs, and generate registration keys |
| **Managed identity integration** | User-assigned managed identity required during managed-app deployment to grant the publisher access to the device resource outside the managed RG |
| **Partner ecosystem** | Growing set of ISV partners publishing validated NF images to Azure Marketplace |

---

## Architecture patterns

```
┌─────────────────────────────────────────────────┐
│                  Azure Region                    │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │  Resource Group (customer-owned)          │   │
│  │  • NFM Device resource  ──────────────── │──┐│
│  │  • Managed App placeholder (per NF)      │  ││
│  └──────────────────────────────────────────┘  ││
│                                                  ││
│  ┌──────────────────────────────────────────┐   ││
│  │  Managed Resource Group (publisher-owned) │   ││
│  │  • Network Function resource (hidden type)│   ││
│  └──────────────────────────────────────────┘   ││
└─────────────────────────────────────────────────┘│
                                                   │ registration key
                                    ┌──────────────┘
                         ┌──────────▼──────────────────────────────┐
                         │  On-premises / Edge Site                 │
                         │                                          │
                         │  Azure Stack Edge Pro (GPU)              │
                         │  • ASE resource (linked 1:1 to NFM Dev.) │
                         │  • NF VMs (packet core, SD-WAN, VPN)    │
                         │  • Ports 5 & 6: network-accelerated      │
                         └──────────────────────────────────────────┘
```

**Key structural rules:**
- **1:1 mapping** — one NFM Device resource maps to exactly one ASE resource. Multiple ASE devices require multiple NFM Device resources.
- **Two resource groups per NF deployment** — a customer RG (contains managed app, visible properties) and a publisher-controlled managed RG (contains the NF resource; show "Hidden Types" to see it).
- The **Azure Stack Edge resource, NFM Device resource, and managed application** must all reside in the **same Azure region**. The physical ASE appliance does not need to be in that region.
- NFM is part of the **Azure private MEC** solution stack — ASE Pro can simultaneously run NFs, VM/container-based edge apps, and GPU workloads on the same device.

---

## Configuration essentials

### Prerequisites

| Requirement | Detail |
|---|---|
| **Hardware** | Azure Stack Edge Pro with GPU — only supported ASE variant [VERIFY] |
| **Device status** | ASE must be installed, activated, and showing **Online** in the portal before creating NFM resources |
| **Subscription alignment** | Same Azure subscription ID must be used for ASE activation and NFM resources; must also be onboarded with the NF partner |
| **Resource provider** | Register `Microsoft.HybridNetwork` on the subscription |
| **Firewall — outbound HTTPS** | Allow `*.blob.storage.azure.net` and `*.mecdevice.azure.com` |

### Deployment sequence

```
1. Register Microsoft.HybridNetwork resource provider
       ↓
2. Configure RBAC — assign custom roles for device resource creation
       ↓
3. Create NFM Device resource in Azure portal (links to ASE resource; must be Online)
       ↓
4. Get registration key from device resource
   ⚠️  Key expires 24 hours after generation
       ↓
5. Connect to ASE via PowerShell (minishell)
   Run: Invoke-MecRegister <device-registration-key>
   Verify: Device Status = Registered
       ↓
6. Create user-assigned managed identity
   Assign custom role with Microsoft.HybridNetwork/devices/join/action
       ↓
7. From Device resource → "+ Create Network Function"
   Select Vendor SKU → redirected to Marketplace managed-app portal
   Configure Management / LAN / WAN interfaces, IP addresses, partner settings
   ⚠️  Do NOT use first 4 IPs of any port's IP range (reserved for ASE)
       ↓
8. After deployment: vendor provisioning status = Provisioned
   Complete remaining configuration via partner management portal
```

### Partner network functions

| Partner | Category |
|---|---|
| Affirmed Private Network Service | Mobile packet core |
| Metaswitch Fusion Core | 5G packet core |
| NetFoundry ZTNA | Zero-trust network access |
| Versa SD-WAN | SD-WAN |
| VMware SD-WAN | SD-WAN |

### Deletion sequence

```
1. Delete all network functions within the device
   (if "Failed to delete resource" error: find and delete the managed application directly)
       ↓
2. Delete the NFM Device resource
   ⚠️  Cannot delete device while NFs still exist
```

---

## Monitoring and troubleshooting

| Area | Detail |
|---|---|
| **Common management surface** | NFM Device resource provides unified monitoring for all NFs on the ASE device |
| **Connectivity requirement** | Active network connectivity between ASE and the NFM cloud service required for all management operations |
| **Disconnected mode** | If ASE is disconnected: NF VMs continue running; management ops are blocked |
| **Region outage** | NFM management plane impacted; on-device NFs unaffected |
| **Provisioning validation** | Check managed RG for NF resource with **Vendor Provisioning Status = Provisioned** (enable "Show Hidden Types") |
| **Device registration validation** | Check Device resource for **Device Status = Registered** after `Invoke-MecRegister` |
| **Partner management portal** | All post-deployment configuration is done via the partner's portal, not NFM directly |

---

## Common gotchas / known limits

- **⚠️ SERVICE IS SUNSET (2025-10-01).** Do not build new solutions on NFM.
- **Only Azure Stack Edge Pro with GPU is supported** — no other edge device variants.
- **1:1 device-to-ASE constraint** — each ASE resource requires its own NFM Device resource.
- **Registration key TTL is 24 hours** — if expired before running `Invoke-MecRegister`, generate a new one.
- **First 4 IPs per port range are reserved** for ASE internal services — do not assign to NF VMs.
- **Must delete all NFs before deleting the device resource** — no cascade delete.
- **Partner portal required for full configuration** — NFM only handles initial provisioning.
- **Subscription ID alignment is strict** — ASE activation, NFM resources, and partner onboarding must all use the same subscription ID.
- **Cross-region resource moves are not supported.**

---

## Related services

- **[Virtual WAN](virtual-wan.md)** — Alternative SD-WAN integration approach for cloud-managed branch connectivity
- **[VPN Gateway](vpn-gateway.md)** — Alternative for VPN termination in cloud-centric architectures
- **[Azure Firewall Manager](firewall-manager.md)** — Centralised security policy management for cloud-native deployments
