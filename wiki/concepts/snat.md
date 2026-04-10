# SNAT in Azure Networking

> **Compiled:** 2026-04-10 | **Type:** Concept | **Status:** ✅ current

## What SNAT is

**Source Network Address Translation (SNAT)** rewrites the source IP address and port of outbound traffic from private IPs to public IPs. In Azure, any resource with a private IP that needs to initiate connections to the public internet requires SNAT — the private IP is translated to a public IP at the network edge so return traffic can route back.

SNAT operates on a finite pool of **SNAT ports** (also called ephemeral ports). Each outbound connection consumes a port from this pool. When all ports are exhausted, new connections **fail** — this is SNAT port exhaustion.

---

## Why SNAT matters

### SNAT port exhaustion → connection failures

When a workload opens many concurrent outbound connections (chatty microservices, connection-per-request patterns, bulk API calls), it can consume all available SNAT ports. Symptoms:

| Symptom | Indicator |
|---|---|
| Connection timeouts to external endpoints | TCP SYN sent, no response |
| HTTP 503 / 504 errors from application code | Underlying socket cannot be established |
| Dropped packets metric spikes | Azure Monitor metrics on NAT Gateway or Firewall |
| `SNAT Connection Count` metric flatlines at capacity | All ports in use |
| Intermittent failures under load | Works at low volume, fails at peak |

**Key insight:** SNAT exhaustion is **per destination endpoint**. A pool of 64,000 ports supports 64,000 concurrent connections to *each* unique destination IP:port pair. High-volume traffic to a single destination (e.g., one database or API endpoint) exhausts faster than distributed traffic.

---

## Default outbound access (being retired)

Historically, Azure provided **default outbound access** — VMs without an explicit outbound method received a dynamically assigned public IP for internet egress. This is unreliable:

- IP addresses can change without notice
- No SLA or performance guarantee
- ICMP and fragmented packets may not work
- No metrics or troubleshooting visibility

> ⚠️ **Breaking change — March 31, 2026:** New virtual networks created with API versions after this date will use **private subnets** by default. VMs in private subnets have **no implicit internet egress**. Explicit outbound configuration is required.

**Existing VNets are not affected** — only newly created VNets with new API versions.

---

## Explicit outbound methods (in recommended order)

| Priority | Method | Production-grade? | Notes |
|---|---|---|---|
| 1 (Best) | **NAT Gateway** on subnet | ✅ Yes | Recommended for most scenarios |
| 2 | **Instance-level public IP** on VM NIC | ✅ Yes | Per-VM deterministic outbound; higher cost at scale |
| 3 | **Load Balancer with explicit outbound rules** | ✅ Yes | For workloads already behind LB; scale limits apply |
| 4 | **Azure Firewall** via UDR | ✅ Yes | When egress inspection also required |
| 5 (Worst) | **Default outbound access** | ❌ No | Retiring; avoid for all new deployments |

---

## SNAT port allocation by service

### NAT Gateway

| Metric | Value |
|---|---|
| SNAT ports per public IP | **64,512** |
| Max public IPs per gateway | 16 |
| Max total SNAT ports | **~1,032,192** (16 × 64,512) |
| Port allocation model | **Dynamic on-demand** — ports allocated from shared pool as connections are opened |
| Connections per IP per destination | 50,000 |
| Max concurrent connections | 2,000,000 |
| Idle TCP timeout | 4–120 minutes (configurable; default 4 min) |
| Idle UDP timeout | 4 minutes (fixed) |

**Key advantage:** NAT Gateway uses **dynamic SNAT port allocation** — ports are shared across all VMs in attached subnets and allocated on-demand. No pre-allocation per VM; no wasted capacity on idle VMs.

**Scaling:** Add more public IPs (or use IP prefixes). Each IP adds 64,512 ports. A /28 prefix = 16 IPs = ~1M ports.

---

### Load Balancer (Standard SKU)

| Pool size | Default SNAT ports per backend VM |
|---|---|
| 1–50 VMs | **1,024** |
| 51–100 VMs | 512 |
| 101–200 VMs | 256 |
| 201–400 VMs | 128 |
| 401–800 VMs | 64 |
| 801–1,000 VMs | 32 |

| Metric | Value |
|---|---|
| SNAT ports per frontend IP | **64,000** [VERIFY] |
| Idle timeout | 4–120 minutes (configurable via outbound rules) |
| Port allocation model | **Static pre-allocation** per backend VM based on pool size |

**Critical:** Default SNAT allocation on Load Balancer is **not production-safe** for high-connection workloads. Use **explicit outbound rules with manual port allocation** to increase per-VM port count, or (better) attach a NAT Gateway.

**When NAT Gateway and Load Balancer are both on the same subnet:** NAT Gateway takes precedence for outbound traffic. Load Balancer outbound rules are bypassed.

---

### Azure Firewall

| Metric | Value |
|---|---|
| SNAT ports per public IP per Firewall instance | **2,496** [VERIFY] |
| Max public IPs per Firewall | 250 [VERIFY] |
| Scaling model | Firewall autoscales instances (Standard/Premium); each instance adds 2,496 ports per IP |
| Initial throughput (Standard) | ~3 Gbps; scales to 30 Gbps |
| Initial throughput (Premium) | ~18 Gbps; scales to 100 Gbps |

**SNAT exhaustion on Azure Firewall:** High-traffic workloads can exhaust Firewall SNAT ports even with autoscaling. **Solution:** Attach a NAT Gateway to `AzureFirewallSubnet`. NAT Gateway provides 64,512 ports per IP (vs. Firewall's 2,496 per IP per instance), dramatically increasing capacity.

**NAT Gateway on AzureFirewallSubnet:**
- NAT Gateway handles all SNAT for Firewall-routed traffic
- Firewall's native SNAT is bypassed
- Works for Standard and Premium SKUs
- [VERIFY] Not supported on Basic SKU

---

### App Service / Azure Functions

App Service uses **shared regional SNAT pools** — outbound connections from your app compete with all other apps in the same scale unit.

| Scenario | SNAT behavior |
|---|---|
| App Service without VNet integration | Uses shared regional outbound IPs; SNAT pool shared with other tenants |
| App Service with VNet integration | Routes outbound through the VNet; use NAT Gateway on the integration subnet for deterministic SNAT |
| App Service Environment (ASE) v3 | Dedicated outbound IP(s) per ASE; SNAT pool not shared |

**Best practice:** For production App Service workloads with high outbound connection volumes, enable **VNet integration** and attach a **NAT Gateway** to the integration subnet.

---

### Azure Container Instances (ACI)

| Deployment type | SNAT behavior |
|---|---|
| ACI without VNet | Shared Azure SNAT pool; no control |
| ACI with VNet | Outbound via VNet; attach NAT Gateway to the ACI subnet |

---

### Azure Kubernetes Service (AKS)

| Outbound type | SNAT model |
|---|---|
| `loadBalancer` (default) | Standard Load Balancer with outbound rules; per-node port allocation |
| `userDefinedRouting` (UDR) | Route 0.0.0.0/0 to Azure Firewall or NVA; SNAT via that device |
| `managedNATGateway` | AKS-managed NAT Gateway; auto-scales IPs [VERIFY] |
| `userAssignedNATGateway` | Customer-managed NAT Gateway; StandardV2 supported [VERIFY] |

**Recommendation:** Use NAT Gateway for AKS egress. Load Balancer outbound rules can cause SNAT exhaustion in high-pod-density clusters.

---

## SNAT exhaustion: diagnosis

### Metrics to monitor

| Service | Metric | What to look for |
|---|---|---|
| **NAT Gateway** | SNAT Connection Count | High sustained count approaching 2M limit |
| **NAT Gateway** | Dropped Packets | Non-zero indicates exhaustion or config issue |
| **NAT Gateway** | Datapath Availability | Should be 100%; <100% indicates health issue |
| **Load Balancer** | SNAT Connection Count | Sustained high count |
| **Load Balancer** | Allocated SNAT Ports vs. Used SNAT Ports | Used approaching Allocated = exhaustion risk |
| **Azure Firewall** | SNAT Port Utilization (via Azure Monitor) | High utilization = consider NAT Gateway |

### Diagnostic steps

1. **Azure Monitor → Metrics:** Graph SNAT Connection Count over time; correlate spikes with application traffic patterns
2. **Effective routes:** Verify outbound traffic is using expected path (NAT Gateway vs. Load Balancer vs. Firewall)
3. **Flow logs:** Enable NAT Gateway flow logs (StandardV2) or VNet flow logs to identify top talkers and destination concentration
4. **Application telemetry:** Log failed outbound connection attempts; check for retry storms

---

## Decision guide: which outbound method?

| Scenario | Recommended method | Reason |
|---|---|---|
| **General-purpose VMs in spoke VNets** | NAT Gateway | Highest SNAT capacity; dynamic allocation; zone-redundant (StandardV2) |
| **Hub-spoke with egress inspection** | Azure Firewall + NAT Gateway on AzureFirewallSubnet | Firewall inspects; NAT Gateway provides SNAT capacity |
| **Workloads already behind Standard LB** | Keep LB with explicit outbound rules, or add NAT Gateway | NAT Gateway takes precedence if both present |
| **Single VM needing deterministic outbound IP** | Instance-level public IP | Simplest; no shared pool |
| **AKS clusters** | NAT Gateway (managed or user-assigned) | Avoids per-node LB SNAT limits |
| **App Service production** | VNet integration + NAT Gateway | Avoids shared regional SNAT pool |
| **Dev/test with no SLA requirement** | Default outbound (legacy) | Not recommended; will break post-March 2026 for new VNets |

---

## Mitigation patterns

| Pattern | Effect |
|---|---|
| **Add more public IPs to NAT Gateway** | +64,512 ports per IP |
| **Use IP prefixes** | /28 = 16 IPs; simpler management |
| **Connection pooling** | Reuse HTTP connections; reduce port churn |
| **Reduce idle timeouts** | Recycle ports faster; default 4 min may be too long |
| **Multiple NAT Gateways** | Attach different gateways to different subnets to isolate SNAT pools |
| **Distribute destinations** | Avoid concentrating all traffic to one destination IP:port |
| **Private Endpoints for Azure PaaS** | Eliminates SNAT entirely — traffic stays on private IP path |

---

## Related pages

| Page | Relationship |
|---|---|
| [NAT Gateway](../services/nat-gateway.md) | Primary SNAT service; detailed configuration |
| [Load Balancer](../services/load-balancer.md) | Legacy outbound via outbound rules; SNAT port tables |
| [Azure Firewall](../services/azure-firewall.md) | Egress inspection; limited SNAT capacity without NAT Gateway |
| [Virtual Network](../services/virtual-network.md) | Default outbound access retirement details |
| [Private Link](../services/private-link.md) | Eliminates SNAT for Azure PaaS access |

---

## Source pages

| Source | Notes |
|---|---|
| [NAT Gateway](../services/nat-gateway.md) | SNAT ports per IP, dynamic allocation, exhaustion mitigation |
| [Load Balancer](../services/load-balancer.md) | Default SNAT port tables, outbound rules, priority order |
| [Azure Firewall](../services/azure-firewall.md) | SNAT per IP per instance, NAT Gateway integration |
| [Virtual Network](../services/virtual-network.md) | Default outbound access retirement (March 2026) |