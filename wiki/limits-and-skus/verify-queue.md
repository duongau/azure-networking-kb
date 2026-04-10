# Wiki [VERIFY] queue
> Auto-generated: 2026-04-10 | Scan: all wiki/ markdown files
> Use this page to systematically resolve unverified limits, prices, and SLA values.

## Status legend
- ⬜ **Unverified** — needs confirmation against live Azure docs
- ✅ **Confirmed** — value verified correct
- 🔄 **Updated** — value corrected

---

**Total:** 752 unverified items across 53 files

---

## comparisons\app-gateway-vs-front-door.md (6)

| Line | Excerpt | Status |
|---|---|---|
| 16 | \| **TLS version minimum** \| TLS 1.2 (TLS 1.0/1.1 ended August 31, 2025 [VERIFY]) \| TLS 1.2 (TLS 1.0/1.1 not supported) \| | ⬜ |
| 33 | \| **Pricing model** \| Hourly fixed + per capacity unit (CU) \| Monthly base fee (~$35 Std / ~$330 Premium [VERIFY]) + per | ⬜ |
| 34 | \| **WAF pricing** \| WAF_v2: ~$0.443/hr + $0.0144/CU [VERIFY] \| WAF included in base fee for Premium; Standard: custom ru | ⬜ |
| 35 | \| **SLA** \| 99.95% [VERIFY] \| 99.99% [VERIFY] \| | ⬜ |
| 67 | - You need **DHE cipher suites** (v1 only — v2 dropped DHE; Front Door also dropping DHE April 2026 [VERIFY]) | ⬜ |
| 133 | ## Pricing quick comparison [VERIFY all]## comparisons\firewall-sku-comparison.md (11 items) | ⬜ |
| 14 | \| **Max throughput** \| 250 Mbps [VERIFY] \| 30 Gbps [VERIFY] \| 100 Gbps [VERIFY] (10 Gbps with IDPS Alert+Deny [VERIFY])  | ⬜ |
| 15 | \| **Fat flow (single TCP)** \| N/A \| 1 Gbps \| 10 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY] \| | ⬜ |
| 17 | \| **Initial throughput (before scale-out)** \| 250 Mbps [VERIFY] \| ~3 Gbps [VERIFY] \| ~18 Gbps [VERIFY] \| | ⬜ |
| 35 | \| **PCI DSS compliance** \| ❌ \| ❌ \| ✅ [VERIFY] \| | ⬜ |
| 37 | \| **SLA** \| [VERIFY] \| [VERIFY] \| [VERIFY] \| | ⬜ |
| 48 | \| Customizable signature overrides \| Up to 10,000 [VERIFY] \| | ⬜ |
| 52 | \| Throughput impact (Alert+Deny) \| Reduces effective throughput to 10 Gbps aggregate [VERIFY]; single TCP flow max 300 M | ⬜ |
| 129 | │   └─ YES → Azure Firewall Premium (only SKU with PCI DSS compliance [VERIFY]) | ⬜ |
| 160 | ## Service limits [VERIFY all] | ⬜ |
| 164 | \| Max public IPs \| Multiple (fewer than Std) [VERIFY] \| 250 \| 250 \| | ⬜ |
| 165 | \| SNAT ports per public IP \| 2,496 [VERIFY] \| 2,496 [VERIFY] \| 2,496 [VERIFY] \|## comparisons\firewall-vs-nsg.md (5 items) | ⬜ |
| 26 | \| **Cost** \| ✅ Free — included with VNet \| ✅ Free — included with NSG \| 💰 Hourly compute + per-GB data processing; Stan | ⬜ |
| 27 | \| **Scale** \| Per-VNet; up to 1,000 rules per NSG [VERIFY] \| Up to 50 ASG members per NSG on PE subnets [VERIFY] \| Stand | ⬜ |
| 62 | - Up to 50 ASG members per NSG on Private Endpoint subnets [VERIFY] — exceeding 50 silently causes PE connection failure | ⬜ |
| 89 | - **Alert + Deny mode:** runs inline after rule engine; silently drops matched sessions (no TCP RST sent); reduces effec | ⬜ |
| 142 | \| No per-GB cost tolerance \| ✅ (free) \| ❌ ($0.016/GB+ data processing [VERIFY]) \|## comparisons\load-balancing-options.md (4 items) | ⬜ |
| 24 | \| **SLA** \| 99.99% [VERIFY] (Standard, ≥2 healthy backends) \| 99.95% [VERIFY] (Standard_v2 / WAF_v2) \| 99.99% [VERIFY] \| | ⬜ |
| 25 | \| **Pricing model** \| Hourly (rule count) + data processed \| Hourly fixed + capacity units (CU) \| Monthly base (~$35 Std | ⬜ |
| 95 | - Cost of Premium profile (~$330/month [VERIFY]) is not justified for small workloads | ⬜ |
| 156 | ## Service limits (key figures) [VERIFY all]## comparisons\private-endpoints-vs-service-endpoints.md (2 items) | ⬜ |
| 22 | \| **Cost** \| ✅ Free — no extra charge \| 💰 Per-PE hourly charge + per-GB data processing [VERIFY] \| | ⬜ |
| 141 | ## Key limits [VERIFY all]## comparisons\virtual-wan-vs-hub-spoke.md (12 items) | ⬜ |
| 18 | \| **P2S user VPN scale** \| Per-SKU limit (VpnGw1AZ: 128 SSTP + 250 IKEv2) \| Up to 100,000 concurrent users / 200  | ⬜ |
| 19 | \| **ExpressRoute integration** \| Standard ERGateway in hub VNet \| Hub ER gateway; up to 20 Gbps (10 SU) [VERIFY]; | ⬜ |
| 28 | \| **Hub base cost** \| VNet is free; pay for gateway SKUs, Firewall, peering data \| $0.25/hr per Standard hub [VER | ⬜ |
| 29 | \| **Hub routing throughput** \| Firewall/NVA throughput (30–100 Gbps Firewall [VERIFY]) \| Hub router: 3 Gbps (2 RI | ⬜ |
| 30 | \| **Max spoke VMs** \| 500 peerings/hub VNet [VERIFY]; ~unlimited VMs across spokes \| Up to 50,000 VMs at 50 RIUs  | ⬜ |
| 31 | \| **Route limits** \| 400 UDRs/route table [VERIFY] (1,000 with AVNM) \| 10,000 routes total per hub (all connected | ⬜ |
| 55 | \| Hub VNet \| Free \| $0.25/hr per hub [VERIFY] \| | ⬜ |
| 56 | \| VPN Gateway \| VpnGw1AZ–5AZ hourly rates [VERIFY] \| S2S VPN: ~$0.361/hr per scale unit [VERIFY — CONFLICT in sou | ⬜ |
| 57 | \| ER Gateway \| ERGw1Az–ErGwScale hourly rates \| ER gateway: $2/hr per scale unit [VERIFY] \| | ⬜ |
| 58 | \| Data processing \| VNet peering charges per GB both directions \| Hub data processing fee for VNet-to-VNet flows  | ⬜ |
| 59 | \| Azure Firewall \| Standard: ~$1.25/hr + $0.016/GB [VERIFY] \| Same Firewall pricing; Routing Intent itself is fre | ⬜ |
| 60 | \| NVA (third-party) \| NVA VM compute + licensing \| Hub NVA Infrastructure Units: ~$0.25/IU/hr [VERIFY] + vendor l | ⬜ |

## comparisons\vpn-gateway-vs-expressroute.md (14)

| Line | Excerpt | Status |
|---|---|---|
| 16 | \| **Max bandwidth** \| ~10 Gbps (VpnGw5AZ aggregate) [VERIFY] \| 50 Mbps – 400 Gbps (ExpressRoute Direct) \|         | ⬜ |
| 18 | \| **SLA** \| 99.9% (active-standby) [VERIFY] \| 99.95% [VERIFY] \| | ⬜ |
| 24 | \| **Max S2S tunnels (single gateway)** \| 100 [VERIFY] (VpnGw4/5); 30 (VpnGw1–3); 10 (Basic) \| Up to 4 circuits fr | ⬜ |
| 41 | \| **VpnGw1AZ** \| Gen2 \| ✅ \| 30 [VERIFY] \| Entry production; 128 SSTP + 250 IKEv2 P2S \| Required for all new prod | ⬜ |
| 42 | \| **VpnGw2AZ** \| Gen2 \| ✅ \| 30 [VERIFY] \| NAT supported (minimum SKU for overlapping spaces) \| — \| | ⬜ |
| 43 | \| **VpnGw3AZ** \| Gen2 \| ✅ \| 30 [VERIFY] \| Higher throughput \| — \| | ⬜ |
| 44 | \| **VpnGw4AZ** \| Gen2 \| ✅ \| 100 [VERIFY] \| Large enterprise \| — \| | ⬜ |
| 45 | \| **VpnGw5AZ** \| Gen2 \| ✅ \| 100 [VERIFY] \| Highest performance \| — \| | ⬜ |
| 55 | \| **Standard / ERGw1Az** \| 4 \| [VERIFY — in include file] \| ❌ \| ✅ \| | ⬜ |
| 56 | \| **High Performance / ERGw2Az** \| 8 \| [VERIFY] \| ❌ \| ✅ \| | ⬜ |
| 57 | \| **Ultra Performance / ErGw3Az** \| 16 \| [VERIFY] \| ✅ \| ✅ \| | ⬜ |
| 64 | \| **Local** \| 1–2 regions near peering location \| Data transfer included in port charge [VERIFY] \| [VERIFY] \| No  | ⬜ |
| 65 | \| **Standard** \| Same geopolitical area \| Metered or Unlimited \| 10 [VERIFY] \| — \| | ⬜ |
| 66 | \| **Premium** \| All Azure regions globally \| Metered or Unlimited \| Up to 100 [VERIFY] \| Required for M365; requi | ⬜ |

## concepts\azure-networking-fundamentals.md (16)

| Line | Excerpt | Status |
|---|---|---|
| 89 | \| VNet encryption \| Encrypts VM-to-VM traffic within and across peered VNets (requires supported VM SKUs) [VERIFY | ⬜ |
| 203 | - **Media-based streaming workloads?** → Verizon Media Streaming via Azure [VERIFY — check current availability] | ⬜ |
| 216 | \| **VPN Gateway (S2S)** \| Smaller sites; moderate BW; cost-sensitive; where ExpressRoute is unavailable \| IPsec  | ⬜ |
| 217 | \| **ExpressRoute (provider circuit)** \| Low latency, high BW, private connectivity to Azure and M365; compliance | ⬜ |
| 218 | \| **ExpressRoute Direct** \| 10/100 Gbps dedicated port directly into Microsoft network \| Direct port into Micros | ⬜ |
| 219 | \| **Virtual WAN (managed hub)** \| Multi-branch, multi-region, SD-WAN; managed hub routing \| VPN, ER, or SD-WAN;  | ⬜ |
| 248 | \| East US ↔ West US 2 \| ~68 ms [VERIFY] \| | ⬜ |
| 249 | \| West US ↔ Japan East \| ~107 ms [VERIFY] \| | ⬜ |
| 250 | \| West US ↔ North Europe \| ~139 ms [VERIFY] \| | ⬜ |
| 251 | \| East US ↔ West Europe \| ~80–90 ms [VERIFY] \| | ⬜ |
| 252 | \| US regions (same geography) \| 18–50 ms [VERIFY] \| | ⬜ |
| 254 | > [VERIFY] — All latency figures should be validated against the current `azure-network-latency.md` source artic | ⬜ |
| 266 | > **Status:** Limited General Availability (GA) — sign-up required [VERIFY current availability status].         | ⬜ |
| 272 | \| Connections Per Second (CPS) \| Up to **25× improvement** over baseline for high-concurrency workloads [VERIFY] | ⬜ |
| 273 | \| Total Active Connections \| Significantly increased ceiling [VERIFY] \| | ⬜ |
| 294 | - Supported regions include: East US, West US, West US 2/3, North/South Central US, West Central US, North/West  | ⬜ |

## concepts\dns-zones-and-records.md (5)

| Line | Excerpt | Status |
|---|---|---|
| 56 | - Limit: 50 alias record sets per Azure resource [VERIFY] | ⬜ |
| 150 | \| DNS zones per subscription \| See Azure DNS Limits [VERIFY] \| Soft limit \| | ⬜ |
| 151 | \| Record sets per zone \| See Azure DNS Limits [VERIFY] \| \| | ⬜ |
| 153 | \| Alias record sets per resource \| 50 [VERIFY] \| \| | ⬜ |
| 156 | \| DNS servers per VNet \| 20 [VERIFY] \| \| | ⬜ |

## concepts\flow-logs.md (4)

| Line | Excerpt | Status |
|---|---|---|
| 58 | \| **Azure Storage Account** \| Long-term retention, compliance archival \| GPv2 required; up to 1 year retention [V | ⬜ |
| 64 | - Storage account: configurable up to 1 year [VERIFY] | ⬜ |
| 124 | \| Flow logs (NSG or VNet) \| Per GB stored; storage account charges separate [VERIFY] \| | ⬜ |
| 125 | \| Traffic Analytics \| Per GB processed + Log Analytics workspace cost [VERIFY] \| | ⬜ |

## concepts\hub-spoke-networking.md (17)

| Line | Excerpt | Status |
|---|---|---|
| 17 | \| **Hub-spoke (DIY)** \| Medium — UDRs required for spoke-to-spoke and egress; BGP propagation must be disabled on | ⬜ |
| 18 | \| **Azure Virtual WAN** \| Low — hub router handles transitive routing automatically; no UDR management \| 500 VNet | ⬜ |
| 74 | \| **Backend / workload** \| VMs, AKS, App Service Environment VNet integration \| Size for workload; create as **pr | ⬜ |
| 100 | > ⚠️ **Peering is not free.** Data transferred across VNet peering links is charged per GB in both directions. I | ⬜ |
| 120 | \| Peering-learned routes \| VNet peering \| Yes — UDR with same or longer prefix [VERIFY: confirm UDR precedence o | ⬜ |
| 153 | \| **AVNM Routing Configs** \| AVNM manages and deploys route tables declaratively \| Low — policy-driven; up to 1, | ⬜ |
| 154 | \| **Virtual WAN hub router** \| Microsoft-managed; fully automatic transitive routing \| None from customer \| High | ⬜ |
| 162 | \| Spoke VNets per hub \| 500 peerings/VNet [VERIFY] \| 1,000 spoke VNets per hub config [VERIFY] \| 500 VNet connec | ⬜ |
| 163 | \| Route table entries \| 400 UDRs/table [VERIFY] \| 1,000 UDRs/table [VERIFY] \| Managed by hub router \| | ⬜ |
| 167 | \| Max routes per hub \| No hub-level limit; limited per route table \| 1,000 per table [VERIFY] \| 10,000 routes to | ⬜ |
| 185 | \| Single hub Firewall throughput is a bottleneck \| Firewall Standard max ~30 Gbps [VERIFY]; add second hub or up | ⬜ |
| 216 | \| Route table management \| Manual; up to 400 UDRs/table [VERIFY] \| Routing configurations; up to 1,000 UDRs/tabl | ⬜ |
| 224 | \| Spoke VNets per hub in connectivity config \| 1,000 [VERIFY] \| | ⬜ |
| 225 | \| Connected group size (spoke-to-spoke direct) \| 250 default (soft limit); 1,000 on request; 5,000 preview [VERI | ⬜ |
| 226 | \| UDRs per AVNM-managed route table \| 1,000 [VERIFY] \| | ⬜ |
| 295 | Link the DDoS Protection plan to **both** hub and spoke VNets before creating any public IPs. DDoS infrastructur | ⬜ |
| 310 | Peering traffic is billed per GB in both directions. In a hub-spoke design where all spoke egress (internet + sp | ⬜ |

## concepts\hybrid-connectivity.md (22)

| Line | Excerpt | Status |
|---|---|---|
| 17 | \| **VPN Gateway S2S** \| 99.9% [VERIFY] \| ~10 Gbps (VpnGw5AZ) [VERIFY] \| Variable — crosses public internet \| ✅ I | ⬜ |
| 18 | \| **ExpressRoute (provider circuit)** \| 99.95% [VERIFY] \| 50 Mbps – 10 Gbps \| Low, consistent, no internet jitter | ⬜ |
| 19 | \| **ExpressRoute Direct** \| 99.95% [VERIFY] \| 10 / 100 / 400 Gbps \| Lowest — direct into Microsoft network \| ❌ M | ⬜ |
| 20 | \| **Virtual WAN (S2S VPN)** \| 99.95% [VERIFY] \| 20 Gbps per hub [VERIFY] \| Variable — crosses public internet \|   | ⬜ |
| 21 | \| **Virtual WAN (ExpressRoute)** \| 99.95% [VERIFY] \| 20 Gbps per hub (10 scale units) [VERIFY] \| Low, consistent  | ⬜ |
| 22 | \| **Point-to-Site VPN (standalone)** \| 99.9% [VERIFY] \| Aggregate per SKU [VERIFY]; VpnGw1: 128 SSTP + 250 IKEv2  | ⬜ |
| 23 | \| **Virtual WAN P2S** \| 99.95% [VERIFY] \| Up to 100 Gbps / 100,000 users (200 scale units) [VERIFY] \| Variable —  | ⬜ |
| 25 | > All SLA, throughput, and pricing figures are **[VERIFY]** — check current Azure documentation and pricing pages | ⬜ |
| 107 | - Requires **Premium** SKU when circuits span geopolitical boundaries; Standard within same geopolitical area [V | ⬜ |
| 131 | \| Direct 100 Gbps / 400 Gbps \| 200,000 IPs [VERIFY] \| | ⬜ |
| 132 | \| Direct 10 Gbps \| 100,000 IPs [VERIFY] \| | ⬜ |
| 133 | \| Provider circuits ≤10 Gbps \| 25,000 IPs [VERIFY] \| | ⬜ |
| 148 | \| **Local** \| 1–2 Azure regions near the peering location \| Port charge includes data transfer (no separate egre | ⬜ |
| 149 | \| **Standard** \| All Azure regions in same geopolitical area \| Metered or Unlimited \| Up to 10 [VERIFY] \| — \|    | ⬜ |
| 150 | \| **Premium** \| All Azure regions globally (excl. national clouds) \| Metered or Unlimited \| Up to 100 [VERIFY] \| | ⬜ |
| 198 | \| **VpnGw4AZ** \| ✅ \| Large enterprise; up to 100 S2S tunnels [VERIFY] \| | ⬜ |
| 199 | \| **VpnGw5AZ** \| ✅ \| Maximum performance; up to 100 S2S tunnels [VERIFY] \| | ⬜ |
| 204 | Exact per-SKU aggregate throughput (Mbps/Gbps) and full P2S connection counts are in include files not fully cap | ⬜ |
| 209 | - Azure VPN Gateway default ASN: **65515** [VERIFY] | ⬜ |
| 222 | P2S connection limits (VpnGw1): **128 SSTP** and **250 IKEv2** connections (limits are independent per protocol) | ⬜ |
| 278 | \| P2S at scale \| Single gateway; limited P2S user count per SKU \| Up to 100,000 users per hub (200 scale units)  | ⬜ |
| 442 | - Higher SKU limits are defined in include files — **[VERIFY]** | ⬜ |

## concepts\ip-addressing.md (33)

| Line | Excerpt | Status |
|---|---|---|
| 22 | **Key constraint:** Addresses in `224.0.0.0/4` (multicast), `255.255.255.255/32` (broadcast), `127.0.0.0/8` (loop | ⬜ |
| 32 | \| **Standard v2** \| Static only \| Zone-redundant (always — cannot be zonal) [VERIFY] \| Closed to inbound; NSG req | ⬜ |
| 34 | \| **Basic** *(retiring)* \| Static or Dynamic \| None (non-zonal only) \| **Open to inbound by default** — no NSG re | ⬜ |
| 42 | - Basic must be migrated before September 30, 2025 [VERIFY]; after that date, Basic public IPs are decommissioned | ⬜ |
| 55 | Prefixes simplify firewall allow-listing: one CIDR covers all outbound IPs instead of individual entries. [VERIFY | ⬜ |
| 71 | - **Scale:** Up to 16 public IPs × 64,512 SNAT ports per IP ≈ **1,032,192 SNAT ports total** [VERIFY] | ⬜ |
| 102 | **Default SNAT port allocation by backend pool size:** [VERIFY all values] | ⬜ |
| 113 | Each public frontend IP on a Standard Load Balancer provides 64,000 [VERIFY] SNAT ports total to split across th | ⬜ |
| 119 | > ⚠️ **Breaking change — March 31, 2026:** New virtual networks created after this date default to **private sub | ⬜ |
| 148 | - NAT Gateway users are largely immune — ports are dynamically allocated on-demand from a shared pool up to ~1M  | ⬜ |
| 165 | \| **Add more public IPs to LB** \| Load Balancer outbound rules \| Each IP adds 64,000 [VERIFY] ports to the share | ⬜ |
| 167 | \| **Add more public IPs to NAT Gateway** (up to 16) \| NAT Gateway \| Each IP adds 64,512 ports [VERIFY] \|         | ⬜ |
| 191 | \| — \| `168.63.129.16/32` \| ❌ Azure platform-reserved — not assignable [VERIFY] \| | ⬜ |
| 205 | **Impact on small subnets:** [VERIFY] | ⬜ |
| 220 | \| VPN Gateway (`GatewaySubnet`) \| /29 [VERIFY] \| Microsoft recommends /27 or larger for production \| | ⬜ |
| 221 | \| Azure Bastion (`AzureBastionSubnet`) \| /26 [VERIFY] \| Smaller sizes not supported \| | ⬜ |
| 222 | \| Azure Firewall (`AzureFirewallSubnet`) \| /26 [VERIFY] \| Smaller sizes not supported \| | ⬜ |
| 223 | \| Azure DNS Private Resolver (inbound/outbound) \| /28 [VERIFY] \| Dedicated delegated subnet required; `/28` to ` | ⬜ |
| 224 | \| Application Gateway v2 \| /24 recommended [VERIFY] \| Can autoscale; needs room to grow \| | ⬜ |
| 243 | Azure supports **dual-stack VNets**: a VNet can have both an IPv4 prefix and an IPv6 prefix (`/48` or larger; su | ⬜ |
| 252 | \| NAT Gateway (StandardV2) \| ✅ IPv4 + IPv6 \| Up to 16 IPv4 + 16 IPv6 public IPs [VERIFY] \| | ⬜ |
| 253 | \| Application Gateway \| ❌ [VERIFY] \| Not confirmed in source articles — verify before relying on this \|         | ⬜ |
| 254 | \| Azure Firewall \| ❌ [VERIFY] \| Not confirmed in source articles — verify before relying on this \| | ⬜ |
| 255 | \| VPN Gateway \| ❌ [VERIFY] \| Not confirmed in source articles \| | ⬜ |
| 256 | \| Azure Bastion \| ❌ [VERIFY] \| Not confirmed in source articles \| | ⬜ |
| 261 | - IPv6 subnets must be exactly `/64` — no other prefix length is valid [VERIFY] | ⬜ |
| 263 | - Azure-provided DNS (`168.63.129.16`) handles AAAA record resolution for VNet resources [VERIFY] | ⬜ |
| 268 | Public IPv6 prefixes can be allocated for outbound connectivity. NAT Gateway StandardV2 supports `/124` IPv6 pre | ⬜ |
| 297 | \| **Custom DNS servers** \| Set per VNet; up to 20 DNS server IPs [VERIFY]; overrides the default for all VMs in  | ⬜ |
| 302 | **DNS server limit per VNet:** 20 [VERIFY] | ⬜ |
| 325 | \| 2 \| **Basic public IP retires September 30, 2025** \| Resources using Basic public IPs will lose connectivity a | ⬜ |
| 328 | \| 5 \| **IPv6 not supported by all services** \| Dual-stack design may break at certain hops (Firewall, App Gatewa | ⬜ |
| 333 | \| 10 \| **NAT Gateway cannot attach to gateway subnets** \| VPN Gateway subnets cannot use NAT Gateway for outboun | ⬜ |

## concepts\monitoring.md (6)

| Line | Excerpt | Status |
|---|---|---|
| 109 | \| Network Watcher (monitoring, diagnostics) \| No separate charge for most tools; packet capture and connection m | ⬜ |
| 110 | \| Flow logs (NSG or VNet) \| Data volume charges for logs written to storage [VERIFY] \| | ⬜ |
| 111 | \| Traffic Analytics \| Charged per GB of data processed [VERIFY] \| | ⬜ |
| 112 | \| Log Analytics workspace \| Standard Azure Monitor log ingestion and retention pricing [VERIFY] \| | ⬜ |
| 122 | \| Packet capture sessions (concurrent) \| Limited per region [VERIFY] \| See Azure subscription limits \| | ⬜ |
| 123 | \| Traffic Analytics processing frequency \| Every 10 minutes or 60 minutes [VERIFY] \| Configurable per workspace  | ⬜ |

## concepts\network-security-design.md (6)

| Line | Excerpt | Status |
|---|---|---|
| 62 | \| Rule priority range \| 100–4,096 (lower number = higher priority; first match wins) [VERIFY] \| | ⬜ |
| 82 | \| Limit \| 50 ASG members per NSG on a PE subnet [VERIFY] — exceeding this silently causes connection failures \|   | ⬜ |
| 128 | - **Scale:** Standard Firewall autoscales to 30 Gbps aggregate throughput [VERIFY]; Premium to 100 Gbps [VERIFY] | ⬜ |
| 310 | \| **DDoS IP Protection** \| Per public IP resource \| Per-IP per month [VERIFY] \| Yes \| No \| No \| No \| | ⬜ |
| 311 | \| **DDoS Network Protection** \| Per VNet (plan covers all IPs in linked VNets, up to 100 IPs included) [VERIFY]  | ⬜ |
| 336 | \| Detection-to-mitigation time \| 30–60 seconds [VERIFY] \| | ⬜ |

## concepts\network-security-groups.md (1)

| Line | Excerpt | Status |
|---|---|---|
| 83 | \| Limit per NSG \| 50 ASG members per NSG on a private endpoint subnet [VERIFY] \| | ⬜ |

## concepts\private-access-to-paas.md (9)

| Line | Excerpt | Status |
|---|---|---|
| 81 | **Onboarded NSP services (Preview):** Cosmos DB, SQL DB, Azure OpenAI [VERIFY] | ⬜ |
| 109 | \| Private Link for IPv6-only traffic \| Private Link Service supports IPv4 traffic only [VERIFY] \| | ⬜ |
| 148 | \| **Extra cost** \| ❌ No \| ✅ Yes — charged per hour + data processed [VERIFY] \| | ⬜ |
| 158 | \| Private Endpoints per VNet (default) \| 1,000 [VERIFY] \| Subject to Azure Private Link limits \| | ⬜ |
| 159 | \| Private Endpoints per VNet (High Scale, opt-in) \| 5,000 [VERIFY] \| Peered-VNet aggregate: 20,000 \| | ⬜ |
| 160 | \| NAT IPs per Private Link Service \| 8 (max) [VERIFY] \| Minimum 1 must be maintained \| | ⬜ |
| 161 | \| PLS idle timeout \| ~5 minutes (300 seconds) [VERIFY] \| Configure TCP keepalives below this threshold \|         | ⬜ |
| 162 | \| PLS: IPv4 only \| No IPv6 support [VERIFY] \| \| | ⬜ |
| 163 | \| Service Endpoints per VNet \| No limit [VERIFY] \| Individual services may limit subnet count \| | ⬜ |

## concepts\routing.md (5)

| Line | Excerpt | Status |
|---|---|---|
| 51 | \| **VNet Gateway** \| Send traffic into the VPN gateway \| VPN gateways **only** — ExpressRoute gateway is NOT a va | ⬜ |
| 56 | ### Limits [VERIFY] | ⬜ |
| 100 | \| VPN Gateway (S2S) \| BGP peering between Azure gateway (ASN 65515 [VERIFY]) and on-premises CPE \| On-premises p | ⬜ |
| 110 | \| **Azure internal private** \| 65515, 65517, 65518, 65519, 65520 \| Azure VPN Gateway default = 65515 [VERIFY] \|  | ⬜ |
| 266 | ### Virtual WAN routing limits [VERIFY] | ⬜ |

## concepts\snat.md (6)

| Line | Excerpt | Status |
|---|---|---|
| 92 | \| SNAT ports per frontend IP \| **64,000** [VERIFY] \| | ⬜ |
| 106 | \| SNAT ports per public IP per Firewall instance \| **2,496** [VERIFY] \| | ⬜ |
| 107 | \| Max public IPs per Firewall \| 250 [VERIFY] \| | ⬜ |
| 118 | - [VERIFY] Not supported on Basic SKU | ⬜ |
| 151 | \| `managedNATGateway` \| AKS-managed NAT Gateway; auto-scales IPs [VERIFY] \| | ⬜ |
| 152 | \| `userAssignedNATGateway` \| Customer-managed NAT Gateway; StandardV2 supported [VERIFY] \| | ⬜ |

## concepts\user-defined-routes.md (2)

| Line | Excerpt | Status |
|---|---|---|
| 104 | **Limit:** 25 routes with service tags per route table [VERIFY]. | ⬜ |
| 177 | - Max 25 service tag routes per route table [VERIFY] | ⬜ |

## concepts\vnet-encryption.md (1)

| Line | Excerpt | Status |
|---|---|---|
| 61 | \| **Enforcement mode** \| Currently `AllowUnencrypted` only; `DropUnencrypted` planned [VERIFY] \| | ⬜ |

## concepts\vnet-peering.md (8)

| Line | Excerpt | Status |
|---|---|---|
| 23 | \| **Pricing** \| Ingress + egress per GB \| Higher per-GB rate than local [VERIFY] \| | ⬜ |
| 172 | \| Max VNets per group \| 250 (default); 1,000 on request; 5,000 preview [VERIFY] \| | ⬜ |
| 173 | \| VNets per VNet \| Up to 2 connected groups simultaneously [VERIFY] \| | ⬜ |
| 239 | \| Peerings per VNet (default) \| 500 [VERIFY] \| | ⬜ |
| 240 | \| Peerings per VNet (with AVNM) \| 1,000 [VERIFY] \| | ⬜ |
| 241 | \| VNets in connected group (default) \| 250 [VERIFY] \| | ⬜ |
| 242 | \| VNets in connected group (on request) \| 1,000 [VERIFY] \| | ⬜ |
| 243 | \| VNets in connected group (preview) \| 5,000 [VERIFY] \| | ⬜ |

## decisions\connectivity-options.md (42)

| Line | Excerpt | Status |
|---|---|---|
| 16 | \| **VNet-to-VNet, cross-region** \| ⚠️ VNet-to-VNet connection type; encrypted; cross-region egress charges \| ❌ A | ⬜ |
| 17 | \| **Remote user → Azure (P2S)** \| ✅ P2S via OpenVPN/SSTP/IKEv2; up to 10,000 users on VpnGw5AZ [VERIFY] \| ❌ \|   | ⬜ |
| 34 | **Bandwidth / latency profile:** Up to ~10 Gbps aggregate (VpnGw5AZ) [VERIFY]; latency varies with internet path  | ⬜ |
| 48 | **Key constraints:** Provider provisioning takes **weeks** (not minutes); no encryption by default (MACsec on Dir | ⬜ |
| 58 | **Bandwidth / latency profile:** S2S up to 20 Gbps aggregate per hub [VERIFY]; P2S up to 200 Gbps / 100,000 users | ⬜ |
| 70 | **Bandwidth / latency profile:** Line-rate; lowest possible latency (same as intra-VNet); intra-region data trans | ⬜ |
| 72 | **Key constraints:** Non-transitive by default (route through hub requires gateway transit or NVA); Basic Load Ba | ⬜ |
| 134 | \| **SLA** \| 99.9% (active-standby) / 99.95% (active-active) [VERIFY] \| 99.95% circuit SLA [VERIFY] \| | ⬜ |
| 135 | \| **Max bandwidth (single gateway)** \| ~10 Gbps (VpnGw5AZ) [VERIFY] \| 10 Gbps (provider) / 400 Gbps (Direct) \| | ⬜ |
| 159 | \| **ER ECMP** \| Standard BGP ECMP \| Disabled by default; Route-map creation required to enable [VERIFY] \|        | ⬜ |
| 160 | \| **ER max bandwidth per hub** \| Per gateway SKU (up to ErGwScale, ~40+ Gbps [VERIFY]) \| 20 Gbps (10 scale units | ⬜ |
| 172 | \| **Latency** \| Same as intra-VNet (lowest possible) \| Adds gateway processing; ~1–2 ms additional [VERIFY] \|    | ⬜ |
| 175 | \| **Intra-region data transfer** \| Free [VERIFY] \| Free [VERIFY] \| | ⬜ |
| 176 | \| **Cross-region data transfer** \| Billed at standard egress rates [VERIFY] \| Billed at region-pair rates [VERIF | ⬜ |
| 215 | Deploy a Standard Virtual WAN with hubs in each primary Azure region. Branch CPE devices (SD-WAN or vanilla VPN) | ⬜ |
| 220 | - **Cost:** Hub base fee ~$0.25/hr [VERIFY] + gateway scale units + hub data processing fees for VNet-to-VNet fl | ⬜ |
| 254 | > All values tagged [VERIFY] — confirm against Azure service limit documentation before treating as authoritativ | ⬜ |
| 258 | \| **VPN Gateway** \| Max S2S tunnels (VpnGw1–3) \| 30 [VERIFY] \| Per gateway \| | ⬜ |
| 259 | \| **VPN Gateway** \| Max S2S tunnels (VpnGw4–5 / AZ) \| 100 [VERIFY] \| Per gateway; use Virtual WAN beyond this \|  | ⬜ |
| 260 | \| **VPN Gateway** \| Max aggregate throughput (VpnGw5AZ) \| ~10 Gbps [VERIFY] \| Shared across all tunnels \|        | ⬜ |
| 261 | \| **VPN Gateway** \| Max aggregate throughput (VpnGw1AZ) \| ~650 Mbps [VERIFY] \| \| | ⬜ |
| 270 | \| **ExpressRoute** \| Bandwidth (ExpressRoute Direct) \| 10 / 100 / 400 Gbps \| 400 Gbps: limited locations, enroll | ⬜ |
| 271 | \| **ExpressRoute** \| VNets per Standard circuit \| 10 [VERIFY] \| \| | ⬜ |
| 272 | \| **ExpressRoute** \| VNets per Premium circuit \| Up to 100 [VERIFY] \| Scaled by circuit bandwidth \| | ⬜ |
| 273 | \| **ExpressRoute** \| Max circuits per subscription \| 50 (default) [VERIFY] \| Increasable via support ticket \|    | ⬜ |
| 283 | \| **Virtual WAN** \| S2S connections per hub \| 1,000 (2,000 IPsec tunnels) [VERIFY] \| \| | ⬜ |
| 284 | \| **Virtual WAN** \| S2S aggregate throughput per hub \| 20 Gbps [VERIFY] \| \| | ⬜ |
| 285 | \| **Virtual WAN** \| ER scale units per hub \| Max 10 (20 Gbps) [VERIFY] \| 1 scale unit = 2 Gbps \| | ⬜ |
| 286 | \| **Virtual WAN** \| P2S max concurrent users per hub \| 100,000 [VERIFY] \| At 200 scale units \| | ⬜ |
| 287 | \| **Virtual WAN** \| P2S max aggregate throughput \| 200 Gbps [VERIFY] \| At 200 scale units \| | ⬜ |
| 288 | \| **Virtual WAN** \| Hub router max throughput (50 RIUs) \| 50 Gbps [VERIFY] \| \| | ⬜ |
| 289 | \| **Virtual WAN** \| Hub router max spoke VMs (50 RIUs) \| 50,000 [VERIFY] \| \| | ⬜ |
| 291 | \| **Virtual WAN** \| Single TCP flow limit \| 1.5 Gbps [VERIFY] \| Hard ceiling per flow \| | ⬜ |
| 295 | \| **VNet Peering** \| Peered VNets per VNet (default) \| 500 [VERIFY] \| \| | ⬜ |
| 296 | \| **VNet Peering** \| Peered VNets per VNet (VNet Manager) \| 1,000 [VERIFY] \| \| | ⬜ |
| 299 | \| **Azure Bastion** \| Standard/Premium SKU instances \| 2–50 [VERIFY] \| 20 RDP / 40 SSH sessions per instance \|   | ⬜ |
| 300 | \| **Azure Bastion** \| Max concurrent RDP (50 instances) \| 1,000 [VERIFY] \| \| | ⬜ |
| 301 | \| **Azure Bastion** \| Max concurrent SSH (50 instances) \| 2,000 [VERIFY] \| \| | ⬜ |
| 305 | \| **Route Server** \| Max spoke VMs (default 2 RIUs) \| 4,000 [VERIFY] \| \| | ⬜ |
| 306 | \| **Route Server** \| Max spoke VMs (48 RIUs) \| 50,000 [VERIFY] \| Hard maximum \| | ⬜ |
| 318 | > **Note:** Azure VPN Gateway default ASN is **65515** [VERIFY]. Azure Route Server and Virtual WAN hub router a | ⬜ |
| 338 | > - All bandwidth figures (VpnGw SKU throughput, VWAN gateway scale unit throughput, ErGwScale performance) are  | ⬜ |

## decisions\firewall-and-security-options.md (18)

| Line | Excerpt | Status |
|---|---|---|
| 80 | \| **Detection-to-mitigation** \| 30–60 seconds [VERIFY] \| | ⬜ |
| 81 | \| **Telemetry** \| Azure Monitor metrics, attack analytics, 30-day retention [VERIFY]; Sentinel integration \|      | ⬜ |
| 91 | \| **SKUs** \| Basic (250 Mbps, no autoscale, alert-only ThreatIntel [VERIFY]); Standard (30 Gbps, autoscale, DNS p | ⬜ |
| 92 | \| **IDPS impact** \| Alert+Deny mode caps effective throughput at **10 Gbps** [VERIFY]; single TCP flow max **300  | ⬜ |
| 172 | \| **IDPS Alert+Deny throughput impact** \| N/A \| Max **10 Gbps** aggregate [VERIFY]; single TCP flow max **300 Mb | ⬜ |
| 179 | \| **Max throughput** \| 30 Gbps [VERIFY] \| 100 Gbps [VERIFY] (10 Gbps effective with IDPS Alert+Deny) [VERIFY] \|  | ⬜ |
| 180 | \| **Fat flow max** \| 1 Gbps \| 10 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY] \| | ⬜ |
| 181 | \| **PCI DSS compliance** \| ❌ \| ✅ [VERIFY] \| | ⬜ |
| 200 | \| **CAPTCHA** \| ❌ \| ✅ Front Door only; usage-based charges [VERIFY] \| | ⬜ |
| 204 | \| **Custom rules max** \| 100 per policy [VERIFY] \| 100 per policy [VERIFY] \| | ⬜ |
| 309 | \| **DDoS Protection** \| Network Protection \| Per-IP adaptive tuning \| 100 public IPs per plan [VERIFY] \| DRR + c | ⬜ |
| 310 | \| **Azure Firewall** \| Basic \| 250 Mbps [VERIFY] \| No autoscale (fixed 2 instances) \| Alert-only ThreatIntel; no | ⬜ |
| 311 | \| **Azure Firewall** \| Standard \| 30 Gbps [VERIFY] \| 250 public IPs [VERIFY]; SNAT 2,496 ports/PIP [VERIFY] \| Au | ⬜ |
| 312 | \| **Azure Firewall** \| Premium \| 100 Gbps [VERIFY] (10 Gbps with IDPS Alert+Deny) [VERIFY] \| 10,000 IDPS signatu | ⬜ |
| 313 | \| **WAF (App Gateway)** \| WAF_v2 \| App GW v2 max 125 RCU [VERIFY] \| 100 custom rules/policy [VERIFY] \| Per-site/ | ⬜ |
| 314 | \| **WAF (Front Door)** \| Front Door Premium \| Global anycast \| 100 custom rules/policy [VERIFY] \| DRS only (no C | ⬜ |
| 315 | \| **Firewall Manager** \| — \| Control plane only \| 1 parent policy → unlimited children \| Free ≤1 policy associat | ⬜ |
| 316 | \| **NSG** \| — \| No throughput limit \| 1,000 rules per NSG [VERIFY] \| Free; no data processing charges \| | ⬜ |

## decisions\load-balancing-options.md (29)

| Line | Excerpt | Status |
|---|---|---|
| 38 | \| **SLA** \| 99.99% [VERIFY] (Standard, ≥ 2 healthy backend instances) \| | ⬜ |
| 51 | \| **SLA** \| 99.95% [VERIFY] (Standard_v2 / WAF_v2) \| | ⬜ |
| 63 | \| **Key SKUs** \| Standard (~$35/mo base [VERIFY]), Premium (~$330/mo base [VERIFY]), Classic *(retiring Mar 31, 2 | ⬜ |
| 64 | \| **SLA** \| Not specified in source articles — [VERIFY] \| | ⬜ |
| 77 | \| **SLA** \| Not specified in source articles — [VERIFY] \| | ⬜ |
| 162 | \| **mTLS** \| ✅ Pass-through (client cert reaches backend unmodified) \| ✅ Strict (gateway validates cert) or pa | ⬜ |
| 166 | \| **Pricing model** \| Per rule/hour + data processing charge \| Fixed $/hr (Standard_v2: $0.246/hr [VERIFY]) + ca | ⬜ |
| 182 | \| **TLS minimum** \| TLS 1.2 (as of Aug 31, 2025) [VERIFY] \| TLS 1.2 (TLS 1.0/1.1 not supported) \| | ⬜ |
| 191 | \| **Pricing** \| ~$0.246/hr + ~$0.008/CU (Standard_v2) [VERIFY] \| ~$35/mo base (Standard) or ~$330/mo base (Premi | ⬜ |
| 208 | \| **Health probes** \| HTTP/HTTPS (GET or HEAD) from every active PoP; sliding window (SampleSize / SuccessfulSam | ⬜ |
| 209 | \| **Failover speed** \| Sub-minute — health probe failures detected independently at each PoP \| TTL-dependent (de | ⬜ |
| 215 | \| **Private origins** \| ✅ Premium: Private Link to origin (7,200 RPS limit [VERIFY]) \| ❌ Public endpoints only | ⬜ |
| 217 | \| **Base cost** \| ~$35–$330/mo base fee [VERIFY] + usage \| ❌ No base fee — per DNS query + per probe \| | ⬜ |
| 243 | - Cost: Front Door Premium base (~$330/mo [VERIFY]) + App Gateway WAF_v2 capacity units. | ⬜ |
| 259 | - Use fast probing (10 s [VERIFY]) and low TTL (e.g., 30–60 s) if SLA requires fast failover — but expect more D | ⬜ |
| 297 | - Rate limit: 7,200 RPS per regional cluster per profile [VERIFY] — add Private Link origins in multiple regions | ⬜ |
| 304 | > All values marked [VERIFY] — cross-check with [Azure subscription and service limits](https://learn.microsoft. | ⬜ |
| 308 | \| **Azure Load Balancer** \| Standard \| Unlimited rules (per-frontend/port combinations) \| Single VNet scope \| Mi | ⬜ |
| 309 | \| **Azure Load Balancer** \| Standard — Global tier \| N/A \| Regional Standard LBs only \| Bounded by regional LB c | ⬜ |
| 310 | \| **Azure Load Balancer** \| Gateway \| HA ports only (All/0) \| Up to 2 backend pools per rule; 2 tunnel interface | ⬜ |
| 311 | \| **Application Gateway** \| Standard_v2 \| 400 routing rules [VERIFY] \| 100 pools × 1,200 backends/pool [VERIFY]  | ⬜ |
| 312 | \| **Application Gateway** \| WAF_v2 \| 400 routing rules [VERIFY] \| 100 pools × 1,200 backends/pool [VERIFY] \| 62, | ⬜ |
| 313 | \| **Application Gateway** \| Basic *(preview)* \| 5 rules [VERIFY] \| 5 pools × 5 backends [VERIFY] \| 200 CPS [VERI | ⬜ |
| 314 | \| **Azure Front Door** \| Standard \| 5,000 composite routes (domains × paths + rule overrides) \| Unlimited origin | ⬜ |
| 315 | \| **Azure Front Door** \| Premium \| 5,000 composite routes \| Unlimited origins; Private Link: 7,200 RPS/regional  | ⬜ |
| 316 | \| **Traffic Manager** \| N/A (consumption) \| Unlimited endpoints; 1 Web App per region per profile [VERIFY] \| Azu | ⬜ |
| 317 | \| **WAF (App GW)** \| WAF_v2 \| 100 custom rules/policy [VERIFY] \| Inherits App GW limits \| Inherits App GW limits | ⬜ |
| 318 | \| **WAF (Front Door)** \| Standard \| 100 custom rules/policy [VERIFY] \| — \| — \| — \| Custom rules only; no managed | ⬜ |
| 319 | \| **WAF (Front Door)** \| Premium \| 100 custom rules/policy [VERIFY] \| — \| — \| — \| DRS 2.1+; Bot Manager 1.1; JS  | ⬜ |

## decisions\private-access-options.md (25)

| Line | Excerpt | Status |
|---|---|---|
| 31 | \| **Cost-sensitive workload** \| ⚠️ PE: per endpoint-hour + per-GB charge [VERIFY] \| ✅ Free — no extra charge for | ⬜ |
| 57 | \| High Scale (opt-in) \| Set `privateEndpointVNetPolicies=Basic` on VNet to raise per-VNet limit from 1,000 → 5,00 | ⬜ |
| 73 | - Cost: per-hour billing + per-GB data processing [VERIFY] | ⬜ |
| 79 | \| Azure Container Registry \| Premium [VERIFY] \| | ⬜ |
| 80 | \| Azure Service Bus \| Premium [VERIFY] \| | ⬜ |
| 81 | \| Azure SignalR \| Standard or above [VERIFY] \| | ⬜ |
| 82 | \| Azure App Service \| Basic, Standard, Premium v2/v3, Isolated v2, or Functions Premium [VERIFY] \| | ⬜ |
| 83 | \| Azure Storage \| GPv2 accounts only (not GPv1, not classic Blob storage) [VERIFY] \| | ⬜ |
| 84 | \| Azure DB for PostgreSQL Single Server \| General Purpose or Memory Optimized [VERIFY] \| | ⬜ |
| 103 | \| Service endpoint policies \| Restrict access to specific storage accounts or SQL servers (Storage and SQL only) | ⬜ |
| 132 | A dedicated subnet must be delegated to the compute service (e.g., `Microsoft.Web/serverFarms` for App Service). | ⬜ |
| 221 | > ⚠️ The full list contains 43+ zone names. The above covers the most common services. Source: `raw/articles/pri | ⬜ |
| 343 | \| **Private endpoints per VNet (standard)** \| 1,000 [VERIFY] \| Raise via High Scale opt-in \| | ⬜ |
| 344 | \| **Private endpoints per VNet (High Scale)** \| 5,000 [VERIFY] \| Set `privateEndpointVNetPolicies=Basic`; one-ti | ⬜ |
| 345 | \| **Private endpoints across peered VNets (standard)** \| 4,000 [VERIFY] \| Silent degradation when exceeded \|     | ⬜ |
| 346 | \| **Private endpoints across peered VNets (High Scale)** \| 20,000 [VERIFY] \| \| | ⬜ |
| 347 | \| **NAT IPs per Private Link Service** \| 8 [VERIFY] \| \| | ⬜ |
| 348 | \| **ASG members per NSG on PE subnet** \| 50 [VERIFY] \| Exceeding causes connection failures \| | ⬜ |
| 350 | \| **Private DNS zones per subscription** \| [VERIFY — see Azure DNS Limits] \| \| | ⬜ |
| 351 | \| **VNet links per private DNS zone** \| [VERIFY — see Azure DNS Limits] \| \| | ⬜ |
| 352 | \| **Registration VNets per private zone** \| [VERIFY] \| A VNet can be registration VNet for only one zone \|       | ⬜ |
| 354 | \| **DNS forwarding rules per ruleset** \| 1,000 [VERIFY] \| Longest suffix match wins \| | ⬜ |
| 355 | \| **VNets linked per DNS forwarding ruleset** \| 500 (same region) [VERIFY] \| Cross-region VNet links not support | ⬜ |
| 359 | > All limits marked [VERIFY] — authoritative source: [Azure Networking Limits](https://learn.microsoft.com/azure | ⬜ |
| 378 | 3. **All limits `[VERIFY]`:** Source articles consistently defer to the Azure subscription limits reference page | ⬜ |

## limits-and-skus\service-limits-quick-reference.md (69)

| Line | Excerpt | Status |
|---|---|---|
| 5 | > ⚠️ All values tagged `[VERIFY]` — confirm against live Azure docs before relying on these in architecture decisi | ⬜ |
| 13 | \| VNets per subscription per region \| 1,000 [VERIFY] \| \| | ⬜ |
| 14 | \| Subnets per VNet \| 3,000 [VERIFY] \| \| | ⬜ |
| 17 | \| Peered VNets per VNet (default) \| 500 [VERIFY] \| \| | ⬜ |
| 18 | \| Peered VNets per VNet (with VNet Manager) \| 1,000 [VERIFY] \| \| | ⬜ |
| 19 | \| NSG rules per NSG \| 1,000 [VERIFY] \| \| | ⬜ |
| 30 | \| SNAT ports per public frontend IP \| 64,000 [VERIFY] \| \| | ⬜ |
| 31 | \| Default SNAT ports — pool 1–50 VMs \| 1,024 per VM [VERIFY] \| \| | ⬜ |
| 32 | \| Default SNAT ports — pool 51–100 VMs \| 512 per VM [VERIFY] \| \| | ⬜ |
| 33 | \| Default SNAT ports — pool 101–200 VMs \| 256 per VM [VERIFY] \| \| | ⬜ |
| 34 | \| Default SNAT ports — pool 401–800 VMs \| 64 per VM [VERIFY] \| \| | ⬜ |
| 36 | \| Standard LB SLA \| 99.99% [VERIFY] \| Requires ≥2 healthy backend instances \| | ⬜ |
| 51 | \| Public IP addresses per NAT Gateway \| 1–16 [VERIFY] \| \| | ⬜ |
| 52 | \| SNAT ports per public IP \| 64,512 [VERIFY] \| Per public IP address \| | ⬜ |
| 53 | \| Total SNAT ports per NAT Gateway (16 IPs) \| ~1,032,192 [VERIFY] \| \| | ⬜ |
| 55 | \| NAT Gateway SLA \| 99.99% [VERIFY] \| \| | ⬜ |
| 56 | \| Subnets per NAT Gateway \| Up to 1,000 [VERIFY] \| \| | ⬜ |
| 68 | \| Standard/Premium SKU — instances \| 2–50 [VERIFY] \| \| | ⬜ |
| 71 | \| Max concurrent RDP (50 instances) \| 1,000 [VERIFY] \| \| | ⬜ |
| 72 | \| Max concurrent SSH (50 instances) \| 2,000 [VERIFY] \| \| | ⬜ |
| 73 | \| Shareable links per Bastion resource \| 500 [VERIFY] \| \| | ⬜ |
| 86 | \| BGP routes per circuit — Standard \| 4,000 [VERIFY] \| \| | ⬜ |
| 87 | \| BGP routes per circuit — Premium \| 10,000 [VERIFY] \| \| | ⬜ |
| 88 | \| VNet links per circuit — Standard (default) \| 10 [VERIFY] \| \| | ⬜ |
| 89 | \| VNet links per circuit — Premium \| 100+ (scales with bandwidth) [VERIFY] \| \| | ⬜ |
| 91 | \| BFD failure detection \| <1 second [VERIFY] \| vs ~3 minutes without BFD \| | ⬜ |
| 92 | \| Traffic Collector sampling \| 1:4096 [VERIFY] \| Up to 300,000 flows/min \| | ⬜ |
| 100 | \| S2S connections per gateway \| Varies by SKU [VERIFY] \| Basic: 10; VpnGw1-5: 30–100 \| | ⬜ |
| 101 | \| P2S concurrent connections \| Varies by SKU [VERIFY] \| Basic: 128; VpnGw1: 250; VpnGw2: 500; VpnGw3: 1,000; Vpn | ⬜ |
| 102 | \| Gateway throughput \| Varies by SKU [VERIFY] \| VpnGw1: 650 Mbps; VpnGw5: 10 Gbps \| | ⬜ |
| 112 | \| Rules per Firewall Policy \| 20,000 [VERIFY] \| \| | ⬜ |
| 113 | \| DNAT rules per policy \| 298 [VERIFY] \| \| | ⬜ |
| 114 | \| Firewall throughput (Standard) \| ~30 Gbps [VERIFY] \| With forced tunneling: ~10 Gbps \| | ⬜ |
| 115 | \| Firewall throughput (Premium) \| ~100 Gbps [VERIFY] \| \| | ⬜ |
| 124 | \| Max instances — v2 SKU \| 125 [VERIFY] \| Autoscaling up to max \| | ⬜ |
| 125 | \| Min instances — v2 SKU (for SLA) \| 2 [VERIFY] \| \| | ⬜ |
| 126 | \| Listeners per gateway \| 200 [VERIFY] \| \| | ⬜ |
| 127 | \| Backend pools \| 100 [VERIFY] \| \| | ⬜ |
| 128 | \| Backend servers \| 1,200 [VERIFY] \| \| | ⬜ |
| 129 | \| HTTP headers max size \| 32 KB [VERIFY] \| \| | ⬜ |
| 130 | \| TLS certificate key size max \| 4,096-bit RSA [VERIFY] \| \| | ⬜ |
| 131 | \| WAF custom rules \| 100 [VERIFY] \| \| | ⬜ |
| 139 | \| Private Endpoints per VNet (default) \| 1,000 [VERIFY] \| \| | ⬜ |
| 140 | \| Private Endpoints per VNet (High Scale, opt-in) \| 5,000 [VERIFY] \| \| | ⬜ |
| 141 | \| Peered-VNet PE aggregate (High Scale) \| 20,000 [VERIFY] \| \| | ⬜ |
| 142 | \| NAT IPs per Private Link Service \| 8 max [VERIFY] \| Minimum 1 must remain \| | ⬜ |
| 143 | \| PLS idle connection timeout \| ~300 seconds [VERIFY] \| Use TCP keepalives below this \| | ⬜ |
| 144 | \| Private Link SLA \| 99.99% [VERIFY] \| \| | ⬜ |
| 145 | \| Service Endpoints per VNet \| No limit [VERIFY] \| \| | ⬜ |
| 146 | \| NSP perimeter resources \| Up to limit per region [VERIFY] \| See NSP docs \| | ⬜ |
| 154 | \| DNS zones per subscription \| 250 (public) [VERIFY] \| \| | ⬜ |
| 155 | \| Record sets per zone (public) \| 10,000 [VERIFY] \| \| | ⬜ |
| 156 | \| Private zones per subscription \| 1,000 [VERIFY] \| \| | ⬜ |
| 157 | \| Virtual network links per private zone \| 1,000 [VERIFY] \| \| | ⬜ |
| 158 | \| VNets with autoregistration per private zone \| 1 [VERIFY] \| Only 1 VNet can have autoregistration per zone \|   | ⬜ |
| 159 | \| Private DNS Private Resolver — inbound endpoints per VNet \| 5 [VERIFY] \| \| | ⬜ |
| 160 | \| Rulesets per resolver \| 5 [VERIFY] \| \| | ⬜ |
| 168 | \| DDoS Network Protection — mitigation threshold (TCP SYN) \| ~10,000–200,000+ pps [VERIFY] \| Adaptive tuning; no | ⬜ |
| 169 | \| Protected public IP resources per plan \| Unlimited [VERIFY] \| All public IPs in protected VNets covered \|      | ⬜ |
| 171 | \| DDoS Network Protection SLA \| 99.99% [VERIFY] \| \| | ⬜ |
| 179 | \| Origins per origin group \| 50 [VERIFY] \| \| | ⬜ |
| 180 | \| Front Door profiles per subscription \| 500 [VERIFY] \| \| | ⬜ |
| 181 | \| Rules per rules engine configuration \| 25 [VERIFY] \| \| | ⬜ |
| 182 | \| Custom domains per profile \| 500 [VERIFY] \| \| | ⬜ |
| 183 | \| Edge PoP count \| 100+ locations globally [VERIFY] \| \| | ⬜ |
| 184 | \| WAF custom rules \| 100 [VERIFY] \| \| | ⬜ |
| 192 | \| Endpoints per profile \| 200 [VERIFY] \| \| | ⬜ |
| 193 | \| Nested profiles depth \| 10 [VERIFY] \| \| | ⬜ |
| 194 | \| Profile TTL (DNS) \| Configurable; minimum 0 seconds [VERIFY] \| \| | ⬜ |

## limits-and-skus\sku-comparison.md (90)

| Line | Excerpt | Status |
|---|---|---|
| 7 | Quick reference for SKU selection and limit planning. All numeric limits extracted from compiled wiki pages — valu | ⬜ |
| 18 | \| **VpnGw1** \| Gen1/Gen2 [VERIFY] \| 30 [VERIFY] \| 128 SSTP / 250 IKEv2 \| see docs [VERIFY] \| ✅ \| ❌ \| Entry prod | ⬜ |
| 19 | \| **VpnGw1AZ** \| Gen1/Gen2 [VERIFY] \| 30 [VERIFY] \| 128 SSTP / 250 IKEv2 \| see docs [VERIFY] \| ✅ \| ✅ \| Zone-red | ⬜ |
| 20 | \| **VpnGw2 / VpnGw2AZ** \| Gen1/Gen2 [VERIFY] \| 30 [VERIFY] \| see docs [VERIFY] \| see docs [VERIFY] \| ✅ \| ✅ (AZ) | ⬜ |
| 21 | \| **VpnGw3 / VpnGw3AZ** \| Gen1/Gen2 [VERIFY] \| 30 [VERIFY] \| see docs [VERIFY] \| see docs [VERIFY] \| ✅ \| ✅ (AZ) | ⬜ |
| 22 | \| **VpnGw4 / VpnGw4AZ** \| Gen2 \| 100 [VERIFY] \| see docs [VERIFY] \| see docs [VERIFY] \| ✅ \| ✅ (AZ) \| Large ente | ⬜ |
| 23 | \| **VpnGw5 / VpnGw5AZ** \| Gen2 \| 100 [VERIFY] \| see docs [VERIFY] \| see docs [VERIFY] \| ✅ \| ✅ (AZ) \| Highest pe | ⬜ |
| 33 | \| Max S2S tunnels per gateway \| 100 [VERIFY] \| Use Virtual WAN if >100 needed \| | ⬜ |
| 38 | \| P2S connections — higher SKUs \| see docs [VERIFY] \| See `about-gateway-skus.md` \| | ⬜ |
| 53 | \| **Local** \| 1–2 Azure regions near peering location \| Included in port charge (no egress billing) [VERIFY] \| se | ⬜ |
| 54 | \| **Standard** \| All regions in same geopolitical area \| Metered or Unlimited \| 10 [VERIFY] \| Within same geopoli | ⬜ |
| 55 | \| **Premium** \| All Azure regions globally \| Metered or Unlimited \| Up to 100 [VERIFY] \| Across geopolitical boun | ⬜ |
| 59 | **ExpressRoute Direct port speeds:** 10 Gbps, 100 Gbps, 400 Gbps (limited locations; enrollment required [VERIFY] | ⬜ |
| 73 | > Gateway throughput figures live in include files — check `expressroute-about-virtual-network-gateways.md` for c | ⬜ |
| 79 | \| ER circuits per subscription (default) \| 50 [VERIFY] \| Increasable via support ticket \| | ⬜ |
| 82 | \| VNets per Standard circuit \| 10 [VERIFY] \| — \| | ⬜ |
| 83 | \| VNets per Premium circuit \| Up to 100 [VERIFY] \| Scaled by circuit bandwidth \| | ⬜ |
| 106 | \| **Standard** \| ✅ (internal only) \| ✅ \| ✅ \| Via Global tier \| 99.99% [VERIFY] \| ✅ (closed by default) \| Via | ⬜ |
| 114 | \| SNAT ports per public frontend IP \| 64,000 [VERIFY] \| Blocks of 8 ports consumed per rule \| | ⬜ |
| 115 | \| Default SNAT ports — pool 1–50 VMs \| 1,024 per VM [VERIFY] \| Capped regardless of additional frontend IPs \|    | ⬜ |
| 116 | \| Default SNAT ports — pool 51–100 VMs \| 512 per VM [VERIFY] \| — \| | ⬜ |
| 117 | \| Default SNAT ports — pool 101–200 VMs \| 256 per VM [VERIFY] \| — \| | ⬜ |
| 118 | \| Default SNAT ports — pool 201–400 VMs \| 128 per VM [VERIFY] \| — \| | ⬜ |
| 120 | \| Standard LB SLA \| 99.99% [VERIFY] \| Requires ≥2 healthy backend instances \| | ⬜ |
| 132 | \| **Basic** *(preview)* \| ❌ \| ❌ \| 5 [VERIFY] \| 5 [VERIFY] \| 5 [VERIFY] \| 5 [VERIFY] \| 5 [VERIFY] \| ❌ \| 99.9%  | ⬜ |
| 133 | \| **Standard_v2** \| ❌ \| ✅ (0–125) \| 125 [VERIFY] \| 100 [VERIFY] \| 400 [VERIFY] \| 100 [VERIFY] \| 1,200 [VERIFY] | ⬜ |
| 134 | \| **WAF_v2** \| ✅ OWASP CRS 3.1/3.0/2.2.9 \| ✅ (0–125) \| 125 [VERIFY] \| 100 [VERIFY] \| 400 [VERIFY] \| 100 [VERIF | ⬜ |
| 142 | \| Max instances (autoscale) \| 125 [VERIFY] \| 0 minimum = no reserved capacity; scale-out 3–5 min \| | ⬜ |
| 146 | \| Max trusted client CA chains per SSL profile \| 100 [VERIFY] \| mTLS strict mode \| | ⬜ |
| 147 | \| Max trusted client CA chains per gateway \| 200 [VERIFY] \| mTLS strict mode \| | ⬜ |
| 148 | \| Persistent connections per capacity unit \| 2,500 [VERIFY] \| v2 billing unit \| | ⬜ |
| 149 | \| Throughput per capacity unit \| 2.22 Mbps (1 GB/hr) [VERIFY] \| v2 billing unit \| | ⬜ |
| 150 | \| Min CUs per instance \| 10 [VERIFY] \| — \| | ⬜ |
| 151 | \| Max hostnames per multi-site listener \| 5 [VERIFY] \| — \| | ⬜ |
| 152 | \| TLS minimum version \| TLS 1.2 \| TLS 1.0/1.1 support ended August 31, 2025 [VERIFY] \| | ⬜ |
| 158 | \| SKU \| WAF custom rules \| WAF managed rules (OWASP DRS) \| Bot protection \| Private Link origins \| Base fee [VER | ⬜ |
| 175 | \| Private Link RPS limit \| 7,200 RPS per regional cluster per profile [VERIFY] \| Exceeding returns HTTP 429 \|    | ⬜ |
| 178 | \| Certificate auto-rotation \| 45 days before expiry (Standard/Premium) [VERIFY] \| Classic: 90 days; Classic mana | ⬜ |
| 188 | \| DNS TTL minimum \| 0 seconds [VERIFY] \| All queries reach TM name servers \| | ⬜ |
| 189 | \| DNS TTL maximum \| 2,147,483,647 seconds [VERIFY] \| RFC-1035 maximum \| | ⬜ |
| 191 | \| Probe interval (standard) \| 30 seconds [VERIFY] \| Default \| | ⬜ |
| 192 | \| Probe interval (fast) \| 10 seconds [VERIFY] \| Additional billing applies \| | ⬜ |
| 193 | \| Tolerated failures before degraded \| 0–9, default 3 [VERIFY] \| — \| | ⬜ |
| 194 | \| Priority values range \| 1–1,000 [VERIFY] \| No duplicates allowed \| | ⬜ |
| 195 | \| Weighted values range \| 1–1,000 [VERIFY] \| Default 1 \| | ⬜ |
| 196 | \| Custom health-check headers \| Up to 8 header:value pairs [VERIFY] \| Per profile or endpoint \| | ⬜ |
| 197 | \| Expected status code ranges \| Up to 8 ranges [VERIFY] \| HTTP/HTTPS monitoring only \| | ⬜ |
| 198 | \| Web App endpoints per region per profile \| 1 [VERIFY] \| Workaround: use External endpoint type \| | ⬜ |
| 209 | \| **Basic** \| SMB / essential protection \| 250 Mbps [VERIFY] \| N/A \| Alert only \| ❌ \| ❌ \| ❌ \| ❌ \| ❌ (fixed  | ⬜ |
| 210 | \| **Standard** \| Enterprise L3–L7, centralized egress \| 30 Gbps [VERIFY] \| 1 Gbps \| Alert + Deny \| ❌ \| ❌ \| FQD | ⬜ |
| 211 | \| **Premium** \| Regulated / deep inspection \| 100 Gbps [VERIFY] \| 10 Gbps \| Alert + Deny \| ✅ \| ✅ (outbound + E | ⬜ |
| 213 | > **Performance notes:** Initial out-of-the-box throughput (before autoscale): Standard ~3 Gbps, Premium ~18 Gbp | ⬜ |
| 219 | \| Max public IP addresses per firewall \| 250 [VERIFY] \| Basic supports fewer \| | ⬜ |
| 220 | \| SNAT ports per public IP \| 2,496 [VERIFY] \| Add PIPs or NAT Gateway to scale \| | ⬜ |
| 222 | \| Max custom DNS servers \| 15 [VERIFY] \| Configured per firewall or policy \| | ⬜ |
| 223 | \| IDPS customizable signature overrides \| Up to 10,000 [VERIFY] \| Alert / Alert+Deny / Disabled per signature \|  | ⬜ |
| 225 | \| Parallel IP Group updates \| 20 at a time [VERIFY] \| Per firewall policy or classic firewall \| | ⬜ |
| 254 | \| **DDoS IP Protection** \| Per public IP resource \| Per-IP per month [VERIFY] \| ✅ \| ❌ \| ❌ \| ❌ \| ✅ \|         | ⬜ |
| 257 | > **Pricing breakeven:** IP Protection is more cost-effective for <10 public IPs; Network Protection becomes mor | ⬜ |
| 263 | \| Public IPs included per Network Protection plan \| 100 [VERIFY] \| Additional IPs incur overage charges \|        | ⬜ |
| 265 | \| Attack detection-to-mitigation time \| 30–60 seconds [VERIFY] \| Varies by attack type \| | ⬜ |
| 266 | \| Attack metric data retention \| 30 days [VERIFY] \| Via Azure Monitor \| | ⬜ |
| 313 | \| Private endpoints per VNet (standard) \| 1,000 [VERIFY] \| — \| | ⬜ |
| 314 | \| Private endpoints per VNet (High Scale, opt-in) \| 5,000 [VERIFY] \| One-time connection reset on enable/disable | ⬜ |
| 315 | \| Private endpoints across peered VNets (standard) \| 4,000 [VERIFY] \| Exceeding silently degrades connection hea | ⬜ |
| 316 | \| Private endpoints across peered VNets (High Scale) \| 20,000 [VERIFY] \| — \| | ⬜ |
| 317 | \| NAT IP addresses per Private Link Service \| 8 [VERIFY] \| Each NAT IP adds more TCP port capacity \| | ⬜ |
| 318 | \| ASG members per NSG on PE subnet \| 50 [VERIFY] \| Exceeding 50 causes connection failures \| | ⬜ |
| 319 | \| PLS idle timeout \| ~300 seconds (5 minutes) [VERIFY] \| Implement TCP keepalives <300 s \| | ⬜ |
| 327 | \| Azure Container Registry \| Premium tier [VERIFY] \| | ⬜ |
| 328 | \| Azure Service Bus \| Premium tier [VERIFY] \| | ⬜ |
| 329 | \| Azure SignalR \| Standard tier or above [VERIFY] \| | ⬜ |
| 330 | \| Azure Storage \| GPv2 account only (not GPv1) [VERIFY] \| | ⬜ |
| 331 | \| Azure App Service \| Basic, Standard, Premium v2/v3, Isolated v2, or Functions Premium [VERIFY] \| | ⬜ |
| 340 | \| **Standard** \| S2S VPN, P2S VPN, ExpressRoute, VNet \| ✅ Full mesh (automatic) \| ✅ \| ✅ \| ✅ \| ✅ \| ✅ \| $0.2 | ⬜ |
| 348 | \| **S2S VPN** \| 500 Mbps [VERIFY] \| see docs \| 20 Gbps [VERIFY] \| Active-active dual-instance; up to 1,000 conne | ⬜ |
| 349 | \| **ExpressRoute** \| 2 Gbps [VERIFY] \| 10 \| 20 Gbps [VERIFY] \| Max 4 circuits from same peering location, 8 from | ⬜ |
| 350 | \| **User VPN (P2S)** \| 500 Mbps / 500 users \| 200 \| 100 Gbps / 100,000 users [VERIFY] \| Scale ≥40 requires multi | ⬜ |
| 361 | > Max routes: **10,000** regardless of RIU count. Single TCP flow hard-limited to **1.5 Gbps** [VERIFY]. Hub sca | ⬜ |
| 371 | \| VNets per subscription per region \| 1,000 [VERIFY] \| Soft limit; can request increase \| | ⬜ |
| 372 | \| Subnets per VNet \| 3,000 [VERIFY] \| — \| | ⬜ |
| 376 | \| VNet peerings per VNet (default) \| 500 [VERIFY] \| — \| | ⬜ |
| 377 | \| VNet peerings per VNet (VNet Manager) \| 1,000 [VERIFY] \| — \| | ⬜ |
| 378 | \| NSG rules per NSG \| 1,000 [VERIFY] \| — \| | ⬜ |
| 380 | \| Route tables (UDRs) per subscription per region \| 200 [VERIFY] \| — \| | ⬜ |
| 381 | \| Routes per route table (default) \| 400 [VERIFY] \| — \| | ⬜ |
| 382 | \| Routes per route table (VNet Manager) \| 1,000 [VERIFY] \| — \| | ⬜ |
| 383 | \| UDRs with service tag as prefix per table \| 25 [VERIFY] \| — \| | ⬜ |
| 384 | \| DNS servers per VNet \| 20 [VERIFY] \| — \| | ⬜ |
| 404 | \| **DHE cipher suites — Azure Front Door** \| April 1, 2026 [VERIFY] \| Remove TLS_DHE_RSA_WITH_AES_* dependencies | ⬜ |

## patterns\dns-hybrid-resolution.md (3)

| Line | Excerpt | Status |
|---|---|---|
| 143 | - One ruleset can link to up to 500 VNets in the same region [VERIFY]. | ⬜ |
| 275 | \| DNS forwarding rules per ruleset \| 1,000 [VERIFY] \| | ⬜ |
| 276 | \| VNets linked per ruleset \| 500 (same region) [VERIFY] \| | ⬜ |

## patterns\expressroute-resiliency-patterns.md (2)

| Line | Excerpt | Status |
|---|---|---|
| 252 | \| Available locations \| 21 metro locations [VERIFY for latest list] \| | ⬜ |
| 447 | \| ER circuits per subscription \| 50 (default) \| Increasable [VERIFY] \| | ⬜ |

## patterns\hub-spoke-with-firewall.md (4)

| Line | Excerpt | Status |
|---|---|---|
| 71 | - Standard — enterprise egress control, threat intel alert+deny, DNS proxy, FQDN rules [VERIFY SKU pricing]       | ⬜ |
| 72 | - Premium — adds TLS inspection (outbound + E-W), IDPS (67,000+ signatures), URL filtering; required for PCI DSS  | ⬜ |
| 146 | - SNAT port limit: **2,496 ports per public IP per Firewall instance** [VERIFY]. If you have many VMs making hig | ⬜ |
| 257 | \| SNAT port exhaustion on Firewall \| Attach NAT Gateway to `AzureFirewallSubnet`; each public IP on NAT GW adds  | ⬜ |

## patterns\nat-gateway-hub-spoke.md (3)

| Line | Excerpt | Status |
|---|---|---|
| 169 | - High-scale workloads are exhausting Azure Firewall's SNAT port pool (2,496 ports per public IP per Firewall in | ⬜ |
| 176 | \| Azure Firewall (Standard/Premium) \| 2,496 per IP [VERIFY] \| ~39,936 total \| | ⬜ |
| 177 | \| NAT Gateway (on AzureFirewallSubnet) \| 64,512 per IP [VERIFY] \| ~1,032,192 total \| | ⬜ |

## services\application-gateway.md (35)

| Line | Excerpt | Status |
|---|---|---|
| 13 | \| **SSL/TLS termination** \| Terminates TLS at the gateway (offloads crypto from backends). Supports end-to-end TL | ⬜ |
| 28 | \| **Mutual authentication (mTLS)** \| v2 only. Two modes: strict (gateway validates client cert) and passthrough ( | ⬜ |
| 60 | \| FIPS 140-2 validated cryptography \| FIPS mode not currently supported on v2 [VERIFY] \| | ⬜ |
| 70 | \| **Basic** (preview) \| Dev/test, low-traffic, simple routing \| 99.9% [VERIFY] \| 200 [VERIFY] \| 5 \| 5 \| 5 \| 5 \| N | ⬜ |
| 71 | \| **Standard_v2** \| Production web workloads \| 99.95% [VERIFY] \| 62,500 [VERIFY] \| 100 \| 100 \| 1,200 \| 400 \| Full | ⬜ |
| 72 | \| **WAF_v2** \| Production + OWASP WAF \| 99.95% [VERIFY] \| 62,500 [VERIFY] \| 100 \| 100 \| 1,200 \| 400 \| Same as Sta | ⬜ |
| 81 | **v1 throughput (SSL offload enabled, approximate):** [VERIFY] | ⬜ |
| 115 | > All limits marked [VERIFY] — cross-check with [Azure subscription service limits](https://learn.microsoft.com/ | ⬜ |
| 121 | \| Max instances (autoscale) \| N/A \| 125 [VERIFY] \| 0 minimum = no reserved capacity \| | ⬜ |
| 122 | \| Max instances (manual) \| 32 [VERIFY] \| 125 [VERIFY] \| \| | ⬜ |
| 130 | \| Persistent connections \| 2,500 [VERIFY] \| | ⬜ |
| 131 | \| Throughput \| 1 GB/hr = 2.22 Mbps [VERIFY] \| | ⬜ |
| 132 | \| Compute unit \| 1 [VERIFY] \| | ⬜ |
| 133 | \| CUs per instance \| 10 minimum [VERIFY] \| | ⬜ |
| 135 | **Per-instance capacity (Standard_v2):** 10 CUs, 25,000 persistent connections, 500 Mbps throughput [VERIFY]     | ⬜ |
| 137 | **Compute unit capacity:** Standard_v2 ≈ 50 TLS connections/sec (RSA 2048-bit) per CU; WAF_v2 ≈ 10 concurrent re | ⬜ |
| 143 | \| Recommended subnet size \| /26 min \| /24 recommended [VERIFY] \| | ⬜ |
| 144 | \| NSG inbound port range required \| 65503–65534 \| 65200–65535 (not required for private deployment) [VERIFY] \|   | ⬜ |
| 153 | \| Minimum TLS version (frontend) \| TLS 1.2 \| As of August 31, 2025 — TLS 1.0/1.1 support ended [VERIFY] \|        | ⬜ |
| 155 | \| Max trusted client CA chains per SSL profile \| 100 [VERIFY] \| mTLS strict mode \| | ⬜ |
| 156 | \| Max trusted client CA chains per gateway \| 200 [VERIFY] \| mTLS strict mode \| | ⬜ |
| 157 | \| Max file size per CA certificate upload \| 25 KB [VERIFY] \| mTLS \| | ⬜ |
| 163 | \| Max listeners \| 100 [VERIFY] \| | ⬜ |
| 164 | \| Max backend pools \| 100 [VERIFY] \| | ⬜ |
| 165 | \| Max backends per pool \| 1,200 [VERIFY] \| | ⬜ |
| 166 | \| Max routing rules \| 400 [VERIFY] \| | ⬜ |
| 167 | \| Max hostnames per multi-site listener \| 5 [VERIFY] \| | ⬜ |
| 168 | \| Max websites per gateway \| 100+ [VERIFY] \| | ⬜ |
| 170 | ### Pricing (East US, illustration only — use Azure pricing page for actuals) [VERIFY] | ⬜ |
| 208 | \| **FIPS mode** \| Not supported on v2. [VERIFY] \| | ⬜ |
| 209 | \| **Microsoft Defender for Cloud** \| Not integrated with v2 yet. [VERIFY] \| | ⬜ |
| 271 | 2. **v1 limits marked [VERIFY].** | ⬜ |
| 272 | v1 is retiring. Throughput figures from `features.md` are labeled "approximate" in the source. Flagged all v1 pe | ⬜ |
| 274 | 3. **Pricing figures marked [VERIFY].** | ⬜ |
| 275 | Source (`understanding-pricing.md`) explicitly states prices are East US examples for illustration only, subject | ⬜ |

## services\azure-firewall.md (12)

| Line | Excerpt | Status |
|---|---|---|
| 66 | \| **Basic** \| SMB, essential protection \| 250 Mbps [VERIFY] \| N/A \| Alert only \| x \| x \| x \| | ⬜ |
| 67 | \| **Standard** \| Enterprise L3-L7, autoscale \| 30 Gbps [VERIFY] \| 1 Gbps \| Alert + Deny \| x \| x \| Yes \| | ⬜ |
| 68 | \| **Premium** \| Regulated, deep inspection \| 100 Gbps [VERIFY] \| 10 Gbps \| Alert + Deny \| Yes \| Yes (outbound + E | ⬜ |
| 73 | - Initial out-of-the-box throughput (before autoscale): Standard ~3 Gbps, Premium ~18 Gbps [VERIFY] | ⬜ |
| 74 | - IDPS in Alert+Deny mode reduces Premium effective throughput to **10 Gbps** for single-flow inspection [VERIFY] | ⬜ |
| 75 | - Premium single TCP connection max: 9 Gbps (300 Mbps with IDPS Alert+Deny) [VERIFY] | ⬜ |
| 76 | - PCI DSS compliance: Premium only [VERIFY] | ⬜ |
| 86 | \| Max public IP addresses per firewall \| 250 [VERIFY] \| Basic supports multiple but fewer \| | ⬜ |
| 87 | \| SNAT ports per public IP \| 2,496 [VERIFY] \| Add more PIPs or attach NAT Gateway to scale \| | ⬜ |
| 89 | \| Max custom DNS servers \| 15 [VERIFY] \| Configured per firewall or policy \| | ⬜ |
| 90 | \| IDPS customizable signature overrides \| Up to 10,000 [VERIFY] \| Alert / Alert+Deny / Disabled per signature \|   | ⬜ |
| 92 | \| Parallel IP Group updates \| 20 at a time [VERIFY] \| Per firewall policy or classic firewall \| | ⬜ |

## services\bastion.md (9)

| Line | Excerpt | Status |
|---|---|---|
| 70 | \| **Developer** \| Dev/test; no-cost evaluation \| 1 VM at a time; no peering; select regions only [VERIFY] \| Free  | ⬜ |
| 71 | \| **Basic** \| Small production; fixed capacity \| 2 instances fixed; 40 RDP / 80 SSH concurrent sessions; no scali | ⬜ |
| 72 | \| **Standard** \| Most production workloads \| 2-50 instances; up to 1,000 RDP / 2,000 SSH at max scale; native cli | ⬜ |
| 73 | \| **Premium** \| Compliance / high-security \| All Standard features + session recording + private-only deployment  | ⬜ |
| 86 | \| Standard/Premium SKU instances \| 2-50 (configurable) \| [VERIFY] \| | ⬜ |
| 89 | \| Max concurrent RDP at 50 instances \| 1,000 \| [VERIFY] \| | ⬜ |
| 90 | \| Max concurrent SSH at 50 instances \| 2,000 \| [VERIFY] \| | ⬜ |
| 91 | \| Shareable links per Bastion resource \| 500 \| [VERIFY] \| | ⬜ |
| 96 | \| First 5 GB outbound data/month \| Free \| All paid SKUs [VERIFY] \| | ⬜ |

## services\ddos-protection.md (10)

| Line | Excerpt | Status |
|---|---|---|
| 18 | \| **Attack detection-to-mitigation time** \| 30-60 seconds [VERIFY] \| | ⬜ |
| 20 | \| **Attack metrics and alerting** \| Azure Monitor metrics (e.g., *Under DDoS attack or not*, *Inbound packets dro | ⬜ |
| 38 | \| Enterprise deployment with 10+ public IPs, or requiring DRR / cost protection / WAF discount \| **DDoS Network P | ⬜ |
| 63 | \| **DDoS IP Protection** \| Per public IP resource \| Per protected IP per month [VERIFY] \| No \| No \| No \| | ⬜ |
| 64 | \| **DDoS Network Protection** \| Per VNet (plan covers all IPs in linked VNets) \| Fixed monthly plan fee; up to 10 | ⬜ |
| 66 | > **Pricing breakeven:** IP Protection is more cost-effective for <10 public IPs; Network Protection becomes more | ⬜ |
| 74 | \| Public IPs included per Network Protection plan \| 100 [VERIFY] \| Additional IPs incur overage charges [VERIFY]  | ⬜ |
| 76 | \| Attack metric data retention \| 30 days [VERIFY] \| Via Azure Monitor \| | ⬜ |
| 77 | \| Attack detection to mitigation initiation \| 30-60 seconds [VERIFY] \| May vary by attack type \| | ⬜ |
| 79 | \| VMSS DDoS telemetry \| Flexible orchestration mode only [VERIFY] \| Not available for Uniform orchestration \|     | ⬜ |

## services\dns.md (28)

| Line | Excerpt | Status |
|---|---|---|
| 29 | \| Alias records \| Dynamic references to Azure resources (public IP, Traffic Manager, CDN, Azure Front Door). Elim | ⬜ |
| 34 | \| TTL range \| 1 to 2,147,483,647 seconds [VERIFY] \| | ⬜ |
| 130 | \| **Public DNS zones** \| Per zone hosted + per million queries [VERIFY] \| Billed as Azure resources; same billin | ⬜ |
| 131 | \| **Private DNS zones** \| Per zone + per million queries [VERIFY] \| Global resource; no charge for VNet links [V | ⬜ |
| 132 | \| **DNS Private Resolver** \| Per endpoint-hour (inbound and outbound endpoints billed separately) [VERIFY] \| Sig | ⬜ |
| 133 | \| **DNS Security Policy** \| [VERIFY — pricing not stated explicitly in source articles] \| — \| | ⬜ |
| 135 | > All pricing marked [VERIFY] — confirm at [Azure DNS Pricing](https://azure.microsoft.com/pricing/details/dns/) | ⬜ |
| 145 | \| DNS zones per subscription \| [VERIFY — see Azure DNS Limits] \| Soft limit \| | ⬜ |
| 146 | \| Record sets per zone \| [VERIFY — see Azure DNS Limits] \| \| | ⬜ |
| 147 | \| Records per record set \| [VERIFY — see Azure DNS Limits] \| \| | ⬜ |
| 149 | \| Alias record sets per resource \| 50 [VERIFY] \| Max alias record sets pointing to a single Azure resource \|     | ⬜ |
| 157 | \| Private zones per subscription \| [VERIFY — see Azure DNS Limits] \| \| | ⬜ |
| 158 | \| Record sets per private zone \| [VERIFY] \| Monitor zone size; consider sharding before limits are approached \|  | ⬜ |
| 159 | \| VNet links per private zone \| [VERIFY] \| \| | ⬜ |
| 160 | \| Registration VNets per private zone \| [VERIFY] \| A VNet can be a registration VNet for only one private zone \| | ⬜ |
| 168 | \| DNS forwarding rules per ruleset \| 1,000 [VERIFY] \| \| | ⬜ |
| 170 | \| VNets linked per ruleset \| 500 (same region) [VERIFY] \| Cross-region VNet links not supported \| | ⬜ |
| 177 | \| Security policies \| 1,000 [VERIFY] \| \| | ⬜ |
| 178 | \| DNS traffic rules per policy \| 100 [VERIFY] \| Priority range 100–65,000 \| | ⬜ |
| 179 | \| Domain lists per policy \| 2,000 [VERIFY] \| \| | ⬜ |
| 180 | \| Domains per large domain list \| 100,000 [VERIFY] \| \| | ⬜ |
| 181 | \| Domains per standard domain list \| 100,000 [VERIFY] \| \| | ⬜ |
| 184 | > All limits marked [VERIFY] should be confirmed at [Azure DNS Limits](https://learn.microsoft.com/azure/azure-r | ⬜ |
| 285 | - Microsoft Defender for DNS — monitors queries and detects suspicious activity without agents [VERIFY availabil | ⬜ |
| 351 | 1. **Service limits gap:** The raw article `dns-zones-records.md` references actual limits via an `[!INCLUDE]` d | ⬜ |
| 355 | 3. **DNS Security Policy pricing:** No explicit pricing information found in source articles. The `dns-security- | ⬜ |
| 380 | - **Tagged all limits and pricing claims** with `[VERIFY]` — the limits article uses `[!INCLUDE]` directives poi | ⬜ |
| 384 | 1. **Populate all `[VERIFY]` limits** from the [Azure DNS Limits reference page](https://learn.microsoft.com/azu | ⬜ |

## services\expressroute.md (16)

| Line | Excerpt | Status |
|---|---|---|
| 19 | \| **ExpressRoute Metro** \| Single circuit with links in two distinct peering locations within the same city for h | ⬜ |
| 64 | \| **Local** \| 1–2 Azure regions near the peering location \| Data transfer included in port charge (no separate eg | ⬜ |
| 81 | \| **400 Gbps** \| 5, 10, 40, 100, 200, 400 Gbps (limited locations; enrollment required) [VERIFY] \| | ⬜ |
| 94 | > **Gateway performance figures** are in `[!INCLUDE]` directives not available in raw articles — see `expressrout | ⬜ |
| 102 | \| 20 \| 20 Gbps \| 2,000,000 \| 140,000 \| 30,000 [VERIFY] \| | ⬜ |
| 103 | \| 40 \| 40 Gbps \| 8,000,000 \| 280,000 \| 50,000 [VERIFY] \| | ⬜ |
| 111 | **ErGwScale region gaps (not available):** Belgium Central, Japan East, Qatar Central, Southeast Asia, West Euro | ⬜ |
| 117 | \| ExpressRoute circuits per subscription \| 50 (default) \| Increasable via support ticket [VERIFY] \| | ⬜ |
| 120 | \| VNets per Standard circuit \| 10 \| [VERIFY] \| | ⬜ |
| 121 | \| VNets per Premium circuit \| Up to 100 \| Scaled by circuit bandwidth [VERIFY] \| | ⬜ |
| 137 | \| ExpressRoute limits table (VNets/Global Reach per Premium circuit) \| In `[!INCLUDE]` file \| **[VERIFY]** — see | ⬜ |
| 340 | 1. **VNet and Global Reach limits table** (`expressroute-faqs.md#limits`) references `[!INCLUDE [ExpressRoute li | ⬜ |
| 341 | 2. **Gateway performance table** (`expressroute-about-virtual-network-gateways.md#aggthroughput`) also in an inc | ⬜ |
| 342 | 3. **ExpressRoute Direct FAQ** (`expressroute-faqs.md#expressRouteDirect`) also in include file — Direct-specifi | ⬜ |
| 343 | 4. **Global Reach FAQ** (`expressroute-faqs.md#globalreach`) also in include file — limits on Global Reach conne | ⬜ |
| 347 | 8. **ErGwScale not available in 9 regions** — listed in `scalable-gateway.md`; may change over time, marked `[VE | ⬜ |

## services\firewall-manager.md (6)

| Line | Excerpt | Status |
|---|---|---|
| 34 | \| DNS proxy + custom DNS \| Firewall acts as DNS intermediary; required for FQDN filtering in network rules; up to | ⬜ |
| 50 | \| **On-premises VPN** \| Up to 10 Gbps, 30 S2S connections [VERIFY] \| Up to 20 Gbps, 1000 S2S connections [VERIFY] | ⬜ |
| 92 | \| **Basic** \| NAT rules, Network rules, Application rules, IP Groups, Threat Intelligence (alerts only) \| Basic [ | ⬜ |
| 93 | \| **Standard** \| All Basic features + Custom DNS, DNS proxy, Web Categories, Threat Intelligence (alert or deny)  | ⬜ |
| 94 | \| **Premium** \| All Standard features + TLS Inspection, URL Filtering (full path), IDPS (67,000+ signatures) \| Pr | ⬜ |
| 105 | \| Pricing \| Free (≤1 association); fixed rate (>1 association) [VERIFY] \| Free \| | ⬜ |

## services\front-door.md (16)

| Line | Excerpt | Status |
|---|---|---|
| 58 | \| Very high RPS over Private Link from single region \| Private Link is rate-limited at 7,200 RPS [VERIFY] per reg | ⬜ |
| 67 | \| SKU \| Use case \| Key differentiators \| Base fee [VERIFY] \| | ⬜ |
| 92 | \| Private Link RPS limit \| 7,200 RPS per regional cluster per profile [VERIFY] \| Exceeds → HTTP 429; mitigate by  | ⬜ |
| 95 | \| Certificate auto-rotation \| 45 days before expiry (Standard/Premium); 90 days (Classic) [VERIFY] \| Classic mana | ⬜ |
| 96 | \| DHE cipher suite retirement \| April 1, 2026 [VERIFY] \| `TLS_DHE_RSA_WITH_AES_*` suites being removed \| | ⬜ |
| 105 | \| Base fee \| ~$35/month [VERIFY] \| ~$330/month [VERIFY] \| $0 \| | ⬜ |
| 106 | \| Requests (client → edge) \| Billed by zone (8 zones) \| Billed by zone — higher rate than Standard [VERIFY] \| Fr | ⬜ |
| 107 | \| Egress (edge → client) \| Billed by zone (8 zones) \| Same as Standard [VERIFY] \| Billed (higher rates, 5 zones) | ⬜ |
| 109 | \| Ingress (origin → edge) \| Free \| Free \| Billed ($0.01/GB) [VERIFY] \| | ⬜ |
| 111 | \| WAF custom rules \| Free \| Free \| ~$1/rule/month + request fees [VERIFY] \| | ⬜ |
| 112 | \| WAF managed rules \| Not supported \| Free \| ~$20/rule set/month + request fees [VERIFY] \| | ⬜ |
| 169 | - Rate limit: 7,200 RPS per regional cluster per profile [VERIFY] | ⬜ |
| 252 | \| 1 \| Pricing figures from `understanding-pricing.md` treated as illustrative examples \| Source article explicit | ⬜ |
| 253 | \| 2 \| DHE cipher retirement date (April 1, 2026) included but tagged `[VERIFY]` \| Sourced from `end-to-end-tls.m | ⬜ |
| 254 | \| 3 \| Private Link 7,200 RPS limit included \| Sourced from `private-link.md` FAQ; platform-enforced, tagged `[VE | ⬜ |
| 281 | \| `[VERIFY]` tags applied \| 10 (all pricing figures, rate limits, cipher retirement date, cert rotation windows) | ⬜ |

## services\internet-peering.md (12)

| Line | Excerpt | Status |
|---|---|---|
| 20 | supported** [VERIFY] | ⬜ |
| 59 | \| Physical medium \| 100-Gbps single-mode fiber [VERIFY] \| | ⬜ |
| 62 | \| Session IPs \| Allocated by Microsoft automated process after port configuration; delivered by email; may take * | ⬜ |
| 63 | \| Traffic minimum \| 2 Gbps [VERIFY] \| | ⬜ |
| 64 | \| Port upgrade trigger \| Peak utilization > 50% [VERIFY] \| | ⬜ |
| 66 | \| SKU (standard PNI) \| Basic Free [VERIFY] \| | ⬜ |
| 67 | \| SKU (Peering Service PNI) \| Premium Free [VERIFY] \| | ⬜ |
| 84 | \| Physical medium \| IX switch fabric port; minimum 10-Gbps [VERIFY] \| | ⬜ |
| 87 | \| Traffic range \| 500 Mbps minimum – 2 Gbps maximum [VERIFY]; above 2 Gbps, Direct peering should be used \|       | ⬜ |
| 88 | \| Port upgrade trigger \| Peak utilization > 50% [VERIFY] \| | ⬜ |
| 90 | \| SKU \| Basic Free [VERIFY] \| | ⬜ |
| 102 | Contact peeringservice@microsoft.com to initiate. All use **SKU: Premium Free** [VERIFY]. | ⬜ |

## services\load-balancer.md (16)

| Line | Excerpt | Status |
|---|---|---|
| 19 | \| **Outbound SNAT** \| Uses LB frontend IP(s) for outbound via explicit outbound rules; 64,000 [VERIFY] ports per  | ⬜ |
| 76 | \| **Standard** \| Production-grade; high performance, zone-redundancy, 99.99% SLA [VERIFY] \| Backend: any VM/VMSS  | ⬜ |
| 79 | \| **Standard — Global tier** \| Cross-region geo-proximity routing; multi-region failover \| Public frontend only;  | ⬜ |
| 87 | \| SNAT ports per public frontend IP \| 64,000 [VERIFY] \| Each LB or inbound NAT rule consumes 8-port blocks from t | ⬜ |
| 88 | \| Default SNAT ports — pool 1–50 VMs \| 1,024 per VM [VERIFY] \| Capped at 1,024 regardless of additional frontend  | ⬜ |
| 89 | \| Default SNAT ports — pool 51–100 VMs \| 512 per VM [VERIFY] \| \| | ⬜ |
| 90 | \| Default SNAT ports — pool 101–200 VMs \| 256 per VM [VERIFY] \| \| | ⬜ |
| 91 | \| Default SNAT ports — pool 201–400 VMs \| 128 per VM [VERIFY] \| \| | ⬜ |
| 92 | \| Default SNAT ports — pool 401–800 VMs \| 64 per VM [VERIFY] \| \| | ⬜ |
| 93 | \| Default SNAT ports — pool 801–1,000 VMs \| 32 per VM [VERIFY] \| \| | ⬜ |
| 98 | \| Standard LB SLA \| 99.99% [VERIFY] \| Requires ≥ 2 healthy backend instances per backend pool \| | ⬜ |
| 99 | \| Management operations (Standard) \| < 30 seconds typical [VERIFY] \| \| | ⬜ |
| 100 | \| Management operations (Basic, retired) \| 60–90+ seconds typical [VERIFY] \| \| | ⬜ |
| 102 | \| Subscription move \| Not supported for Standard LB [VERIFY] \| Resource group move (same subscription) is suppor | ⬜ |
| 191 | \| MTU recommendation \| ≥ 1550; up to 4000 for jumbo frame scenarios [VERIFY] \| | ⬜ |
| 209 | \| Home regions (Azure) \| Central US, East Asia, East US 2, North Europe, Southeast Asia, UK South, West Europe,  | ⬜ |

## services\network-function-manager.md (3)

| Line | Excerpt | Status |
|---|---|---|
| 19 | - NFM itself carries **no additional cost** — the ASE device and any partner NF licensing are billed separately.  | ⬜ |
| 32 | \| **Network acceleration** \| ASE Pro ports 5 & 6 support **SR-IOV** and **DPDK** for superior NF data-path perfor | ⬜ |
| 83 | \| **Hardware** \| Azure Stack Edge Pro with GPU — only supported ASE variant [VERIFY] \| | ⬜ |

## services\network-watcher.md (9)

| Line | Excerpt | Status |
|---|---|---|
| 62 | \| Core diagnostics (IP Flow Verify, Next Hop, etc.) \| Free for basic checks [VERIFY] \| | ⬜ |
| 63 | \| NSG Flow Logs \| Per GB stored; storage charges separate [VERIFY] \| | ⬜ |
| 64 | \| VNet Flow Logs \| Per GB stored; storage charges separate [VERIFY] \| | ⬜ |
| 65 | \| Traffic Analytics \| Per GB processed + Log Analytics workspace cost [VERIFY] \| | ⬜ |
| 66 | \| Connection Monitor \| Per monitoring check [VERIFY] \| | ⬜ |
| 76 | \| Packet capture sessions (parallel) \| 10,000 per region per subscription [VERIFY] \| \| | ⬜ |
| 77 | \| Continuous packet capture duration (max) \| 7 days [VERIFY] \| Ring buffer \| | ⬜ |
| 78 | \| VPN troubleshoot concurrent operations \| 1 per subscription [VERIFY] \| \| | ⬜ |
| 79 | \| NSG flow log retention \| Up to 1 year [VERIFY] \| GPv2 storage only \| | ⬜ |

## services\peering-service.md (2)

| Line | Excerpt | Status |
|---|---|---|
| 84 | \| IPv4 only \| Only IPv4 prefixes are currently supported [VERIFY] \| | ⬜ |
| 138 | - **IPv4 only** — IPv6 prefixes not currently supported. [VERIFY] | ⬜ |

## services\private-link.md (25)

| Line | Excerpt | Status |
|---|---|---|
| 68 | \| **Private Endpoint** \| Any VNet subnet; PE must be in same region+subscription as VNet \| 1,000 PEs per VNet [VE | ⬜ |
| 69 | \| **Private Link Service** \| Standard Load Balancer (NIC-based backend) only \| Up to 8 NAT IP addresses per PLS [ | ⬜ |
| 70 | \| **High Scale Private Endpoints (opt-in)** \| Set `privateEndpointVNetPolicies=Basic` on VNet; triggers one-time  | ⬜ |
| 73 | \| **Azure Container Registry** \| Requires Premium tier for PE support \| [VERIFY] \| | ⬜ |
| 74 | \| **Azure Service Bus** \| Requires Premium tier for PE support \| [VERIFY] \| | ⬜ |
| 75 | \| **Azure SignalR** \| Requires Standard tier or above for PE support \| [VERIFY] \| | ⬜ |
| 76 | \| **Azure App Service** \| Requires Basic, Standard, Premium v2/v3, Isolated v2, or Functions Premium plan \| [VERI | ⬜ |
| 77 | \| **Azure DB for PostgreSQL Single Server** \| Requires General Purpose or Memory Optimized pricing tier \| [VERIFY | ⬜ |
| 78 | \| **Azure Storage** \| GPv2 account only (not GPv1, Blob storage) \| [VERIFY] \| | ⬜ |
| 86 | \| Private endpoints per VNet (standard) \| 1,000 [VERIFY] \| Upgrade to High Scale to raise limit \| | ⬜ |
| 87 | \| Private endpoints per VNet (High Scale) \| 5,000 [VERIFY] \| Opt-in; one-time connection reset on enable/disable  | ⬜ |
| 88 | \| Private endpoints across peered VNets (standard, silent limit) \| 4,000 [VERIFY] \| Exceeding silently degrades c | ⬜ |
| 89 | \| Private endpoints across peered VNets (High Scale) \| 20,000 [VERIFY] \| \| | ⬜ |
| 90 | \| NAT IP addresses per Private Link Service \| 8 [VERIFY] \| Each NAT IP adds more TCP port capacity \| | ⬜ |
| 91 | \| PLS per Standard Load Balancer \| See Azure limits reference [VERIFY] \| Multiple PLS per LB via different fronte | ⬜ |
| 92 | \| ASG members per NSG on PE subnet \| 50 [VERIFY] \| Exceeding 50 causes connection failures \| | ⬜ |
| 94 | \| PLS idle timeout \| ~300 seconds (5 minutes) [VERIFY] \| Use TCP keepalives < 300 s \| | ⬜ |
| 100 | **Limits reference:** `../azure-resource-manager/management/azure-subscription-service-limits#azure-private-link | ⬜ |
| 247 | \| Private Endpoint \| Per endpoint, per hour [VERIFY — see pricing page] \| | ⬜ |
| 248 | \| Data processing \| Per GB processed through PE [VERIFY] \| | ⬜ |
| 249 | \| Cross-region traffic \| Per GB transferred between regions [VERIFY] \| | ⬜ |
| 250 | \| Private Link Service \| Per service, per hour [VERIFY] \| | ⬜ |
| 259 | > **SLA:** [SLA for Azure Private Link](https://azure.microsoft.com/support/legal/sla/private-link/v1_0/) [VERIF | ⬜ |
| 359 | ## D4 — Numeric limits tagged [VERIFY] | ⬜ |
| 361 | text and tagged [VERIFY]. Authoritative source is the Azure subscription limits page | ⬜ |

## services\route-server.md (11)

| Line | Excerpt | Status |
|---|---|---|
| 45 | \| 2 (default) \| 4,000 [VERIFY] \| Minimum; set at creation time as the floor for autoscaling \| | ⬜ |
| 46 | \| 3 \| 5,000 [VERIFY] \| Each additional RIU adds ~1,000 VM capacity \| | ⬜ |
| 47 | \| 8 \| 10,000 [VERIFY] \| — \| | ⬜ |
| 48 | \| 18 \| 20,000 [VERIFY] \| — \| | ⬜ |
| 49 | \| 28 \| 30,000 [VERIFY] \| — \| | ⬜ |
| 50 | \| 38 \| 40,000 [VERIFY] \| — \| | ⬜ |
| 51 | \| 48 (max) \| 50,000 [VERIFY] \| Hard maximum \| | ⬜ |
| 54 | > Additional RIUs cost **$0.10/hour** per unit (US pricing) [VERIFY — regional pricing varies]. | ⬜ |
| 55 | > Pricing model: hourly deployment-based; no per-route or per-session charges [VERIFY]. | ⬜ |
| 104 | \| VPN gateway \| Must be in **active-active mode** with ASN **65515** [VERIFY] \| | ⬜ |
| 138 | \| Route Server initial creation \| 30–60 minutes [VERIFY] \| | ⬜ |

## services\traffic-manager.md (20)

| Line | Excerpt | Status |
|---|---|---|
| 24 | \| **Configurable DNS TTL** \| 0 – 2,147,483,647 s [VERIFY]; default 300 s \| | ⬜ |
| 28 | \| **Fast probing** \| 10-second probe interval (billed differently from 30-second standard) [VERIFY] \| | ⬜ |
| 60 | - DNS queries answered [VERIFY pricing page for current rate] | ⬜ |
| 61 | - Health check probes (standard vs. fast probing billed differently) [VERIFY] | ⬜ |
| 62 | - Real User Measurements (per measurement sent) [VERIFY] | ⬜ |
| 63 | - Traffic View (per data point / query processed) [VERIFY] | ⬜ |
| 67 | > **Web App endpoint constraint:** The downstream Web App endpoint must be **Standard tier or higher** in App Ser | ⬜ |
| 73 | \| DNS TTL minimum \| 0 seconds [VERIFY] \| All queries reach TM name servers; no caching \| | ⬜ |
| 74 | \| DNS TTL maximum \| 2,147,483,647 seconds [VERIFY] \| RFC-1035 maximum \| | ⬜ |
| 76 | \| Probing interval (standard) \| 30 seconds [VERIFY] \| Default \| | ⬜ |
| 77 | \| Probing interval (fast) \| 10 seconds [VERIFY] \| Additional billing applies \| | ⬜ |
| 78 | \| Probe timeout (30 s interval) \| 5–10 s; default 10 s [VERIFY] \| Must be < probing interval \| | ⬜ |
| 79 | \| Probe timeout (10 s interval) \| 5–9 s; default 9 s [VERIFY] \| Must be < probing interval \| | ⬜ |
| 80 | \| Tolerated failures before degraded \| 0–9; default 3 [VERIFY] \| 0 = single failure marks endpoint unhealthy \|    | ⬜ |
| 81 | \| Priority values \| 1–1000 [VERIFY] \| Lower = higher priority; no duplicate values allowed \| | ⬜ |
| 82 | \| Weighted values \| 1–1000 [VERIFY] \| Optional; default 1 if omitted \| | ⬜ |
| 83 | \| Custom health-check headers \| Up to 8 `header:value` pairs [VERIFY] \| Per profile or per endpoint \| | ⬜ |
| 84 | \| Expected status code ranges \| Up to 8 ranges [VERIFY] \| HTTP/HTTPS monitoring only \| | ⬜ |
| 85 | \| Web App endpoints per region per profile \| 1 [VERIFY] \| Workaround: configure Web App as External endpoint \|    | ⬜ |
| 142 | \| **Real User Measurements (RUM)** \| JavaScript/Visual Studio SDK; feeds actual latency measurements into Perfor | ⬜ |

## services\virtual-network-manager.md (12)

| Line | Excerpt | Status |
|---|---|---|
| 24 | \| **Routing configurations (UDR management)** \| Orchestrate user-defined routes (UDRs) at scale across subnets an | ⬜ |
| 47 | - Limit: customers with **>15,000 subscriptions** cannot apply AVNM policy at management-group level; must scope  | ⬜ |
| 71 | - A VNet can belong to up to **2 connected groups** (soft limit, adjustable). [VERIFY] | ⬜ |
| 81 | - Up to **1,000 spoke VNets** per hub. [VERIFY] | ⬜ |
| 86 | - Default: 250 VNets per connected group (soft limit, can increase to 1,000 on request). [VERIFY] | ⬜ |
| 87 | - Preview feature `AllowHighScaleConnectedGroup`: up to 5,000 VNets per connected group in supported regions. [VE | ⬜ |
| 114 | - Up to **1,000 UDRs per route table** (AVNM-managed, vs. 400 traditional limit). [VERIFY] | ⬜ |
| 115 | - Route table modes: **ManagedOnly** (AVNM creates/owns route tables in managed resource group) or **UseExisting | ⬜ |
| 133 | - Create hierarchical IP pools: **root pool** (top-level CIDR) → **child pools** (subdivisions, up to 7 layers d | ⬜ |
| 138 | - Charged separately from AVNM — per active IP address (associated with a NIC in a VNet associated with an IP po | ⬜ |
| 146 | - Evaluates: NSG rules, ASG rules, security admin rules, connected groups, VNet peering, route tables, service e | ⬜ |
| 147 | - Charged per reachability analysis run (separate from AVNM charges). [VERIFY] | ⬜ |

## services\virtual-network.md (27)

| Line | Excerpt | Status |
|---|---|---|
| 7 | Azure Virtual Network (VNet) is the fundamental private networking primitive in Azure. It provides a logically iso | ⬜ |
| 17 | \| **Subnets** \| Segment a VNet into subnets; apply NSGs and route tables per subnet. Minimum /29 (IPv4), must be  | ⬜ |
| 19 | \| **Network Security Groups (NSGs)** \| Stateful Layer-4 ACLs applied at subnet or NIC level. Rules defined by pri | ⬜ |
| 26 | \| **VNet peering** \| Connect two VNets (same or different region/subscription/tenant) over Microsoft backbone. Tr | ⬜ |
| 32 | \| **VNet encryption** \| DTLS tunnel between VMs within a VNet or across peered VNets. Requires Accelerated Networ | ⬜ |
| 34 | \| **IP services** \| Public IPs (Standard v1/v2, Basic [retired Sept 30, 2025]), Public IP prefixes (/28 to /31),  | ⬜ |
| 35 | \| **Default outbound access (retiring)** \| Azure historically provided implicit outbound internet IPs. New VNets  | ⬜ |
| 77 | \| **Standard v2** \| Static only \| Zone-redundant (always) \| New deployments; required for Standard v2 NAT Gateway | ⬜ |
| 79 | \| **Basic** \| Static or Dynamic \| None (non-zonal) \| **RETIRED September 30, 2025** [VERIFY] \| Migrate to Standar | ⬜ |
| 85 | \| Routes per table \| 400 [VERIFY] \| 1,000 [VERIFY] \| | ⬜ |
| 86 | \| Routes with service tags per table \| 25 [VERIFY] \| 25 [VERIFY] \| | ⬜ |
| 101 | \| VNets per subscription per region \| 1,000 [VERIFY] \| Soft limit; can request increase \| | ⬜ |
| 102 | \| Subnets per VNet \| 3,000 [VERIFY] \| \| | ⬜ |
| 106 | \| VNets peered per VNet (default) \| 500 [VERIFY] \| \| | ⬜ |
| 107 | \| VNets peered per VNet (VNet Manager) \| 1,000 [VERIFY] \| \| | ⬜ |
| 108 | \| NSG rules per NSG \| 1,000 [VERIFY] \| \| | ⬜ |
| 110 | \| Route tables (UDRs) per subscription \| 200 per region [VERIFY] \| \| | ⬜ |
| 111 | \| Routes per route table \| 400 [VERIFY] \| 1,000 with VNet Manager \| | ⬜ |
| 112 | \| UDRs with service tag as prefix \| 25 per route table [VERIFY] \| \| | ⬜ |
| 113 | \| Network interfaces per VNet \| Subscription limit [VERIFY] \| See Azure Networking Limits \| | ⬜ |
| 114 | \| Private IPs per NIC \| 1 primary + multiple secondary [VERIFY] \| Secondary can be /28 block (preview) \|         | ⬜ |
| 115 | \| DNS servers per VNet \| 20 [VERIFY] \| \| | ⬜ |
| 117 | > All limits marked [VERIFY] should be confirmed against the [Azure Networking Limits](https://learn.microsoft.c | ⬜ |
| 244 | 1. **Service limits**: Most limits are marked `[VERIFY]`. The authoritative source is the [Azure Networking Limi | ⬜ |
| 254 | > **Scribe note:** Logging synthesis decisions to `.squad/decisions/inbox/atlas-virtual-network.md` — key decisi | ⬜ |
| 265 | - **Tagged all SKU, limit, and pricing claims** with `[VERIFY]` — the source articles consistently point to an e | ⬜ |
| 271 | 1. **Verify all `[VERIFY]` limits** against the Azure Networking Limits reference page before treating them as a | ⬜ |

## services\virtual-wan.md (14)

| Line | Excerpt | Status |
|---|---|---|
| 32 | \| **Site-to-site VPN** \| IPsec/IKEv2 tunnels from branch CPE devices to hub VPN gateway. Up to 1,000 S2S connecti | ⬜ |
| 33 | \| **User VPN (point-to-site)** \| IKEv2 or OpenVPN tunnels for remote users. Auth: certificate, RADIUS, or Microso | ⬜ |
| 34 | \| **ExpressRoute** \| Connects ER circuits (Local, Standard, Premium, Direct) to hub ER gateway. 1 scale unit = 2  | ⬜ |
| 35 | \| **VNet-to-VNet transit** \| Transitive connectivity between all spoke VNets via the hub router (Standard SKU onl | ⬜ |
| 62 | \| **Standard** \| S2S VPN, P2S VPN, ExpressRoute, VNet connections \| ✅ Full mesh (automatic) \| ✅ \| ✅ \| $0.25/hr | ⬜ |
| 72 | \| **S2S VPN** \| 500 Mbps [VERIFY] \| — \| 20 Gbps per hub [VERIFY] \| Dual active-active instances; each instance su | ⬜ |
| 73 | \| **ExpressRoute** \| 2 Gbps [VERIFY] \| 10 \| 20 Gbps per hub [VERIFY] \| ER ECMP not enabled by default; requires R | ⬜ |
| 74 | \| **User VPN (P2S)** \| 500 Mbps / 500 users \| 200 \| 100 Gbps / 100,000 users [VERIFY] \| Scale ≥40 requires multi- | ⬜ |
| 76 | > [VERIFY] S2S pricing: pricing-concepts.md shows $0.261/hr per scale unit in the components table but $0.361/hr  | ⬜ |
| 89 | - Single TCP flow is hard-limited to **1.5 Gbps** regardless of RIU count [VERIFY] | ⬜ |
| 200 | - Recommended algorithm for optimal performance: **GCMAES256** for both IPsec Encryption and Integrity [VERIFY]  | ⬜ |
| 255 | \| Gateway Inbound/Outbound Flows \| 5-tuple flow counts; limit is 250,000 flows [VERIFY] \| | ⬜ |
| 293 | - **Single TCP flow cap is 1.5 Gbps** regardless of RIU count. Applications requiring high per-flow throughput c | ⬜ |
| 315 | - **SLA = 99.95%** at the Virtual WAN platform level; individual component SLAs (Firewall, ER, VPN) are calculat | ⬜ |

## services\vpn-gateway.md (14)

| Line | Excerpt | Status |
|---|---|---|
| 65 | \| **VpnGw1 / VpnGw1AZ** \| Gen1 / Gen2 [VERIFY] \| ✅ (AZ variant) \| Entry production \| 30 [VERIFY] \| P2S: 128 SSTP | ⬜ |
| 66 | \| **VpnGw2 / VpnGw2AZ** \| Gen1 / Gen2 [VERIFY] \| ✅ (AZ variant) \| Mid-range; NAT supported \| 30 [VERIFY] \| Minim | ⬜ |
| 67 | \| **VpnGw3 / VpnGw3AZ** \| Gen1 / Gen2 [VERIFY] \| ✅ (AZ variant) \| Higher throughput \| 30 [VERIFY] \| — \| | ⬜ |
| 68 | \| **VpnGw4 / VpnGw4AZ** \| Gen2 \| ✅ (AZ variant) \| Large enterprise \| 100 [VERIFY] \| — \| | ⬜ |
| 69 | \| **VpnGw5 / VpnGw5AZ** \| Gen2 \| ✅ (AZ variant) \| Highest performance \| 100 [VERIFY] \| — \| | ⬜ |
| 71 | > ⚠️ **[VERIFY]** Exact per-SKU tunnel counts, P2S connection limits, and aggregate throughput figures (Mbps/Gbps | ⬜ |
| 97 | \| Max S2S tunnels per gateway \| 100 [VERIFY] \| Use Virtual WAN if >100 needed \| | ⬜ |
| 106 | \| P2S connections – all SKUs (higher tiers) \| [VERIFY] \| See include table in about-gateway-skus.md \| | ⬜ |
| 186 | > [VERIFY] Full supported algorithm list: [New-AzVpnClientIpsecParameter cmdlet](https://learn.microsoft.com/pow | ⬜ |
| 202 | - Azure VPN Gateway default ASN: 65515 [VERIFY]. | ⬜ |
| 229 | > [VERIFY] Current pricing: [Azure VPN Gateway pricing page](https://azure.microsoft.com/pricing/details/vpn-gat | ⬜ |
| 304 | \| Per-SKU S2S tunnel counts (exact) \| Same include file dependency \| Human: confirm values (VpnGw1–3 appear to b | ⬜ |
| 326 | \| `[VERIFY]` tags \| 3 clusters: SKU throughput table, per-SKU tunnel/P2S limits (include file dependency), defau | ⬜ |
| 332 | **Biggest watch-out:** The SKU performance table is entirely in Azure Docs include files I couldn't render — the | ⬜ |

## services\web-application-firewall.md (3)

| Line | Excerpt | Status |
|---|---|---|
| 33 | \| CAPTCHA \| Interactive human verification; Front Door only; incurs additional usage-based charges [VERIFY] \|     | ⬜ |
| 74 | ### Supported ruleset versions and EOL schedule [VERIFY — as of Feb 2026] | ⬜ |
| 104 | - **Max custom rules per policy:** 100 [VERIFY] | ⬜ |

## sources\bastion-docs.md (1)

| Line | Excerpt | Status |
|---|---|---|
| 27 | - Cost details marked [VERIFY] | ⬜ |

## sources\ddos-protection-docs.md (1)

| Line | Excerpt | Status |
|---|---|---|
| 24 | - Detection-to-mitigation timing estimates marked [VERIFY] | ⬜ |

## sources\firewall-docs.md (1)

| Line | Excerpt | Status |
|---|---|---|
| 28 | - IDPS throughput impact figures marked [VERIFY] | ⬜ |

## sources\firewall-manager-docs.md (1)

| Line | Excerpt | Status |
|---|---|---|
| 26 | - Custom DNS server limits marked [VERIFY] | ⬜ |

## sources\internet-peering-docs.md (2)

| Line | Excerpt | Status |
|---|---|---|
| 23 | - Traffic minimum thresholds marked [VERIFY] | ⬜ |
| 25 | - SKU names (Basic Free, Premium Free) marked [VERIFY] | ⬜ |

