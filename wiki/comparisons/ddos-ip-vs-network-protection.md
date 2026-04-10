# Azure DDoS IP Protection vs DDoS Network Protection

> **Compiled:** 2026-04-10 | **Type:** Comparison | **Status:** ✅ current

Azure DDoS Protection offers two paid tiers above the free infrastructure protection: **IP Protection** (per-resource billing) and **Network Protection** (per-VNet plan billing). Both provide the same adaptive tuning and L3/L4 mitigation capabilities — the difference is scope, cost model, and included support features.

---

## At a glance

| Dimension | DDoS IP Protection | DDoS Network Protection |
|---|---|---|
| **Scope** | Per public IP resource | Per VNet (plan covers all public IPs in linked VNets) |
| **Billing model** | Per protected IP per month | Fixed monthly plan fee (covers first 100 IPs [VERIFY]) |
| **Cost crossover** | More cost-effective for <10 public IPs | More cost-effective at ~10+ public IPs [VERIFY] |
| **Rapid Response (DRR)** | ❌ Not included | ✅ Included — dedicated Microsoft experts during active attacks |
| **Cost protection** | ❌ Not included | ✅ Service credit for data-transfer and scale-out costs during attacks |
| **WAF discount** | ❌ Not included | ✅ App Gateway WAF billed at Standard_v2 rate (not WAF_v2) |
| **Adaptive tuning** | ✅ ML-based per-IP profiling | ✅ ML-based per-IP profiling |
| **Attack analytics** | ✅ 5-minute increment reports | ✅ 5-minute increment reports |
| **Attack metrics & alerts** | ✅ Azure Monitor metrics | ✅ Azure Monitor metrics |
| **Mitigation policies** | ✅ 3 auto-tuned policies per IP (TCP SYN, TCP, UDP) | ✅ 3 auto-tuned policies per IP (TCP SYN, TCP, UDP) |
| **Detection-to-mitigation** | 30–60 seconds [VERIFY] | 30–60 seconds [VERIFY] |
| **Multi-subscription** | Per-IP, per-subscription | One plan covers all subscriptions in tenant |

---

## Side-by-side comparison

### Protection capabilities

| Capability | IP Protection | Network Protection |
|---|---|---|
| **Always-on traffic monitoring** | ✅ | ✅ |
| **Adaptive real-time tuning** | ✅ ML-based per-IP | ✅ ML-based per-IP |
| **Auto-tuned mitigation policies** | ✅ 3 per IP (TCP SYN, TCP, UDP) | ✅ 3 per IP (TCP SYN, TCP, UDP) |
| **Attack detection-to-mitigation** | 30–60 seconds | 30–60 seconds |
| **Attack analytics** | ✅ 5-min reports during attack; full summary post-attack | ✅ 5-min reports during attack; full summary post-attack |
| **Attack metrics** | ✅ Azure Monitor (e.g., *Under DDoS attack*, *Inbound packets dropped*) | ✅ Azure Monitor metrics |
| **Metric retention** | 30 days [VERIFY] | 30 days [VERIFY] |
| **Flow log streaming** | ✅ To Sentinel, Splunk, Storage, SIEM | ✅ To Sentinel, Splunk, Storage, SIEM |
| **Microsoft Sentinel integration** | ✅ | ✅ |

### Support and financial protection

| Feature | IP Protection | Network Protection |
|---|---|---|
| **DDoS Rapid Response (DRR)** | ❌ | ✅ — Microsoft experts assist during active attacks |
| **Cost protection / credits** | ❌ | ✅ — Service credit for documented attack-related costs |
| **WAF billing discount** | ❌ | ✅ — App Gateway WAF_v2 billed at Standard_v2 rate |
| **SLA** | 99.99% [VERIFY] | 99.99% [VERIFY] |

### Scope and management

| Aspect | IP Protection | Network Protection |
|---|---|---|
| **Protection scope** | Individual public IP address | All public IPs in VNets linked to the plan |
| **Plan resource** | None — enabled per-IP | DDoS Protection Plan resource (one per tenant recommended) |
| **Cross-subscription** | Per-IP, per-subscription | One plan spans all subscriptions in tenant |
| **Cross-region** | Per-IP | One plan covers all regions |
| **Enable/disable** | Per public IP resource | Per VNet link to plan |
| **Subscription move** | IP moves with resource | Plan cannot be moved (delete + recreate) |

---

## Cost model

### IP Protection

- **Per protected IP per month** [VERIFY exact rate]
- Enabled on individual public IP resources
- No upfront commitment
- Best for: small deployments with few public IPs

### Network Protection

- **Fixed monthly plan fee**: ~$2,944/month [VERIFY]
  - Includes first 100 public IP addresses
  - Overage charges for additional IPs [VERIFY]
- One plan covers:
  - All subscriptions in the tenant
  - All Azure regions
  - All VNets linked to the plan
- Additional benefits:
  - DDoS Rapid Response (DRR) access
  - Cost protection credits
  - WAF billing discount

### Cost crossover analysis

| Public IPs | IP Protection (est.) | Network Protection (est.) | Recommendation |
|---|---|---|---|
| 1–9 | Lower | Higher | IP Protection |
| 10–99 | Higher | Lower | Network Protection |
| 100+ | Much higher | Lower (overage applies) | Network Protection |

> The exact crossover point is approximately 10 public IPs [VERIFY]. See [Azure DDoS Protection Pricing](https://azure.microsoft.com/pricing/details/ddos-protection/) for current rates.

---

## When to use IP Protection

✅ **Use DDoS IP Protection when:**

| Scenario | Why |
|---|---|
| Small deployment with <10 public IPs | Lower total cost than Network Protection plan |
| No need for DRR support | Rapid Response is not required |
| No need for cost protection credits | Financial credits during attacks not required |
| No Application Gateway WAF | WAF discount doesn't apply |
| Per-IP control needed | Enable/disable protection on specific IPs only |
| Dev/test environments | Lower cost for non-production workloads |

---

## When to use Network Protection

✅ **Use DDoS Network Protection when:**

| Scenario | Why |
|---|---|
| Enterprise deployment with 10+ public IPs | Plan becomes more cost-effective |
| DDoS Rapid Response required | Direct access to Microsoft DDoS experts during attacks |
| Cost protection required | Service credits for attack-related scale-out and data transfer |
| Application Gateway WAF deployed | WAF_v2 billed at Standard_v2 rate (significant savings) |
| Multi-subscription tenant | One plan covers all subscriptions |
| Multi-region deployment | One plan covers all regions |
| Compliance requirements | DRR and cost protection may be compliance-driven |
| Hub-and-spoke topology | Enable on hub VNet; all hub public IPs (Firewall, Bastion, etc.) protected |

---

## WAF interaction

### Without DDoS Network Protection

| Resource | Billing |
|---|---|
| Application Gateway WAF_v2 | WAF_v2 hourly rate + capacity units |

### With DDoS Network Protection (same VNet)

| Resource | Billing |
|---|---|
| Application Gateway WAF_v2 | **Standard_v2** hourly rate + capacity units |

**Savings:** WAF_v2 is billed at the lower Standard_v2 rate when DDoS Network Protection is active on the same VNet.

### Multi-layer protection

| Layer | Protection provided |
|---|---|
| **L3/L4** | DDoS Protection (IP or Network) — volumetric attacks, SYN floods, UDP reflection |
| **L7** | Application Gateway WAF or Azure Front Door WAF — HTTP floods, Slowloris, application exploits |

> Both layers are recommended for comprehensive protection. DDoS Protection handles volumetric L3/L4 attacks; WAF handles L7 application-layer attacks.

---

## Protected resource types

Both tiers protect the same resource types:

| Resource type | Notes |
|---|---|
| **Public Load Balancer (Standard)** | Public IP attached to LB frontend |
| **Application Gateway** | Public IP attached to App Gateway |
| **Azure Firewall** | Public IP attached to Firewall |
| **Azure Bastion** | Public IP in hub-and-spoke |
| **VPN Gateway** | Supported but adaptive tuning not available |
| **Virtual Network Gateway (ER)** | Supported but adaptive tuning not available |
| **VMs with public IPs** | Public IP attached to NIC |

### Not supported

| Resource type | Notes |
|---|---|
| **NAT Gateway public IPs** | Explicitly unsupported |
| **Azure Virtual WAN resources** | Not supported |
| **PaaS multitenant services (outside VNet)** | Requires VNet-deployed resources |
| **Classic/RDFE VM deployments** | Not supported |

---

## Limits

| Limit | Value | Notes |
|---|---|---|
| Public IPs included per Network Protection plan | 100 [VERIFY] | Overage charges apply |
| DDoS protection plans per tenant (recommended) | 1 | One plan links to VNets across all subscriptions/regions |
| Attack metric data retention | 30 days [VERIFY] | Via Azure Monitor |
| Attack detection to mitigation | 30–60 seconds [VERIFY] | May vary by attack type |
| Mitigation policies per protected public IP | 3 | TCP SYN, TCP, UDP — auto-tuned via ML |
| Plan subscription move | Not supported | Must delete and recreate in target subscription |

---

## Decision guide

| Requirement | Recommendation |
|---|---|
| <10 public IPs, basic protection | **IP Protection** |
| 10+ public IPs | **Network Protection** |
| Need DDoS Rapid Response | **Network Protection** |
| Need cost protection credits | **Network Protection** |
| Have Application Gateway WAF | **Network Protection** (WAF discount) |
| Single subscription, few IPs | **IP Protection** |
| Multi-subscription enterprise | **Network Protection** |
| Dev/test, budget-constrained | **IP Protection** |
| Production, compliance-driven | **Network Protection** |

---

## Migration considerations

### IP Protection → Network Protection

1. Create DDoS Protection Plan resource
2. Link VNets containing protected public IPs to the plan
3. Disable IP Protection on individual IPs (optional — plan takes precedence)
4. No service interruption during migration

### Network Protection → IP Protection

1. Unlink VNets from DDoS Protection Plan
2. Enable IP Protection on individual public IP resources
3. Delete DDoS Protection Plan (if no longer needed)
4. Ensure continuous protection during transition

---

## Infrastructure Protection (free tier)

For comparison, the free infrastructure-level DDoS protection:

| Aspect | Infrastructure Protection (Free) |
|---|---|
| **Cost** | $0 — included for all Azure public IPs |
| **Adaptive tuning** | ❌ No |
| **Per-IP profiling** | ❌ No |
| **Attack analytics** | ❌ No |
| **Metrics/alerts** | ❌ No |
| **DRR** | ❌ No |
| **Cost protection** | ❌ No |
| **Protection level** | Basic volumetric protection; shared across Azure |

> Free tier is insufficient for production workloads with public IPs. Use IP Protection or Network Protection for adaptive tuning and telemetry.

---

## Source pages

| Source | Notes |
|---|---|
| [Azure DDoS Protection](../services/ddos-protection.md) | Full service details, capabilities, limits |
| [Network Security Design](../concepts/network-security-design.md) | DDoS in context of Zero Trust |
| [Azure DDoS Protection Pricing](https://azure.microsoft.com/pricing/details/ddos-protection/) | Current pricing [VERIFY] |
