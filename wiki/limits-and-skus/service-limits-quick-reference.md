# Azure Networking — Service Limits Quick Reference

> **Compiled:** 2026-04-10 | **Source:** Compiled wiki service pages | **Status:** current

> ⚠️ All values tagged `[VERIFY]` — confirm against live Azure docs before relying on these in architecture decisions. Reference: [Azure subscription and service limits](https://learn.microsoft.com/azure/azure-resource-manager/management/azure-subscription-service-limits)

---

## Azure Virtual Network

| Limit | Value | Notes |
|---|---|---|
| VNets per subscription per region | 1,000 [VERIFY] | |
| Subnets per VNet | 3,000 [VERIFY] | |
| Minimum IPv4 subnet size | /29 | Azure reserves 5 IPs per subnet (first 4 + last) |
| IPv6 subnet size | Exactly /64 | |
| Peered VNets per VNet (default) | 500 [VERIFY] | |
| Peered VNets per VNet (with VNet Manager) | 1,000 [VERIFY] | |
| NSG rules per NSG | 1,000 [VERIFY] | |
| NSG rule priority range | 100–4096 | |
| Service endpoints per VNet | No limit | Individual services may limit subnets |
| VNet address space updates | Allowed without redeployment | |

---

## Azure Load Balancer

| Limit | Value | Notes |
|---|---|---|
| SNAT ports per public frontend IP | 64,000 [VERIFY] | |
| Default SNAT ports — pool 1–50 VMs | 1,024 per VM [VERIFY] | |
| Default SNAT ports — pool 51–100 VMs | 512 per VM [VERIFY] | |
| Default SNAT ports — pool 101–200 VMs | 256 per VM [VERIFY] | |
| Default SNAT ports — pool 401–800 VMs | 64 per VM [VERIFY] | |
| SNAT idle timeout range | 4–120 minutes | Configurable via outbound rules |
| Standard LB SLA | 99.99% [VERIFY] | Requires ≥2 healthy backend instances |
| Health probe source IP | 168.63.129.16 | Must be allowed in NSGs |
| Health probe default interval | 5 seconds | |
| HTTP/S probe timeout | 30 seconds | |
| Backend pool scope | Single VNet | Cannot span VNets directly |
| Basic LB | **RETIRED September 30, 2025** | Migrate to Standard |
| Inbound NAT rule V1 retirement | September 30, 2027 | Migrate to V2 |
| numberOfProbes property retirement | September 1, 2027 | Use probeThreshold instead |

---

## Azure NAT Gateway

| Limit | Value | Notes |
|---|---|---|
| Public IP addresses per NAT Gateway | 1–16 [VERIFY] | |
| SNAT ports per public IP | 64,512 [VERIFY] | Per public IP address |
| Total SNAT ports per NAT Gateway (16 IPs) | ~1,032,192 [VERIFY] | |
| Idle timeout | 4–120 minutes | Configurable |
| NAT Gateway SLA | 99.99% [VERIFY] | |
| Subnets per NAT Gateway | Up to 1,000 [VERIFY] | |
| Cannot be used with | Basic SKU LB, Basic public IPs, IPv6 (for SNAT) | |

---

## Azure Bastion

| Limit | Value | Notes |
|---|---|---|
| AzureBastionSubnet minimum size | /26 | Must be named exactly `AzureBastionSubnet` |
| Public IP SKU required | Standard, Static | Not needed for Premium private-only |
| Basic SKU — instances | 2 (fixed) | Cannot scale |
| Standard/Premium SKU — instances | 2–50 [VERIFY] | |
| Concurrent RDP per instance | 20 | |
| Concurrent SSH per instance | 40 | |
| Max concurrent RDP (50 instances) | 1,000 [VERIFY] | |
| Max concurrent SSH (50 instances) | 2,000 [VERIFY] | |
| Shareable links per Bastion resource | 500 [VERIFY] | |
| Max browser resolution | 1920x1080 | |
| IPv6 support | Not supported | IPv4 only |
| UDR on AzureBastionSubnet | Not supported | |

---

## Azure ExpressRoute

| Limit | Value | Notes |
|---|---|---|
| Circuit bandwidths available | 50 Mbps, 100 Mbps, 200 Mbps, 500 Mbps, 1 Gbps, 2 Gbps, 5 Gbps, 10 Gbps | Provider circuits |
| ExpressRoute Direct speeds | 10, 100, 400 Gbps | Direct connection to Microsoft global network |
| BGP routes per circuit — Standard | 4,000 [VERIFY] | |
| BGP routes per circuit — Premium | 10,000 [VERIFY] | |
| VNet links per circuit — Standard (default) | 10 [VERIFY] | |
| VNet links per circuit — Premium | 100+ (scales with bandwidth) [VERIFY] | |
| Built-in redundancy | 2 connections to 2 MSEEs | Both should run active-active |
| BFD failure detection | <1 second [VERIFY] | vs ~3 minutes without BFD |
| Traffic Collector sampling | 1:4096 [VERIFY] | Up to 300,000 flows/min |

---

## VPN Gateway

| Limit | Value | Notes |
|---|---|---|
| S2S connections per gateway | Varies by SKU [VERIFY] | Basic: 10; VpnGw1-5: 30–100 |
| P2S concurrent connections | Varies by SKU [VERIFY] | Basic: 128; VpnGw1: 250; VpnGw2: 500; VpnGw3: 1,000; VpnGw4/5: 5,000–10,000 |
| Gateway throughput | Varies by SKU [VERIFY] | VpnGw1: 650 Mbps; VpnGw5: 10 Gbps |
| Basic SKU | Legacy; no AZ support, no active-active, no BGP | Consider upgrade |
| IPsec/IKE policies | Customizable | Numerous cipher/DH group options |

---

## Azure Firewall

| Limit | Value | Notes |
|---|---|---|
| Rules per Firewall Policy | 20,000 [VERIFY] | |
| DNAT rules per policy | 298 [VERIFY] | |
| Firewall throughput (Standard) | ~30 Gbps [VERIFY] | With forced tunneling: ~10 Gbps |
| Firewall throughput (Premium) | ~100 Gbps [VERIFY] | |
| Private ranges (SNAT suppression) | Configurable via policy | RFC 1918 + custom CIDRs |

---

## Application Gateway

| Limit | Value | Notes |
|---|---|---|
| Max instances — v2 SKU | 125 [VERIFY] | Autoscaling up to max |
| Min instances — v2 SKU (for SLA) | 2 [VERIFY] | |
| Listeners per gateway | 200 [VERIFY] | |
| Backend pools | 100 [VERIFY] | |
| Backend servers | 1,200 [VERIFY] | |
| HTTP headers max size | 32 KB [VERIFY] | |
| TLS certificate key size max | 4,096-bit RSA [VERIFY] | |
| WAF custom rules | 100 [VERIFY] | |

---

## Private Link / Private Endpoints

| Limit | Value | Notes |
|---|---|---|
| Private Endpoints per VNet (default) | 1,000 [VERIFY] | |
| Private Endpoints per VNet (High Scale, opt-in) | 5,000 [VERIFY] | |
| Peered-VNet PE aggregate (High Scale) | 20,000 [VERIFY] | |
| NAT IPs per Private Link Service | 8 max [VERIFY] | Minimum 1 must remain |
| PLS idle connection timeout | ~300 seconds [VERIFY] | Use TCP keepalives below this |
| Private Link SLA | 99.99% [VERIFY] | |
| Service Endpoints per VNet | No limit [VERIFY] | |
| NSP perimeter resources | Up to limit per region [VERIFY] | See NSP docs |

---

## Azure DNS

| Limit | Value | Notes |
|---|---|---|
| DNS zones per subscription | 250 (public) [VERIFY] | |
| Record sets per zone (public) | 10,000 [VERIFY] | |
| Private zones per subscription | 1,000 [VERIFY] | |
| Virtual network links per private zone | 1,000 [VERIFY] | |
| VNets with autoregistration per private zone | 1 [VERIFY] | Only 1 VNet can have autoregistration per zone |
| Private DNS Private Resolver — inbound endpoints per VNet | 5 [VERIFY] | |
| Rulesets per resolver | 5 [VERIFY] | |

---

## DDoS Protection

| Limit | Value | Notes |
|---|---|---|
| DDoS Network Protection — mitigation threshold (TCP SYN) | ~10,000–200,000+ pps [VERIFY] | Adaptive tuning; not a fixed customer limit |
| Protected public IP resources per plan | Unlimited [VERIFY] | All public IPs in protected VNets covered |
| DDoS IP Protection — per-resource protection | Single public IP | Lower cost; no per-VNet blanket coverage |
| DDoS Network Protection SLA | 99.99% [VERIFY] | |

---

## Azure Front Door

| Limit | Value | Notes |
|---|---|---|
| Origins per origin group | 50 [VERIFY] | |
| Front Door profiles per subscription | 500 [VERIFY] | |
| Rules per rules engine configuration | 25 [VERIFY] | |
| Custom domains per profile | 500 [VERIFY] | |
| Edge PoP count | 100+ locations globally [VERIFY] | |
| WAF custom rules | 100 [VERIFY] | |

---

## Traffic Manager

| Limit | Value | Notes |
|---|---|---|
| Endpoints per profile | 200 [VERIFY] | |
| Nested profiles depth | 10 [VERIFY] | |
| Profile TTL (DNS) | Configurable; minimum 0 seconds [VERIFY] | |
| Routing methods | 6: Priority, Weighted, Performance, Geographic, Multivalue, Subnet | |

---

## Sources (wiki service pages)

| Service | Wiki page | Compiled |
|---|---|---|
| Virtual Network | [virtual-network.md](../services/virtual-network.md) | 2025-07-31 |
| Load Balancer | [load-balancer.md](../services/load-balancer.md) | 2025-01-30 |
| NAT Gateway | [nat-gateway.md](../services/nat-gateway.md) | 2026-04-08 |
| Bastion | [bastion.md](../services/bastion.md) | 2025-01-30 |
| ExpressRoute | [expressroute.md](../services/expressroute.md) | 2025-01-27 |
| VPN Gateway | [vpn-gateway.md](../services/vpn-gateway.md) | 2025-11-25 |
| Azure Firewall | [azure-firewall.md](../services/azure-firewall.md) | 2025-07-14 |
| Application Gateway | [application-gateway.md](../services/application-gateway.md) | 2025-07-15 |
| Private Link | [private-link.md](../services/private-link.md) | 2025-07-30 |
| Azure DNS | [dns.md](../services/dns.md) | 2025-07-31 |
| DDoS Protection | [ddos-protection.md](../services/ddos-protection.md) | 2026-04-08 |
| Azure Front Door | [front-door.md](../services/front-door.md) | 2026-04-09 |
| Traffic Manager | [traffic-manager.md](../services/traffic-manager.md) | 2026-04-09 |
