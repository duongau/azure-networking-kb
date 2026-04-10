# Azure DNS Private Resolver vs Custom DNS (VM-based forwarders)

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Hybrid DNS resolution between Azure and on-premises requires forwarding DNS queries between environments. This comparison covers two approaches: the managed **Azure DNS Private Resolver** service and traditional **VM-based DNS forwarders** (Windows DNS, BIND, Unbound, etc.).

---

## At a glance

| Dimension | Azure DNS Private Resolver | Custom DNS (VM forwarders) |
|---|---|---|
| **Architecture** | Managed PaaS with inbound/outbound endpoints | IaaS VMs running DNS software |
| **Operational overhead** | Zero — fully managed, no patching | High — OS patching, vulnerability scans, DNS software updates |
| **Availability model** | Zone-redundant by design; Active-Active instances | Customer-managed via VM availability sets/zones |
| **Scaling** | Automatic within endpoint limits | Manual — add VMs, configure clustering |
| **Inbound endpoint** | Receives queries from on-premises forwarders | VM IP receives queries |
| **Outbound endpoint** | Forwards queries to on-premises/external DNS | VM forwards queries via conditional forwarders |
| **Private DNS zone integration** | Native — linked VNets resolve private zones | Requires forwarding to Azure DNS (168.63.129.16) or explicit zone copies |
| **DNS forwarding rules** | Up to 1,000 rules per ruleset | Unlimited — depends on DNS software |
| **VNets per ruleset** | 500 (same region) [VERIFY] | N/A — per-VM configuration |
| **Cost** | Per endpoint-hour [VERIFY] | VM compute + storage + licensing (Windows DNS) |
| **IPv6** | ❌ Not supported | ✅ Depends on DNS software |

---

## Side-by-side comparison

### Architecture

| Aspect | Private Resolver | Custom DNS VMs |
|---|---|---|
| **Resource type** | `Microsoft.Network/dnsResolvers` | Azure VMs with DNS software |
| **Subnet requirement** | Dedicated /28–/24 subnet delegated to `Microsoft.Network/dnsResolvers` | Standard subnet (no delegation required) |
| **Deployment model** | Azure-managed instances (invisible to customer) | Customer-managed VMs |
| **Instance count** | Multiple Active-Active instances (automatic) | Customer configures (typically 2+ for HA) |
| **Self-healing** | ✅ Automatic during zone-wide outages | ❌ Manual — requires automation or human intervention |
| **IaC support** | ARM, Bicep, Terraform | ARM, Bicep, Terraform, Ansible |

### High availability

| Aspect | Private Resolver | Custom DNS VMs |
|---|---|---|
| **Zone redundancy** | ✅ Built-in — auto-deploys across AZs | ⚠️ Manual — use Availability Zones for VMs |
| **Active-Active** | ✅ Multiple instances by default | ⚠️ Requires load balancer or DNS round-robin |
| **Self-healing** | ✅ Automatic | ❌ Manual or via automation scripts |
| **Failover configuration** | None required | Customer configures LB health probes or DNS failover |
| **Regional failover** | Deploy resolvers in multiple regions | Deploy VMs in multiple regions |
| **SLA** | Governed by Azure DNS SLA [VERIFY] | Composite VM SLA (99.95% with AZ) [VERIFY] |

### Operational overhead

| Task | Private Resolver | Custom DNS VMs |
|---|---|---|
| **OS patching** | ❌ None | ✅ Required — security patches, reboots |
| **DNS software updates** | ❌ None | ✅ Required — BIND, Windows DNS, Unbound updates |
| **Vulnerability scanning** | ❌ None | ✅ Required — compliance scans |
| **Backup/restore** | ❌ None | ✅ Required — VM snapshots, config backups |
| **Monitoring** | Azure Monitor metrics | Custom monitoring + Azure Monitor VM insights |
| **Troubleshooting** | Azure portal + metrics | OS-level + DNS software logs |
| **DevOps adoption** | High — ARM/Bicep/Terraform native | Medium — requires OS provisioning automation |

### Scale and limits

| Limit | Private Resolver | Custom DNS VMs |
|---|---|---|
| **Inbound endpoints per resolver** | 6 [VERIFY] | N/A — per-VM |
| **Outbound endpoints per resolver** | 6 [VERIFY] | N/A — per-VM |
| **DNS forwarding rules per ruleset** | 1,000 [VERIFY] | Unlimited (software-dependent) |
| **VNets linked per ruleset** | 500 (same region) [VERIFY] | N/A — configure per-VNet |
| **Endpoints per VNet** | Multiple resolvers possible | Multiple VMs possible |
| **Domain label limit** | 34 labels per rule (or `.` wildcard) | Software-dependent |
| **Cross-region ruleset links** | ❌ Not supported | N/A |
| **Query throughput** | Managed — scales automatically | Scales with VM size |

### Network integration

| Aspect | Private Resolver | Custom DNS VMs |
|---|---|---|
| **VNet peering** | Works with hub-and-spoke; spokes link to ruleset | Works with hub-and-spoke; point spoke DNS to hub VMs |
| **ExpressRoute/VPN** | Required for on-premises connectivity | Required for on-premises connectivity |
| **ExpressRoute FastPath** | ❌ Not compatible | ✅ Compatible |
| **VNet encryption** | ❌ Not compatible | ✅ Compatible |
| **Azure Lighthouse** | ❌ Not compatible | ✅ Compatible |
| **Private endpoint DNS** | ✅ Native — private zones linked to resolver VNet | ✅ Forward to 168.63.129.16 or link zones |
| **Azure Firewall DNS proxy** | Can chain: Firewall DNS proxy → Resolver outbound | Can chain: Firewall DNS proxy → VM forwarders |

### Cost comparison

| Component | Private Resolver | Custom DNS VMs |
|---|---|---|
| **Base cost** | Per endpoint-hour (~$0.18/endpoint/hour) [VERIFY] | VM compute per hour |
| **Inbound endpoint** | ~$0.18/hour (~$131/month) [VERIFY] | Included in VM cost |
| **Outbound endpoint** | ~$0.18/hour (~$131/month) [VERIFY] | Included in VM cost |
| **DNS queries** | Included in endpoint cost | Included in VM cost |
| **Storage** | None | OS disk + data disks |
| **Licensing** | None | Windows Server license (if using Windows DNS) |
| **Operational cost** | None | Staff time for patching, updates, troubleshooting |

**Typical monthly cost comparison:**

| Scenario | Private Resolver | Custom DNS VMs |
|---|---|---|
| 1 inbound + 1 outbound | ~$262/month [VERIFY] | 2× D2s_v5 = ~$140/month + ops overhead |
| 2 inbound + 2 outbound | ~$524/month [VERIFY] | 4× D2s_v5 = ~$280/month + ops overhead |
| Multi-region (2 regions) | ~$524/month [VERIFY] | 4× D2s_v5 = ~$280/month + ops overhead |

> Private Resolver has higher direct cost but zero operational overhead. For organizations with strong VM management practices, custom DNS may be cheaper. For DevOps-focused teams, Private Resolver reduces toil.

---

## When to use Private Resolver

✅ **Use Azure DNS Private Resolver when:**

| Scenario | Why |
|---|---|
| **Eliminate DNS VM infrastructure** | Zero patching, no vulnerability scans, no DNS software updates |
| **Hybrid DNS with minimal ops** | Managed service; focus on rules, not infrastructure |
| **Hub-and-spoke architecture** | Deploy in hub; link rulesets to spoke VNets |
| **Private endpoint DNS resolution from on-premises** | On-premises forwards to inbound endpoint; resolves `privatelink.*` zones |
| **New greenfield deployments** | Modern approach; DevOps-friendly IaC |
| **Multi-region DNS failover** | Deploy resolvers in multiple regions with failover rulesets |
| **Accelerated Networking required** | Private Resolver supports Accelerated Networking (implicit) |
| **Cost clarity** | Predictable per-endpoint billing; no hidden VM/storage costs |

---

## When to use Custom DNS VMs

✅ **Use VM-based DNS forwarders when:**

| Scenario | Why |
|---|---|
| **ExpressRoute FastPath required** | Private Resolver is not compatible with FastPath |
| **VNet encryption required** | Private Resolver is not compatible with VNet encryption |
| **Azure Lighthouse cross-tenant** | Private Resolver is not compatible with Lighthouse |
| **IPv6 required** | Private Resolver does not support IPv6 subnets |
| **Existing mature VM DNS infrastructure** | Migration cost exceeds benefit |
| **DNS software features not available in Resolver** | DNSSEC validation, complex zone transfers, TSIG authentication |
| **Cost optimization with strong VM ops** | Lower direct cost if ops overhead is acceptable |
| **Custom logging/auditing requirements** | Full control over DNS query logging |
| **Third-party DDI solutions** | Infoblox, BlueCat, etc. require VM deployments |
| **Regulatory requirement for full infrastructure control** | Some compliance mandates customer-managed infrastructure |

---

## Private endpoint DNS resolution

Both approaches support private endpoint DNS resolution. The key difference is configuration complexity:

### Private Resolver approach

```
On-premises DNS server
    │
    │  Conditional forwarder: privatelink.blob.core.windows.net → [Inbound endpoint IP]
    ▼
Azure DNS Private Resolver (inbound endpoint)
    │
    │  VNet linked to private DNS zone: privatelink.blob.core.windows.net
    ▼
Private DNS zone resolves → Private endpoint IP
```

**Configuration steps:**
1. Create Private Resolver with inbound endpoint
2. Link private DNS zones to the resolver's VNet
3. Configure on-premises conditional forwarder to point to inbound endpoint IP

### Custom DNS VM approach

```
On-premises DNS server
    │
    │  Conditional forwarder: privatelink.blob.core.windows.net → [VM DNS IP]
    ▼
VM-based DNS forwarder
    │
    │  Forward to Azure DNS (168.63.129.16) — or link zone directly
    ▼
Azure DNS (wireserver)
    │
    │  VNet linked to private DNS zone
    ▼
Private DNS zone resolves → Private endpoint IP
```

**Configuration steps:**
1. Deploy DNS VMs with HA (Availability Zones, load balancer)
2. Configure conditional forwarding to 168.63.129.16 for `privatelink.*` zones
3. Ensure VNet linked to private DNS zones
4. Configure on-premises conditional forwarder to point to VM IPs

---

## Hub-and-spoke integration

### Private Resolver in hub

```
┌────────────────────────────────────────────────────────┐
│                       Hub VNet                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  Azure DNS Private Resolver                       │  │
│  │  • Inbound endpoint (for on-premises queries)     │  │
│  │  • Outbound endpoint (for on-premises resolution) │  │
│  │  • DNS Forwarding Ruleset                         │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Private DNS Zones linked to Hub VNet                   │
│  • privatelink.blob.core.windows.net                   │
│  • privatelink.database.windows.net                    │
│  • contoso.internal                                    │
└────────────────────────────────────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌────────────┐    ┌────────────┐
│ Spoke VNet │    │ Spoke VNet │
│            │    │            │
│ DNS: Hub   │    │ DNS: Hub   │
│ Ruleset    │    │ Ruleset    │
│ linked     │    │ linked     │
└────────────┘    └────────────┘
```

**Key configurations:**
- Link DNS forwarding ruleset to spoke VNets
- Spoke VNets use custom DNS pointing to inbound endpoint (or inherit via ruleset)
- Private DNS zones linked only to hub VNet

### Custom DNS VMs in hub

```
┌────────────────────────────────────────────────────────┐
│                       Hub VNet                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │  DNS Forwarder VMs (2+ for HA)                    │  │
│  │  • Internal Load Balancer frontend                │  │
│  │  • Conditional forwarders to on-premises          │  │
│  │  • Forward to 168.63.129.16 for Azure zones       │  │
│  └──────────────────────────────────────────────────┘  │
│                                                         │
│  Private DNS Zones linked to Hub VNet                   │
└────────────────────────────────────────────────────────┘
              │
    ┌─────────┴─────────┐
    │                   │
    ▼                   ▼
┌────────────┐    ┌────────────┐
│ Spoke VNet │    │ Spoke VNet │
│            │    │            │
│ DNS: ILB   │    │ DNS: ILB   │
│ frontend   │    │ frontend   │
│ IP         │    │ IP         │
└────────────┘    └────────────┘
```

**Key configurations:**
- Deploy Internal Load Balancer in front of DNS VMs
- Spoke VNets use custom DNS pointing to ILB frontend IP
- DNS VMs forward to 168.63.129.16 for Azure private zones
- Private DNS zones linked to hub VNet

---

## Azure Firewall DNS proxy integration

Both approaches can integrate with Azure Firewall DNS proxy:

### With Private Resolver

```
Clients → Azure Firewall (DNS proxy) → Private Resolver (outbound) → On-premises DNS
```

- Firewall DNS proxy setting: point to Private Resolver inbound endpoint IP
- Firewall caches and filters DNS queries
- Resolver handles forwarding logic

### With Custom DNS VMs

```
Clients → Azure Firewall (DNS proxy) → DNS VMs → On-premises DNS
```

- Firewall DNS proxy setting: point to DNS VM IPs (or ILB)
- Firewall caches and filters DNS queries
- VMs handle forwarding logic

---

## Migration: VM-based to Private Resolver

### Migration steps

1. **Assess current state**
   - Document all conditional forwarders on existing DNS VMs
   - Identify all VNets using custom DNS (VM IPs)
   - Inventory private DNS zone links

2. **Deploy Private Resolver**
   - Create dedicated subnet (/28 minimum) in hub VNet
   - Deploy resolver with inbound endpoint (for on-premises queries)
   - Deploy outbound endpoint (for on-premises resolution)
   - Create DNS forwarding ruleset mirroring VM conditional forwarders

3. **Parallel testing**
   - Update test VNet to use Private Resolver inbound endpoint
   - Verify resolution of both Azure and on-premises names
   - Test private endpoint resolution

4. **Gradual migration**
   - Update spoke VNets to link to DNS forwarding ruleset
   - Update on-premises conditional forwarders to inbound endpoint IP
   - Monitor for resolution failures

5. **Decommission VMs**
   - Once all VNets migrated, decommission DNS VMs
   - Remove VM resources, disks, ILB

### Rollback plan

- Keep DNS VMs running during migration
- Revert spoke VNet custom DNS settings if issues arise
- Revert on-premises conditional forwarders to VM IPs

---

## Decision guide

| Requirement | Recommendation |
|---|---|
| Minimize operational overhead | **Private Resolver** |
| ExpressRoute FastPath required | **Custom DNS VMs** |
| VNet encryption required | **Custom DNS VMs** |
| Azure Lighthouse cross-tenant | **Custom DNS VMs** |
| IPv6 required | **Custom DNS VMs** |
| New deployment, DevOps-focused | **Private Resolver** |
| Existing mature VM DNS infrastructure | **Evaluate migration cost** |
| Hub-and-spoke with many spokes | **Private Resolver** (ruleset scales to 500 VNets) |
| Third-party DDI (Infoblox, BlueCat) | **Custom DNS VMs** |
| DNSSEC validation required | **Custom DNS VMs** |
| Budget-constrained with strong VM ops | **Custom DNS VMs** |
| Predictable billing, no hidden costs | **Private Resolver** |

---

## Limitations summary

### Private Resolver limitations

| Limitation | Workaround |
|---|---|
| ExpressRoute FastPath not compatible | Use standard ExpressRoute path for DNS |
| VNet encryption not compatible | Deploy resolver in non-encrypted VNet |
| Azure Lighthouse not compatible | Use per-tenant resolver instances |
| IPv6 subnets not supported | Use IPv4 subnets only |
| Cross-region ruleset links not supported | Deploy resolver per region |
| Wildcard (`.`) rule forwards ALL queries | Ensure target DNS can resolve public names |

### Custom DNS VM considerations

| Consideration | Mitigation |
|---|---|
| OS patching required | Use Update Management or Azure Automation |
| HA configuration required | Use Availability Zones + ILB |
| DNS software updates required | Automate with package management |
| Monitoring complexity | Use Azure Monitor VM insights + DNS logging |
| Vulnerability scanning | Integrate with Defender for Cloud |

---

## Source pages

| Source | Notes |
|---|---|
| [Azure DNS](../services/dns.md) | Full DNS service details including Private Resolver |
| [Private Link](../services/private-link.md) | Private endpoint DNS configuration |
| [Hybrid Connectivity](../concepts/hybrid-connectivity.md) | DNS in hybrid architectures |
| [Hub-Spoke Networking](../concepts/hub-spoke-networking.md) | DNS placement in hub-spoke |
