# Zero Trust Application Delivery with App Gateway and Private Link

> **Compiled:** 2026-04-10 | **Type:** Pattern | **Status:** ✅ current

This pattern implements Zero Trust principles for web application delivery: all traffic is explicitly verified at the WAF, backends have no public IP and are reachable only via Private Endpoints, and NSG rules enforce least-privilege network access. The result is a hardened ingress path where every connection is inspected, no resource trusts another implicitly, and breach blast radius is minimized.

---

## Architecture diagram

```
                          INTERNET
                              │
                              ▼
              ┌───────────────────────────────┐
              │    PUBLIC IP (Standard SKU)   │
              │    ───────────────────────    │
              │    DDoS Protection enabled    │
              └───────────────────────────────┘
                              │
                              ▼
              ┌───────────────────────────────┐
              │  APPLICATION GATEWAY WAF_v2   │
              │                               │
              │  Subnet: AppGatewaySubnet     │
              │  (/24 recommended)            │
              │                               │
              │  - Public frontend listener   │
              │  - TLS termination            │
              │  - WAF Policy (Prevention)    │
              │  - mTLS (optional)            │
              │  - URL routing rules          │
              │  - Health probes              │
              └───────────────────────────────┘
                              │
                   Private IP (10.0.1.x)
                              │
                              ▼
              ┌───────────────────────────────┐
              │     BACKEND SUBNET            │
              │     (Private — no PIP)        │
              │                               │
              │  NSG: Allow ONLY from         │
              │  AppGatewaySubnet on          │
              │  ports 443/8443               │
              │                               │
              │  ┌─────────────────────────┐  │
              │  │   PRIVATE ENDPOINT      │  │
              │  │   (NIC with private IP) │  │
              │  │                         │  │
              │  │   → App Service         │  │
              │  │   → AKS Internal LB     │  │
              │  │   → Container Apps      │  │
              │  │   → Internal LB + VMs   │  │
              │  └─────────────────────────┘  │
              └───────────────────────────────┘
                              │
                   Private DNS Zone
                   (privatelink.azurewebsites.net)
                              │
              ┌───────────────────────────────┐
              │     BACKEND SERVICE           │
              │     (No public IP)            │
              │                               │
              │  - App Service (PE-only)      │
              │  - AKS private cluster        │
              │  - VMs behind ILB             │
              └───────────────────────────────┘
```

---

## Zero Trust principles applied

### 1. Verify explicitly

Every request is inspected before reaching the backend:

| Control | Component | Configuration |
|---|---|---|
| **WAF inspection** | App Gateway WAF_v2 | DRS 2.1+ managed rules; anomaly scoring; Prevention mode |
| **Request body inspection** | WAF Policy | Enabled (critical — prevents SQLi/XSS in POST bodies) |
| **Bot protection** | WAF Bot Manager 1.1 | Good/Bad/Unknown classification; block or challenge bad bots |
| **Client certificate auth (mTLS)** | App Gateway SSL Profile | Strict mode: gateway validates client cert against trusted CA |
| **JWT validation** | Backend application | Validate tokens at backend; App Gateway passes through |

### 2. Least privilege access

No resource has more network access than absolutely required:

| Control | Implementation |
|---|---|
| **No public IP on backend** | App Service: Access Restrictions → Deny all public; AKS: private cluster; VMs: no PIP |
| **Backend only reachable via Private Endpoint** | Create PE for App Service/ILB; backend has no public attack surface |
| **NSG on backend subnet** | Allow inbound only from `AppGatewaySubnet` CIDR on backend port (443/8443) |
| **NSG on App Gateway subnet** | Allow inbound 65200–65535 from `GatewayManager` (required for v2); allow 443 from Internet |
| **No lateral movement** | Backend subnet cannot initiate connections to other subnets (NSG outbound deny except required) |

### 3. Assume breach

Detection and response controls limit blast radius:

| Control | Implementation |
|---|---|
| **Diagnostic logs to Log Analytics** | App Gateway: access logs, WAF logs, performance logs; PE: bytes in/out |
| **WAF in Prevention mode** | Blocks attacks in real-time; logs every blocked request for forensics |
| **Alert on anomalies** | Alert rules for: WAF block spikes, unexpected 4xx/5xx, unusual source geo |
| **Microsoft Sentinel integration** | WAF solution with pre-built analytic rules (SQLi, XSS, Log4J, path traversal) |
| **Session recording** (if using Bastion) | Bastion Premium records admin sessions for audit |

---

## Key configuration areas

### 1. WAF Policy configuration

| Setting | Value | Rationale |
|---|---|---|
| Mode | **Prevention** | Blocks malicious requests; Detection mode logs only — not Zero Trust |
| Rule set | DRS 2.1 or 2.2 | Latest Microsoft rules; includes Threat Intelligence collection |
| Request body inspection | **Enabled** | Without this, attackers embed payloads in POST bodies and bypass all rules |
| Bot Manager | 1.1 | Classifies and blocks bad bots; JS Challenge for suspicious requests |
| Anomaly scoring threshold | 5 (default) | Single Critical match blocks; cumulative lower-severity can also block |
| Custom rules | Rate limiting, geo-block | Block by source country; rate limit per-client IP |

**Per-site / per-URI policies:** App Gateway v2 supports attaching different WAF policies to different listeners or path-based rules. Use this to apply stricter rules to `/admin` paths.

### 2. Private Endpoint DNS configuration

DNS is the most common failure mode. The Private Endpoint must resolve correctly from App Gateway's VNet.

| DNS approach | Configuration |
|---|---|
| **Azure Private DNS Zone (recommended)** | Create zone (e.g., `privatelink.azurewebsites.net`); link to App Gateway VNet; PE auto-registers A record |
| **Custom DNS server** | Conditional forwarder for `privatelink.*` zones → Azure DNS (`168.63.129.16`) or DNS Private Resolver inbound endpoint |

**Validation:** From a VM in the same VNet as App Gateway, run `nslookup myapp.azurewebsites.net`. It should return the private IP of the Private Endpoint, not the public IP.

### 3. mTLS (mutual TLS) configuration

mTLS requires clients to present a certificate. App Gateway validates the certificate chain against trusted CAs.

| Component | Setting |
|---|---|
| SSL Profile | Create SSL Profile → Client authentication → Enable |
| Trusted client CA | Upload root CA cert(s) (max 25 KB per cert [VERIFY]) |
| Mode | **Strict** (App Gateway validates) or **Passthrough** (backend validates) |
| OCSP | Enable for revocation checking |
| Limit | 100 trusted CA chains per SSL profile; 200 per gateway [VERIFY] |

**Use case:** IoT devices, B2B API consumers, or internal services presenting machine certificates.

### 4. NSG design

#### App Gateway subnet NSG (required rules)

| Direction | Source | Destination | Port | Protocol | Action |
|---|---|---|---|---|---|
| Inbound | Internet | * | 443 | TCP | Allow |
| Inbound | Internet | * | 80 | TCP | Allow (if redirect to 443) |
| Inbound | GatewayManager | * | 65200–65535 | TCP | **Allow (required for v2)** |
| Inbound | AzureLoadBalancer | * | * | Any | Allow |
| Outbound | * | VirtualNetwork | * | Any | Allow |
| Outbound | * | Internet | * | Any | Allow |

> ⚠️ Without the `GatewayManager` inbound rule on 65200–65535, App Gateway v2 health probes fail and the gateway becomes unhealthy.

#### Backend subnet NSG (least privilege)

| Direction | Source | Destination | Port | Protocol | Action |
|---|---|---|---|---|---|
| Inbound | `AppGatewaySubnet` CIDR | * | 443, 8443 | TCP | Allow |
| Inbound | AzureLoadBalancer | * | * | Any | Allow (for health probes) |
| Inbound | * | * | * | Any | **Deny** |
| Outbound | * | AzureCloud | 443 | TCP | Allow (Azure management) |
| Outbound | * | * | * | Any | Deny (or allow selectively) |

### 5. Header handling

| Header | Behavior | Configuration |
|---|---|---|
| `X-Forwarded-For` | App Gateway appends client IP | Backend should trust this header for logging |
| `X-Forwarded-Proto` | Shows original protocol (http/https) | Use for redirect logic in backend |
| `Host` | By default, preserves original Host header | Override with HTTP settings → "Pick host name from backend target" if backend requires specific host |
| Client cert header | mTLS client cert passed to backend | Configure `frontend_certificate` header in rewrite rules |

---

## Integration with Azure security services

| Service | Integration |
|---|---|
| **Azure Policy** | Built-in policies: audit WAF not enabled, mandate Prevention mode, require request body inspection |
| **Microsoft Defender for Cloud** | Flags unprotected web apps; displays WAF health; recommendations for hardening |
| **Microsoft Sentinel** | WAF solution in Content Hub; pre-built analytic rules (SQLi, XSS, Log4J, path traversal, code injection) |
| **Security Copilot** | AI-assisted WAF log investigation (App Gateway WAF_v2 supported) |

---

## When to use this pattern vs alternatives

| Scenario | Recommendation |
|---|---|
| Public-facing web app, backend must have zero public exposure | ✅ This pattern — App Gateway + Private Endpoint |
| Global users, need edge WAF + CDN | Use **Front Door Premium** as global edge; Front Door → Private Link → App Gateway → Private Endpoint |
| Backend is App Service with public IP acceptable | Simpler: App Gateway → App Service via public IP with App Service Access Restrictions (less Zero Trust) |
| Internal-only app, no internet ingress | Use **private-only App Gateway** (no public frontend) → Private Endpoint |
| AKS workloads with Kubernetes-native ingress | Use **AGIC** (Application Gateway Ingress Controller) or **App Gateway for Containers** |

---

## Decision checklist

| # | Question | Expected answer for this pattern |
|---|---|---|
| 1 | Does the backend need to be unreachable from the public internet? | Yes |
| 2 | Is WAF required for L7 attack protection? | Yes |
| 3 | Is client certificate authentication (mTLS) required? | Optional — this pattern supports it |
| 4 | Is all traffic over HTTPS (no TCP/UDP)? | Yes |
| 5 | Is the backend an Azure PaaS service (App Service, Container Apps) or IaaS behind ILB? | Yes |
| 6 | Can you manage Private DNS zones for Private Endpoint resolution? | Yes |

---

## Common pitfalls

| Pitfall | Symptom | Fix |
|---|---|---|
| Private DNS zone not linked to App Gateway VNet | App Gateway health probes fail; 502 errors | Link the `privatelink.*` zone to the VNet containing App Gateway |
| Request body inspection disabled | SQLi/XSS in POST bodies bypass WAF | Enable in WAF policy (it's disabled by default in some configurations) |
| Missing GatewayManager NSG rule | App Gateway shows unhealthy; no traffic flows | Add inbound Allow for `GatewayManager` service tag on 65200–65535 |
| Backend still has public endpoint enabled | Attackers bypass App Gateway by hitting public URL | App Service: Access Restrictions → Deny all; AKS: private cluster |
| Host header mismatch | App Service returns 404 or redirect loops | Override Host header in App Gateway HTTP settings to match App Service hostname |

---

## Service limits reference [VERIFY all]

| Limit | Value | Notes |
|---|---|---|
| Trusted client CA chains per SSL profile | 100 | mTLS |
| Trusted client CA chains per gateway | 200 | mTLS |
| Private endpoints per VNet | 1,000 (default); 5,000 (High Scale) | |
| App Gateway max instances | 125 | Scale-out 3–5 min |
| App Gateway subnet minimum | /24 recommended | Supports 125 instances + 5 reserved IPs |
| WAF custom rules per policy | 100 | |

---

## Related pages

| Page | Relationship |
|---|---|
| [Application Gateway](../services/application-gateway.md) | WAF_v2, mTLS, private deployment, backend pools |
| [Private Link](../services/private-link.md) | Private Endpoint architecture, DNS zones, network policies |
| [Web Application Firewall](../services/web-application-firewall.md) | DRS rules, Bot Manager, request body inspection, anomaly scoring |
| [Network Security Design](../concepts/network-security-design.md) | Defense-in-depth, Zero Trust checklist, NSG design |
| [Azure DNS](../services/dns.md) | Private DNS zones, split-horizon DNS |

---

## Source pages

| Source | Notes |
|---|---|
| [Application Gateway](../services/application-gateway.md) | WAF_v2 SKU, mTLS, SSL profiles, private deployment, NSG requirements |
| [Private Link](../services/private-link.md) | Private Endpoint creation, DNS configuration, network policies |
| [Web Application Firewall](../services/web-application-firewall.md) | DRS rule sets, Prevention mode, request body inspection, Bot Manager |
| [Network Security Design](../concepts/network-security-design.md) | Zero Trust principles, WAF hardening checklist |
