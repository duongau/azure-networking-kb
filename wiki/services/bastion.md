# Azure Bastion

> **Compiled:** 2026-04-10 | **Source articles:** 43 | **Status:** current

## What it is

Azure Bastion is a fully managed PaaS service that provides secure RDP/SSH connectivity to virtual machines directly over TLS (port 443) from the Azure portal, or via native SSH/RDP clients, without requiring a public IP address on the VM, an agent, or special client software. It is deployed into a dedicated subnet inside your virtual network and reaches all VMs in that VNet (and peered VNets for Basic SKU and above) via private IP addresses.

---

## Key capabilities

| Capability | Details |
|---|---|
| Browser-based RDP/SSH | HTML5 web client via Azure portal; single-click session; all SKUs |
| Native client connections | Local SSH/RDP client via Azure CLI (`az network bastion`); Standard+ only |
| Shareable links | Portal-free VM access links; no Azure credentials required by end user; Standard+ only |
| IP-based connections | Connect to VMs by IP rather than resource ID; Standard+ |
| Custom ports | Override default RDP (3389) / SSH (22) inbound ports; Standard+ |
| File transfer | Upload/download via native client; Standard+ |
| Host scaling | Configurable 2-50 instances in scale-unit increments; Standard+ |
| Session recording | Full RDP/SSH session capture to Azure Blob Storage; Premium only; portal sessions only; cannot be used concurrently with native client |
| Private-only deployment | No public IP; access via ExpressRoute private peering or VPN; Premium only |
| VNet peering support | Single Bastion serves hub-and-spoke or full-mesh topologies; Basic+ |
| Kerberos authentication | Domain-joined Windows VM authentication; all SKUs |
| SSH key from Key Vault | Retrieve stored private keys at connect time; all SKUs |
| Microsoft Entra ID auth (SSH) | Entra ID for SSH (Linux) via portal and native client; GA (November 2024) |
| Microsoft Entra ID auth (RDP portal) | Entra ID for RDP connections via portal; **Public Preview** (November 2025); cannot be used concurrently with graphical session recording |
| Microsoft Entra ID auth (RDP native) | Entra ID for RDP via native client only |
| Availability zones | Zonal or zone-redundant deployment; **Public Preview** in select regions |
| Session monitoring | View/disconnect active sessions; all SKUs |
| Azure Monitor integration | Metrics, diagnostic logs (BastionAuditLogs), activity logs |
| AKS private cluster connectivity | Connect to AKS private clusters via Bastion tunneling command; **Public Preview** (August 2025) |

---

## When to use it

| Scenario | Rationale |
|---|---|
| Eliminate public IPs on VMs | Bastion terminates user sessions; VMs need no public IP, no open RDP/SSH ports |
| Centralized secure access in hub-and-spoke | Deploy once in hub VNet; reach all spoke VMs via VNet peering (Basic+) |
| Compliance / audit requirements | Session recording (Premium) provides immutable connection logs |
| Dev/test environments | Developer SKU is free; no subnet required; single VM at a time |
| ExpressRoute / private-only environments | Private-only deployment (Premium) removes public IP entirely |
| Mixed Windows/Linux fleets | Single platform handles RDP and SSH |
| Teams without Azure portal credentials | Shareable links (Standard+) allow connection without portal access |
| AKS private cluster access | Bastion tunneling command connects to AKS private API server without VPN (Public Preview) |

---

## When NOT to use it

| Anti-pattern | Alternative / notes |
|---|---|
| Azure Virtual Desktop connectivity | Bastion does not support AVD; use AVD native connectivity |
| Force-tunneled networks (0.0.0.0/0 via ER or VPN) | Breaks Bastion control plane; remove default route from Bastion VNet |
| Deploying inside a Virtual WAN hub | Not supported inside hub; deploy in spoke VNet instead |
| IPv6-only or dual-stack ingress | Bastion is IPv4 only |
| Private Link fronting for Bastion | Azure Private Link is not supported for Bastion |
| UDR / forced traffic inspection on AzureBastionSubnet | UDR not supported on AzureBastionSubnet |
| RDS (Remote Desktop Services) scenarios | Explicitly not supported |

---

## SKUs and tiers

| SKU | Use case | Key limits | Cost |
|---|---|---|---|
| **Developer** | Dev/test; no-cost evaluation | 1 VM at a time; no peering; select regions only [VERIFY] | Free |
| **Basic** | Small production; fixed capacity | 2 instances fixed; 40 RDP / 80 SSH concurrent sessions; no scaling | Paid hourly + data transfer [VERIFY] |
| **Standard** | Most production workloads | 2-50 instances; up to 1,000 RDP / 2,000 SSH at max scale; native client; shareable links | Paid hourly + data transfer [VERIFY] |
| **Premium** | Compliance / high-security | All Standard features + session recording + private-only deployment | Paid hourly + data transfer [VERIFY] |

**SKU upgrade path:** Developer -> Basic/Standard/Premium | Basic -> Standard -> Premium (in-place, ~10 min, no deletion). **Downgrade not supported** - requires delete and recreate.

---

## Service limits

| Limit | Value | Notes |
|---|---|---|
| AzureBastionSubnet minimum size | /26 | Must be named exactly `AzureBastionSubnet` |
| Public IP SKU (Basic/Standard/Premium) | Standard, Static allocation | Private-only: no public IP needed |
| Basic SKU instances | 2 (fixed) | Cannot scale |
| Standard/Premium SKU instances | 2-50 (configurable) | [VERIFY] |
| Concurrent RDP sessions per instance | 20 | |
| Concurrent SSH sessions per instance | 40 | |
| Max concurrent RDP at 50 instances | 1,000 | [VERIFY] |
| Max concurrent SSH at 50 instances | 2,000 | [VERIFY] |
| Shareable links per Bastion resource | 500 | [VERIFY] |
| Maximum screen resolution (browser) | 1920x1080 | |
| IPv6 support | Not supported | IPv4 only |
| UDR on AzureBastionSubnet | Not supported | |
| Private Link for Bastion | Not supported | |
| First 5 GB outbound data/month | Free | All paid SKUs [VERIFY] |

---

## NSG requirements

If an NSG is applied to `AzureBastionSubnet`, all of the following rules are mandatory:

**Inbound:**

| Source | Destination | Port | Protocol |
|---|---|---|---|
| Internet | * | 443 | TCP |
| GatewayManager | * | 443 | TCP |
| VirtualNetwork | VirtualNetwork | 8080, 5701 | Any |
| AzureLoadBalancer | * | 443 | TCP |

**Outbound:**

| Source | Destination | Port | Protocol |
|---|---|---|---|
| * | VirtualNetwork | 22, 3389 | Any |
| * | AzureCloud | 443 | TCP |
| VirtualNetwork | VirtualNetwork | 8080, 5701 | Any |
| * | Internet | 80 | Any |

**Target VM subnet:** Allow inbound from AzureBastionSubnet range on ports 22 and 3389 (or custom ports).

---

## Architecture patterns

| Pattern | SKUs | Notes |
|---|---|---|
| Single-VNet dedicated | Basic / Standard / Premium | Bastion in AzureBastionSubnet; VMs in same VNet |
| Hub-and-spoke (centralized) | Basic+ | Bastion in hub; reaches spoke VMs via peering; single deployment |
| Private-only | Premium | No public IP; users connect via ExpressRoute private peering or VPN |
| Developer (shared) | Developer | Microsoft-managed shared infrastructure; 1 VM at a time |

---

## Related services

- [Azure Virtual Network](virtual-network.md) - Bastion deploys into AzureBastionSubnet within a VNet
- [Azure Firewall](azure-firewall.md) - Co-exists in same VNet without UDR hairpinning
- [DDoS Protection](ddos-protection.md) - Applies to Bastion public IP
- [ExpressRoute](expressroute.md) - Required for private-only Bastion deployment
- [Network Watcher](network-watcher.md) - NSG flow logs and Traffic Analytics complement Bastion audit logging

---

## Source articles

| Article | Date |
|---|---|
| `bastion-overview.md` | 2025-01-30 |
| `configuration-settings.md` | 2025-01-30 |
| `bastion-sku-comparison.md` | 2025-01-30 |
| `bastion-nsg.md` | 2025-01-30 |
| `design-architecture.md` | 2025-01-30 |
| `bastion-faq.md` | 2025-12-10 |
| `native-client.md` | 2025-01-30 |
| `session-recording.md` | 2025-01-30 |
| `secure-bastion.md` | 2025-08-28 |
| `vnet-peering.md` | 2025-01-30 |
| `cost-optimization.md` | 2025-01-30 |
| `private-only-deployment.md` | 2025-01-30 |
| `monitor-bastion.md` | 2025-01-30 |
| `configure-host-scaling.md` | 2025-01-30 |
| `shareable-link.md` | 2025-01-30 |
| `whats-new.md` | 2025-03-13 — **delta read 2026-04-10** |
| `bastion-connect-to-aks-private-cluster.md` | 2025-08 (Public Preview) — **new** |
| `bastion-entra-id-authentication.md` | referenced — Entra ID RDP portal preview |
```

---

## ✅ RECOMPILE 4 — Network Security Design

**File:** `wiki/concepts/network-security-design.md`

The full updated page is very large, so here are the **changed and added sections only** (all other sections are unchanged and should be preserved as-is from the existing page):

**Header line — update to:**
```markdown
> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current
```

**In the "Zero Trust network principles" section — replace the "Zero Trust hardening checklist" subsection entirely with the following expanded version:**

```markdown
### Zero Trust hardening checklist — per service (from official Zero Trust recommendations, updated 2026-03-17)

An automated assessment of these controls is available via the [Zero Trust Assessment](/security/zero-trust/assessment) tool, which evaluates your Azure environment's configuration programmatically across these checks.

#### Azure DDoS Protection

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| DDoS Protection enabled for all public IPs in VNets | High | Low | Low |
| Metrics enabled for DDoS-protected public IPs | Medium | Low | Low |
| Diagnostic logging enabled for DDoS-protected public IPs | Medium | Low | Low |

> Without DDoS Protection, public IPs for Application Gateways, Load Balancers, Azure Firewalls, Bastion, VPN Gateways, and VMs remain exposed to attacks that can exhaust bandwidth and cause cascading outages.

#### Azure Firewall

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| Outbound VNet traffic routed through Azure Firewall | High | Low | Medium |
| Threat Intelligence enabled in Deny mode | High | Low | Low |
| IDPS inspection enabled in Deny mode *(Premium only)* | High | Low | Low |
| Outbound TLS inspection enabled *(Premium only)* | High | Low | Low |
| Diagnostic logging enabled | High | Low | Low |

> **Threat Intelligence:** Requires Standard or Premium; Basic supports Alert mode only.
> **IDPS:** Signature-based L3–L7 detection; applies to inbound, spoke-to-spoke, and outbound traffic including on-premises traffic over VPN/ER; signatures continuously updated by Microsoft.
> **TLS inspection:** Requires a CA certificate stored in Azure Key Vault; decrypts, inspects, and re-encrypts; enables IDPS to see encrypted payloads.
> **SNAT note:** For high-traffic workloads at risk of SNAT port exhaustion, deploy NAT Gateway on the AzureFirewallSubnet — NAT Gateway provides 64,512 SNAT ports per public IP vs. Azure Firewall's 2,496 SNAT ports per public IP per instance. No double NAT occurs.

#### Application Gateway WAF

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| WAF enabled in Prevention mode | High | Low | Low |
| Request body inspection enabled | High | Low | Low |
| Default rule set (DRS/CRS) enabled | High | Low | Low |
| Bot protection rule set enabled | High | Low | Low |
| HTTP DDoS protection rule set enabled | High | Low | Low |
| Rate limiting configured | High | Low | Medium |
| JavaScript challenge enabled | Medium | Low | Low |
| Diagnostic logging enabled | High | Low | Low |

> **Request body inspection:** When disabled, attackers can embed SQLi/XSS/command injection in POST/PUT/PATCH bodies, bypassing all rule evaluation — direct path to exploitation.
> **HTTP DDoS rule set:** Distinct from DDoS Network/IP Protection; detects HTTP flood and Slowloris attacks that target application-layer connection pools and threads.
> **JavaScript challenge:** Proves request originates from a real browser (executes JS snippet for cookie); blocks credential-stuffing bots and scrapers without user-visible friction.

#### Azure Front Door WAF

| Check | Risk level | User impact | Implementation cost |
|---|---|---|---|
| WAF enabled in Prevention mode | High | Low | Low |
| Request body inspection enabled | High | Low | Low |
| Default rule set assigned | High | Low | Low |
| Bot protection rule set enabled | High | Low | Low |
| Rate limiting configured | High | Low | Medium |
| JavaScript challenge enabled | Medium | Low | Low |
| CAPTCHA challenge enabled | Medium | Low | Low |
| Diagnostic logging enabled | High | Low | Low |

> **CAPTCHA challenge (Front Door only):** Presents interactive challenge to humans for requests that JavaScript challenge cannot fully classify; blocks sophisticated bots that can execute JavaScript but cannot solve visual CAPTCHAs.
```

**In the "Source articles" table at the end — append these rows:**

```markdown
| `raw/articles/networking/security/zero-trust-network-security.md` | Raw Azure docs | Master Zero Trust recommendations index; risk/impact/cost table; Automated Assessment reference; 2026-03-17 |
| `raw/articles/networking/security/zero-trust-azure-firewall.md` | Raw Azure docs | Firewall-specific Zero Trust checks with full remediation detail; NAT GW + Firewall SNAT comparison; 2026-03-17 |
| `raw/articles/networking/security/zero-trust-ddos-protection.md` | Raw Azure docs | DDoS-specific Zero Trust checks; metrics and diagnostic logging guidance; 2026-03-17 |
| `raw/articles/networking/security/zero-trust-application-gateway-waf.md` | Raw Azure docs | App GW WAF checks; request body inspection; HTTP DDoS rule set; JS challenge; 2026-03-17 |
| `raw/articles/networking/security/zero-trust-front-door-waf.md` | Raw Azure docs | Front Door WAF checks; CAPTCHA challenge; JS challenge; prevention mode; 2026-03-17 |
```

---

Now the four decisions logs:

---

## 📋 DECISIONS LOG 1

**File:** `.squad/decisions/inbox/atlas-expressroute.md`

```markdown