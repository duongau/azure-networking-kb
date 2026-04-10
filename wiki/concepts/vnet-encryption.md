# VNet Encryption in Azure

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** current

## Overview

Azure VNet encryption provides **DTLS-based encryption for VM-to-VM traffic** within a virtual network and across peered VNets. It operates at the network layer, encrypting all traffic between supported VMs without requiring application changes.

---

## What it is

VNet encryption creates DTLS tunnels between VM NICs to encrypt traffic in transit:
- **Within a single VNet** — encrypts VM-to-VM traffic
- **Across peered VNets** — encrypts traffic traversing VNet peering
- **Transparent to applications** — no code changes or certificates required
- **No throughput impact** — encryption handled by accelerated networking hardware

### How it works

```
VM A (Encrypted NIC) ←→ DTLS Tunnel ←→ VM B (Encrypted NIC)
```

- Traffic encrypted at source NIC, decrypted at destination NIC
- Uses Accelerated Networking hardware offload for performance
- Key exchange and tunnel establishment managed by Azure SDN

---

## Requirements

| Requirement | Detail |
|---|---|
| **Accelerated Networking** | Must be enabled on all VMs |
| **Supported VM SKUs** | D v4/v5/v6, E v4/v5/v6, M v2/v3, L v3, F v6 series |
| **VNet configuration** | Enable encryption on VNet resource |
| **Peering** | Both VNets must have encryption enabled |

### Supported VM series

| Series | Supported |
|---|---|
| D v4, D v5, D v6 | ✅ |
| E v4, E v5, E v6 | ✅ |
| M v2, M v3 | ✅ |
| L v3 | ✅ |
| F v6 | ✅ |
| A, B, NC, NV series | ❌ |
| VMs without AccelNet | ❌ |

---

## Limitations

| Limitation | Detail |
|---|---|
| **Basic Load Balancer** | Not supported with VNet encryption |
| **Host-based limitations** | Some older host configurations may not support encryption |
| **DNS Private Resolver** | Not compatible with VNet encryption — deploy resolver in non-encrypted VNet |
| **Enforcement mode** | Currently `AllowUnencrypted` only; `DropUnencrypted` planned [VERIFY] |
| **PaaS services** | Most PaaS services not supported; encryption is for VM-to-VM only |

### AllowUnencrypted vs DropUnencrypted

| Mode | Behavior |
|---|---|
| **AllowUnencrypted** (current) | Encrypts traffic when both endpoints support it; allows unencrypted traffic when not |
| **DropUnencrypted** (planned) | Drops traffic that cannot be encrypted; strict enforcement |

---

## How to enable

### Portal

1. Navigate to VNet resource → **Encryption**
2. Enable **Virtual network encryption**
3. Select enforcement mode (currently `AllowUnencrypted` only)

### CLI

```azurecli
az network vnet update \
  --resource-group myRG \
  --name myVNet \
  --enable-encryption true \
  --encryption-enforcement-policy allowUnencrypted
```

### Bicep

```bicep
resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: 'myVNet'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    encryption: {
      enabled: true
      enforcement: 'AllowUnencrypted'
    }
  }
}
```

---

## Verification

Check encryption status via VNet flow logs:
- `encryptionStatus` field indicates whether traffic was encrypted
- Only available in VNet Flow Logs (not NSG Flow Logs)

### Azure CLI

```azurecli
az network vnet show \
  --resource-group myRG \
  --name myVNet \
  --query encryption
```

---

## Relationship to other encryption technologies

### MACsec on ExpressRoute

| Aspect | VNet Encryption | MACsec (ExpressRoute Direct) |
|---|---|---|
| **Scope** | VM-to-VM within/across VNets | Physical link encryption on ER Direct ports |
| **Layer** | Network (DTLS) | Layer 2 |
| **Use case** | VM workload encryption | Dedicated circuit encryption |
| **Key management** | Azure-managed | Customer-managed via Key Vault |

MACsec and VNet encryption are **complementary**:
- MACsec encrypts ExpressRoute Direct physical links
- VNet encryption encrypts VM-to-VM traffic within Azure

### IPsec on VPN Gateway

| Aspect | VNet Encryption | IPsec (VPN Gateway) |
|---|---|---|
| **Scope** | VM-to-VM within Azure | Site-to-site and point-to-site tunnels |
| **Use case** | Intra-Azure encryption | Hybrid connectivity encryption |
| **Endpoint** | VM NICs | VPN Gateway ↔ on-premises VPN device |

IPsec and VNet encryption serve different purposes:
- IPsec encrypts traffic over public internet to/from on-premises
- VNet encryption encrypts VM traffic within Azure

---

## Zero Trust relevance

VNet encryption supports Zero Trust network principles:

| Zero Trust principle | VNet encryption contribution |
|---|---|
| **Assume breach** | Encrypts lateral movement paths; compromised traffic is still protected |
| **Verify explicitly** | Encryption is transparent but adds defense-in-depth layer |
| **Least privilege** | Combine with NSGs for network segmentation + encrypted transport |

### Defense-in-depth stack with VNet encryption

```
┌────────────────────────────────────────┐
│ DDoS Protection (L3/L4)                │
├────────────────────────────────────────┤
│ Azure Firewall (L3-L7 inspection)      │
├────────────────────────────────────────┤
│ NSGs (L4 segmentation)                 │
├────────────────────────────────────────┤
│ VNet Encryption (transport encryption) │ ← Encrypts VM-to-VM traffic
├────────────────────────────────────────┤
│ Application-level encryption (TLS)     │
└────────────────────────────────────────┘
