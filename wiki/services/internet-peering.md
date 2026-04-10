# Azure Internet Peering

> **Compiled:** 2026-04-10 | **Source articles:** 23 | **Status:** ✅ current

## What it is

**Azure Internet Peering** is the managed interconnection service between Microsoft's global
network (**AS8075**) and the networks of Internet Service Providers (ISPs), Network Service
Providers (NSPs), and Internet Exchange Providers (IXPs), used to exchange internet traffic
to and from Microsoft online services and Azure. Connections are provisioned as
**always-free Azure resources** (types: `PeerAsn` + `Peering`), enabling unified portal
management, BGP metrics, and support-ticket access from the same subscription used for other
Azure services. Connections established before this system existed are called **legacy
peerings** and can be converted to Azure resources at any time.

Key behavior:
- Microsoft's policy is **selective but generally open** — peers evaluated on performance,
  capability, and mutual benefit; Microsoft reserves the right to make exceptions
- **Both IPv4 and IPv6 sessions are required** in each peering location; **MD5 is not
  supported** [VERIFY]
- **BGP** is the sole routing protocol; connection states (ProvisioningStarted, Active, etc.)
  are distinct from standard BGP session states
- All peer routes must be registered in a public **Internet Routing Registry (IRR)** and
  conform to **MANRS** standards; Microsoft may reject unsigned/unregistered RPKI routes at
  its discretion
- Peers **must filter AS12076 (ExpressRoute) routes** on all peering sessions — no exceptions
- Microsoft **does not readvertise** peer prefixes to the internet

---

## Key capabilities

| Capability | Detail |
|---|---|
| Direct peering (PNI) | Physical direct connections over 100-Gbps single-mode fiber between peer and Microsoft edge routers; BGP sessions per routing policy; also called Private Network Interconnect |
| Exchange peering | Standard public peering through an Internet Exchange (IX) switch fabric; BGP sessions use IX-provided IP space |
| Peering Service (ISP) | Partner program providing enterprise-grade, geo-redundant, optimally routed public-internet connectivity; ISP registers customer prefixes |
| Peering Service Voice | Direct-peering variant optimized for communications services (SBCs, SIP gateways); requires BGP over BFD; integrates with Azure Communication Services and Microsoft Teams |
| Peering Service Exchange Route Server | IXP variant using a BGP mesh; partners register customer ASNs rather than prefixes; BGP mesh auto-provisioned when LAG is running |
| Legacy peering conversion | Pre-existing PNIs and exchange connections converted to Azure resources via portal; required for MAPS partnership |
| Prefix / ASN registration | Partners register IPv4 prefixes (or ASNs for route server variant) for validated, optimized routing; each prefix gets a unique prefix key for customer activation |
| Traffic metrics | Per-connection session availability, ingress/egress rate, flap count, and packet drop rate visible in Azure portal |
| Prefix telemetry | Registered prefix latency, customer prefix latency (route server), and BGP prefix events (announcements, withdrawals, primary/backup transitions) |
| Maintenance notifications | Azure Service Health integration; alertable via email, SMS, voice, and mobile app; legacy peerings notified via NOC email automatically |
| Type conversion | Existing Direct peerings (PNI → PNI+Peering Service, or PNI → Voice) can be converted in-place; conversions run one connection at a time during Pacific business hours |

---

## Peering types

### Direct peering (PNI)

Connections run over **100-Gbps single-mode fiber** directly between the peer's edge routers
and two Microsoft edge routers at a Microsoft edge PoP. Exclusively available to **ISPs and
NSPs**.

| Attribute | Value |
|---|---|
| Physical medium | 100-Gbps single-mode fiber [VERIFY] |
| Eligible peers | ISPs and NSPs only |
| Redundancy | Two connections to two different Microsoft edge routers; dual BGP sessions required |
| Session IPs | Allocated by Microsoft automated process after port configuration; delivered by email; may take **up to one week** after request submission [VERIFY] |
| Traffic minimum | 2 Gbps [VERIFY] |
| Port upgrade trigger | Peak utilization > 50% [VERIFY] |
| BGP provisioning | Microsoft provisions BGP with DENY ALL policy first; end-to-end validation before traffic allowed |
| SKU (standard PNI) | Basic Free [VERIFY] |
| SKU (Peering Service PNI) | Premium Free [VERIFY] |
| Deprovisioning | Not supported via portal or PowerShell; contact peering@microsoft.com |

**Provisioning flow:**
Request submitted → Microsoft contacts peer via registered email (LOA or additional info) →
`ProvisioningStarted` → peer completes wiring per LOA → optional link test (169.254.0.0/16) →
BGP session configured → peer notifies Microsoft → Microsoft end-to-end validation → `Active`

---

### Exchange peering

Connections run through the switch fabric of an **Internet Exchange (IX)**; physical
infrastructure managed by the IX. IPs provided by the IX.

| Attribute | Value |
|---|---|
| Physical medium | IX switch fabric port; minimum 10-Gbps [VERIFY] |
| Eligible peers | Any peer present at the IX |
| Session IPs | Provided by the IX |
| Traffic range | 500 Mbps minimum – 2 Gbps maximum [VERIFY]; above 2 Gbps, Direct peering should be used |
| Port upgrade trigger | Peak utilization > 50% [VERIFY] |
| BGP provisioning | Microsoft provisions BGP with DENY ALL policy; end-to-end validation before traffic allowed |
| SKU | Basic Free [VERIFY] |
| Deprovisioning | Not supported via portal or PowerShell; contact peeringexperience@microsoft.com |

**Provisioning flow:**
Request submitted → Microsoft reviews → `Approved` → peer configures BGP → peer notifies
Microsoft → Microsoft end-to-end validation → `Active`

---

### Peering Service connection sub-types

All Peering Service variants require a **signed Microsoft Azure Peering Service agreement**.
Contact peeringservice@microsoft.com to initiate. All use **SKU: Premium Free** [VERIFY].

| Sub-type (`Microsoft network` field in portal) | Target partner | Key differentiator |
|---|---|---|
| **AS8075** | ISPs (standard Peering Service) | Standard Direct PNI enabled for Peering Service; partner registers customer IPv4 prefixes; prefix keys issued for customer activation |
| **AS8075 (with Voice)** | Communications services providers | Requires **BGP over BFD** for sub-second convergence; Microsoft provides session IPs (peer cannot provide own IPs); integrates with Azure Communication Services and Microsoft Teams |
| **AS8075 (with exchange route server)** | Internet Exchange Providers (IXPs) | BGP mesh provisioned automatically when LAG is up; partner registers **customer ASNs** (not prefixes); same prefix key valid across all customer prefixes under that ASN |

---

## Architecture patterns

### Pattern 1 — Standard Direct peering (PNI)
