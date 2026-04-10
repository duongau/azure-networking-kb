# Network Security Groups (NSGs) in Depth

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

## NSG rule structure

An NSG is a collection of security rules that filter network traffic to and from Azure resources. Each rule specifies:

| Property | Description | Values |
|---|---|---|
| **Priority** | Order of evaluation; lower number = higher priority | 100–4,096 |
| **Name** | Display name for the rule | Any string |
| **Direction** | Inbound or outbound | `Inbound`, `Outbound` |
| **Action** | What to do when rule matches | `Allow`, `Deny` |
| **Protocol** | Network protocol | `TCP`, `UDP`, `ICMP`, `ESP`, `AH`, `*` (any) |
| **Source** | Where traffic originates | IP address, CIDR, service tag, ASG |
| **Source port range** | Source port(s) | Single port, range (e.g., `1024-65535`), `*` |
| **Destination** | Where traffic is destined | IP address, CIDR, service tag, ASG |
| **Destination port range** | Destination port(s) | Single port, range, `*` |

### Rule evaluation

- Rules are evaluated **by priority** (lowest number first)
- **First match wins** — processing stops after a rule matches
- If no rule matches, the default deny rule drops the packet
- NSGs are **stateful** — return traffic for an allowed connection is automatically permitted

---

## Default rules

Every NSG includes these default rules (priority 65000–65500). They cannot be deleted but can be overridden with lower-priority rules.

### Inbound default rules

| Priority | Name | Source | Destination | Action |
|---|---|---|---|---|
| 65000 | `AllowVnetInBound` | `VirtualNetwork` | `VirtualNetwork` | Allow |
| 65001 | `AllowAzureLoadBalancerInBound` | `AzureLoadBalancer` | `*` | Allow |
| 65500 | `DenyAllInBound` | `*` | `*` | Deny |

### Outbound default rules

| Priority | Name | Source | Destination | Action |
|---|---|---|---|---|
| 65000 | `AllowVnetOutBound` | `VirtualNetwork` | `VirtualNetwork` | Allow |
| 65001 | `AllowInternetOutBound` | `*` | `Internet` | Allow |
| 65500 | `DenyAllOutBound` | `*` | `*` | Deny |

**Key implication:** By default, VMs can reach the internet outbound and communicate within the VNet. Inbound traffic from the internet is denied.

---

## Application Security Groups (ASGs)

ASGs provide **logical grouping** of VM NICs for use in NSG rules, eliminating the need to manage IP addresses.

### How ASGs work

1. Create an ASG (e.g., `AsgWebServers`, `AsgDbServers`)
2. Assign VM NICs to ASGs (a NIC can belong to multiple ASGs)
3. Reference ASGs in NSG rules as source or destination

### Example

Instead of:
```
Priority 100: Allow TCP 443 from 10.0.1.5, 10.0.1.6, 10.0.1.7 to 10.0.2.10, 10.0.2.11
```

Use:
```
Priority 100: Allow TCP 443 from AsgWebServers to AsgAppServers
```

### ASG constraints

| Constraint | Detail |
|---|---|
| Same VNet required | All NICs in an ASG must be in the same VNet |
| Cross-VNet not supported | Cannot reference ASG in a different VNet in NSG rules |
| Multiple ASG membership | A NIC can belong to multiple ASGs |
| Limit per NSG | 50 ASG members per NSG on a private endpoint subnet [VERIFY] |

### Scaling benefit

When you add/remove VMs, just update ASG membership — no NSG rule changes required. This scales to hundreds of VMs without rule sprawl.

---

## Service tags

Service tags are **Microsoft-managed groups of IP ranges** for Azure services. Azure updates them automatically — no manual IP management.

### Common service tags

| Tag | Scope | Use case |
|---|---|---|
| `VirtualNetwork` | VNet + connected networks | Allow intra-VNet traffic |
| `AzureLoadBalancer` | LB health probe IPs | Allow health probes (required for LB to work) |
| `Internet` | All public IPs outside Azure VNets | Allow/deny internet traffic |
| `AzureCloud` | All Azure datacenter IPs | Region-scoped variants: `AzureCloud.WestEurope` |
| `Storage` | Azure Storage IPs | Region-scoped: `Storage.EastUS` |
| `Sql` | Azure SQL IPs | Region-scoped variants available |
| `AzureMonitor` | Azure Monitor/Log Analytics | Allow diagnostic traffic |
| `AppService` | App Service outbound IPs | Identify App Service traffic |
| `AzureActiveDirectory` | Azure AD endpoints | Allow identity traffic |
| `GatewayManager` | Gateway management plane | Required for VPN/App Gateway health |
| `AzureBackup` | Azure Backup service | Allow backup traffic |
| `AzureSiteRecovery` | ASR service | Allow replication traffic |

### Using service tags

```
Priority 110: Allow TCP 443 from * to AzureMonitor — outbound
```

This allows outbound HTTPS to Azure Monitor without maintaining an IP list.

---

## NSG flow logs

NSG flow logs capture **per-flow traffic records** for traffic evaluated by NSGs.

### Flow log versions

| Version | Data captured |
|---|---|
| **v1** | 5-tuple (source IP, dest IP, source port, dest port, protocol), action |
| **v2 (current)** | v1 + bytes, packets, flow state, traffic analytics integration |

### Flow log record

Each record includes:
- Timestamp
- 5-tuple
- Flow direction
- NSG rule name that matched
- Action (allow/deny)
- Bytes sent/received
- Packets sent/received
- Flow state (Begin, Continue, End)

### Traffic Analytics

Traffic Analytics processes NSG flow logs and provides:
- **Top talkers** — VMs generating most traffic
- **Geo-map** — traffic origin/destination countries
- **Open ports** — ports accepting traffic
- **Malicious flows** — traffic matching threat intelligence
- **Anomaly detection** — unusual traffic patterns

**Requirement:** Flow logs stored in a Storage Account; Traffic Analytics requires Log Analytics workspace.

### VNet flow logs (preferred for new deployments)

VNet flow logs capture flows at the **VNet level** (not per-NSG), simplifying configuration for large VNets. They are the recommended approach for new deployments.

---

## NSG on subnet vs NIC

NSGs can be applied at two levels:
- **Subnet level** — applies to all NICs in the subnet
- **NIC level** — applies to a specific NIC only

### When both are applied

| Traffic direction | Evaluation order |
|---|---|
| **Inbound** | Subnet NSG → NIC NSG |
| **Outbound** | NIC NSG → Subnet NSG |

Traffic must be **allowed by both** NSGs. If the subnet NSG allows but the NIC NSG denies, traffic is denied.

### Best practice

- Apply NSGs at **subnet level** for consistency
- Use NIC-level NSGs only when VMs in the same subnet need different rules
- Avoid complex per-NIC rules — they create troubleshooting nightmares

---

## Common NSG patterns

### Bastion subnet rules

Azure Bastion requires specific NSG rules on `AzureBastionSubnet`:

**Inbound:**

| Priority | Source | Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|
| 120 | `Internet` | 443 | TCP | Allow | Client HTTPS access |
| 130 | `GatewayManager` | 443 | TCP | Allow | Control plane |
| 140 | `AzureLoadBalancer` | 443 | TCP | Allow | Health probes |
| 150 | `VirtualNetwork` | 8080, 5701 | Any | Allow | Bastion host communication |

**Outbound:**

| Priority | Destination | Port | Protocol | Action | Purpose |
|---|---|---|---|---|---|
| 100 | `VirtualNetwork` | 22, 3389 | TCP | Allow | SSH/RDP to target VMs |
| 110 | `AzureCloud` | 443 | TCP | Allow | Telemetry, management |
| 120 | `VirtualNetwork` | 8080, 5701 | Any | Allow | Bastion host communication |
| 130 | `Internet` | 80 | TCP | Allow | Certificate validation (OCSP, CRL) |

### AzureFirewallSubnet

**NSGs are not supported** on `AzureFirewallSubnet`. Azure Firewall manages its own traffic filtering.

If you apply an NSG to `AzureFirewallSubnet`, it will be ignored or cause deployment failures.

### GatewaySubnet NSG caveats

Applying an NSG to `GatewaySubnet` is **discouraged** by Microsoft:
- May block VPN/ExpressRoute control plane traffic
- Must allow traffic from `GatewayManager` service tag
- Must allow traffic from `AzureLoadBalancer`
- Must allow traffic on ports required by the gateway type

If you must apply an NSG, carefully allow all required control plane traffic.

---

## Augmented security rules

A single rule can specify **multiple IPs, CIDRs, ports, or service tags** — reducing rule count.

### Example

Instead of 3 rules:
```
Allow TCP 80 from 10.0.1.0/24
Allow TCP 80 from 10.0.2.0/24
Allow TCP 80 from 10.0.3.0/24
```

Use 1 augmented rule:
```
Allow TCP 80 from 10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24
```

### Limits

| Property | Max values per rule |
|---|---|
| Source addresses | 4,000 (combined with prefixes) |
| Destination addresses | 4,000 (combined with prefixes) |
| Ports | 250 ranges |

---

## Security admin rules (Azure Virtual Network Manager)

Security admin rules are **evaluated before NSG rules** and provide org-wide policy enforcement.

### Rule actions

| Action | Behavior |
|---|---|
| **Allow** | Traffic allowed; NSG rules evaluated next |
| **Always Allow** | Traffic allowed; NSG evaluation **skipped** |
| **Deny** | Traffic denied; NSG evaluation **skipped** |

### Use case

Central security team creates:
```
Deny Inbound TCP 22 from Internet to * (priority 100)
```

Applied to all VNets via network group. Individual teams cannot override this with NSG allow rules.

### Services that skip security admin rules

| Level | Services |
|---|---|
| VNet level | Azure SQL Managed Instance, Azure Databricks |
| Subnet level | App Gateway, Bastion, Firewall, Route Server, VPN Gateway, ExpressRoute Gateway, Virtual WAN |

For VNet-level skips, you can opt in to **Allow-only** rules using configuration properties.

---

## Related pages

| Page | Relationship |
|---|---|
| [Virtual Network](../services/virtual-network.md) | NSGs applied to subnets/NICs |
| [Network Security Design](./network-security-design.md) | NSGs as Layer 4 of defense-in-depth |
| [Azure Firewall](../services/azure-firewall.md) | L3-L7 inspection (not NSGs) |
| [Virtual Network Manager](../services/virtual-network-manager.md) | Security admin rules |

---

## Source pages

| Source | Notes |
|---|---|
| [Virtual Network](../services/virtual-network.md) | NSG overview, rule priority, ASGs, service tags, effective rules |
| [Network Security Design](./network-security-design.md) | NSG placement, flow logs, Traffic Analytics |