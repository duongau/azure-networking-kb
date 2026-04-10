# Azure Firewall Manager

> **Compiled:** 2026-04-10 | **Source articles:** 27 | **Status:** ✅ current

## What it is

**Azure Firewall Manager** is a centralized security management service that provides **firewall policy** authoring, deployment orchestration, and route management across cloud-based security perimeters. It operates over two distinct network architecture types — the **secured virtual hub** (an Azure Virtual WAN Hub with associated security policies) and the **hub virtual network** (a customer-managed VNet acting as a hub). Policies are global resources: a single policy can govern multiple Azure Firewall instances spanning multiple regions and subscriptions under the same Entra ID tenant.

Key behavior:
- Firewall Manager is a **control plane** service — it manages Azure Firewall instances and policies, not traffic itself
- **Firewall Policy** is the recommended configuration method; Classic rules are still supported but policy-only for Virtual WAN (secured virtual hub)
- Centralized route management (automatic, BGP-based) is available **only** in secured virtual hub deployments; hub VNet deployments require customer-managed UDRs
- Partner security-as-a-service (SECaaS) integration (currently **Zscaler** only) is available **only** in secured virtual hub deployments
- DDoS Protection plan association and WAF policy management are surfaced centrally through Firewall Manager

---

## Key capabilities

| Capability | Detail |
|---|---|
| Central firewall deployment | Deploy and configure multiple Azure Firewall instances across regions and subscriptions from a single pane |
| Firewall Policy management | Create, version, and associate policies (Basic / Standard / Premium) to one or many firewalls |
| Hierarchical policies | Parent–child policy inheritance; central IT sets base policy, DevOps teams extend it via child policies |
| Secured Virtual Hub | Azure Virtual WAN Hub with attached security/routing policies; automated BGP-based routing, no UDRs needed |
| Hub Virtual Network | Customer-managed VNet as hub; UDRs required to steer spoke traffic through firewall |
| Centralized route management | Route traffic to secured hub for filtering without manual UDRs (secured virtual hub only) |
| Partner SECaaS integration | Deploy Zscaler as Internet-traffic security provider alongside Azure Firewall for private traffic (secured virtual hub only) |
| DDoS Protection plan association | Associate DDoS Protection Plans to virtual networks directly from Firewall Manager |
| WAF policy management | Centrally create and associate WAF policies to Azure Front Door and Application Gateway |
| Private endpoint traffic inspection | Filter traffic destined to Private Link endpoints in Virtual WAN via Azure Firewall policy rules |
| IP Groups | Reusable logical groupings of IP addresses/CIDRs across rules and across multiple firewalls |
| Threat Intelligence | Alert or Alert+Deny on Microsoft Threat Intel feed; processed before all other rules |
| DNS proxy + custom DNS | Firewall acts as DNS intermediary; required for FQDN filtering in network rules; up to 15 custom DNS servers [VERIFY] |
| IaC support | Portal, REST API, ARM templates, PowerShell, CLI, Bicep, Terraform all supported |
| Policy high availability | ARM metadata fails over to paired region automatically; linked firewall instances continue operating during policy failover |

---

## Architecture patterns

### Secured virtual hub vs hub virtual network

A **secured virtual hub** is an Azure Virtual WAN Hub to which Firewall Manager has associated security and routing policies. A **hub virtual network** is a standard Azure VNet that you create and manage, with Azure Firewall Policy attached.

| Dimension | Hub Virtual Network | Secured Virtual Hub |
|---|---|---|
| **Underlying resource** | Customer-managed VNet | Microsoft-managed Virtual WAN Hub |
| **Hub & spoke connectivity** | Manual VNet peering | Automated via Virtual WAN hub connections |
| **On-premises VPN** | Up to 10 Gbps, 30 S2S connections [VERIFY] | Up to 20 Gbps, 1000 S2S connections [VERIFY] |
| **ExpressRoute** | Supported | Supported (more scalable) |
| **Automated branch connectivity (SDWAN)** | ❌ Not supported | ✅ Supported |
| **Route management** | Customer UDRs | Automated via BGP; Routing Intent for inter-hub |
| **Partner SECaaS** | Manual VPN to partner; customer-managed | Automated via security partner provider flow |
| **Public IPs on firewall** | Customer-provided | Auto-generated (or BYOPIP preview) |
| **Availability Zones** | Supported | Supported (must use PowerShell to enable AZs on existing hub) |
| **DDoS Protection** | Yes | Yes (requires customer-provided public IP address) |
| **NVA support** | In VNet | In spoke network only (not in hub) |
| **WAF / App Gateway** | In VNet | In spoke network only |
| **Multiple security providers** | Manual forced-tunneling to 3rd party | Automated: Azure Firewall (private) + partner (Internet) |

### Deployment flow — secured virtual hub

1. Create Secured Virtual Hub via Firewall Manager (or convert existing Virtual WAN hub)
2. Select security providers (Azure Firewall and/or partner SECaaS)
3. Create a Firewall Policy and associate it with the hub
4. Configure **Security Configuration** (Internet traffic / Private traffic routing) — Firewall Manager automates route tables via BGP
5. Enable **Routing Intent** (`Inter-hub: Enabled`) for inter-hub and branch-to-branch traffic inspection

### Deployment flow — hub virtual network

1. Create a Firewall Policy (new, inherited, or migrated from Classic rules)
2. Create or designate a Hub VNet; peer spoke VNets
3. Associate Firewall Policy with the hub
4. Configure **User Defined Routes** on spoke subnets to steer traffic through the firewall
5. UDR on hub gateway subnet pointing to firewall private IP is required for spoke reach-back

### Hybrid network (hub VNet + on-premises)

- Requires UDR on hub gateway subnet pointing to firewall for spoke-to-on-prem routing
- Azure Firewall must have direct Internet connectivity — override any BGP-learned default route with a 0.0.0.0/0 UDR `NextHopType: Internet` on `AzureFirewallSubnet`
- Traffic between directly peered VNets bypasses firewall unless UDRs explicitly list target subnet prefixes on **both** sides

---

## Policy management

### Policy tiers

| Policy type | Supported features | Compatible firewall SKU |
|---|---|---|
| **Basic** | NAT rules, Network rules, Application rules, IP Groups, Threat Intelligence (alerts only) | Basic [VERIFY] |
| **Standard** | All Basic features + Custom DNS, DNS proxy, Web Categories, Threat Intelligence (alert or deny) | Standard or Premium [VERIFY] |
| **Premium** | All Standard features + TLS Inspection, URL Filtering (full path), IDPS (67,000+ signatures) | Premium [VERIFY] |

### Policy vs Classic rules

| Subject | Policy | Classic rules |
|---|---|---|
| Protects | Virtual Hubs (VWAN) and Virtual Networks | Virtual Networks only |
| Multi-firewall | One policy → many firewalls | Manual export/import per firewall |
| IDPS, TLS Inspection, URL Filtering | ✅ (Premium policy) | ❌ |
| Web Categories | ✅ | ❌ |
| Portal experience | Centralized (Firewall Manager) | Standalone firewall |
| Pricing | Free (≤1 association); fixed rate (>1 association) [VERIFY] | Free |

### Hierarchical policies and inheritance

