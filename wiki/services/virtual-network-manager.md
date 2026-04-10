# Azure Virtual Network Manager

> **Compiled:** 2026-04-10 | **Source articles:** 52 | **Status:** ✅ current

## What it is

**Azure Virtual Network Manager (AVNM)** is a centralized management service that lets you group, configure, deploy, and manage **virtual networks** globally across subscriptions and tenants from a single control plane. You define a **scope** (management groups and/or subscriptions), organize VNets into **network groups**, then author **configurations** for connectivity, security, and routing that are pushed to those groups at scale.

Key behavior:
- Configurations **do not take effect until explicitly deployed** to one or more regions — creating a config has no runtime impact.
- AVNM operates on a **goal-state model**: committing a deployment describes the desired end state for a region; any previously deployed config not included in the new commit is automatically removed.
- A network manager only has delegated access within its defined scope; resources outside scope are ignored even if added to a network group.
- AVNM is **highly available and regionally resilient**: if the region hosting the AVNM instance goes down, already-deployed configurations continue operating on their target VNets until those VNets' own region is affected.
- Changes to network group membership (add/remove VNet) propagate to active configs **without requiring a redeployment**.

---

## Key capabilities

| Capability | Detail |
|---|---|
| **Connectivity configurations** | Create mesh or hub-and-spoke topologies across VNets at scale using virtual network peering (hub-spoke) or connected groups (mesh). |
| **Security admin configurations** | Define global network security rules evaluated **before** NSG rules. Actions: Allow, Always Allow, Deny. Enforce org-wide policy while leaving NSG flexibility to teams. |
| **Routing configurations (UDR management)** | Orchestrate user-defined routes (UDRs) at scale across subnets and VNets. Up to 1,000 UDRs per route table (vs. traditional 400 limit). [VERIFY] |
| **IP Address Management (IPAM)** | Centrally manage IPv4/IPv6 address pools with hierarchical pool structures (up to 7 layers). Automatically allocates non-overlapping CIDRs to Azure resources. |
| **Network Verifier** | Static reachability analysis tool — validates that NSG rules, security admin rules, peerings, route tables, private endpoints, and VNet topologies produce the expected traffic paths. |
| **Network groups** | Logical containers for VNets; membership is static (manual) or dynamic (Azure Policy with `addToNetworkGroup` effect). |
| **Cross-tenant management** | Extend AVNM scope across tenants with a two-way consent model (network manager connection + VNet manager hub connection). |
| **Azure Policy integration** | Drive dynamic group membership using Azure Policy definitions in `Microsoft.Network.Data` mode. |
| **Event logs (Azure Monitor)** | Three log categories: network group membership changes, rule collection changes, connectivity configuration changes. Sent to Log Analytics, Storage, or Event Hub. |
| **Virtual network flow logs** | Monitor traffic blocked or allowed by security admin rules via Network Watcher VNet flow logs. |
| **Topology View** | Visual preview of connectivity configuration topology during authoring and post-deployment review. |
| **Azure Resource Graph** | All group membership is queryable from Azure Resource Graph; every VNet has a single entry listing all its group memberships. |

---

## Core concepts

### Scope

The **scope** defines the boundary of management groups and/or subscriptions that AVNM can view and manage. Key scope rules:

- Scope can span multiple management groups and/or multiple subscriptions, including across tenants (with two-way consent).
- **You cannot create two network managers with overlapping scope and the same features enabled.**
- Higher-scope network managers take precedence over lower-scope ones in configuration conflicts.
- Scope updates trigger automatic reevaluation — added subscriptions can automatically receive configs; removed subscriptions automatically lose them.
- Limit: customers with **>15,000 subscriptions** cannot apply AVNM policy at management-group level; must scope at lower-level management groups. [VERIFY]

### Network groups

A **network group** is a global logical container of VNet resources used as the target for configuration deployment.

| Membership type | How it works |
|---|---|
| **Static** | Explicitly select individual VNets. Immediate effect. Works for cross-tenant VNets (only supported membership type for cross-tenant). |
| **Dynamic** | Azure Policy definition with `addToNetworkGroup` effect. Policy mode must be `Microsoft.Network.Data`. For scopes <1,000 subscriptions: membership updates within minutes. For scopes >1,000 subscriptions: Azure Policy notifies within a 24-hour window, then active configs apply within minutes after notification. |

- A VNet can belong to **multiple network groups** simultaneously (many-to-many).
- No limit on the number of network groups you can create.
- Cross-tenant VNets can **only** be added via static membership.
- Membership is visible in **Azure Resource Graph**.

### Connectivity configurations

Two topology types:

**Mesh topology:**
- All VNets in the group are bidirectionally connected via a **connected group** (not peering — shows as `ConnectedGroup` next-hop type in effective routes).
- Default: regional mesh (same-region VNets only). Enable **global mesh** for cross-region.
- Overlapping address spaces are permitted in a mesh but traffic to overlapping CIDRs is dropped (nondeterministic routing). Use `ConnectedGroupAddressOverlap: Disallowed` property to enforce non-overlap at admission time.
- A VNet can belong to up to **2 connected groups** (soft limit, adjustable). [VERIFY]

**Hub-and-spoke topology:**
- Hub VNet is bidirectionally **peered** (VNetPeering / GlobalVNetPeering next-hop) to every spoke VNet in the selected spoke network groups.
- Optional: **direct connectivity** per spoke group creates a connected group across that spoke group's VNets (reduces latency by removing hub transit hop).
- Optional: **global mesh** per spoke group enables cross-region direct connectivity.
- Optional: **use hub as gateway** — spoke VNets use hub's VPN/ExpressRoute gateway. Peering creation from spoke to hub **fails** if no gateway exists in hub.
- Optional: **peering enforcement** (`peeringEnforcement: Enforced`) prevents deletion/modification of peerings outside AVNM.
- Optional: **delete existing peerings** removes manually created peerings that don't match the config.
- Multiple connectivity configurations can coexist in the same region; connectivity is **additive**.
- Up to **1,000 spoke VNets** per hub. [VERIFY]

**Connected group internals:**
- Connected groups are AVNM-exclusive constructs — connectivity does not appear under a VNet's Peerings blade.
- Enables higher scale than traditional peering.
- Default: 250 VNets per connected group (soft limit, can increase to 1,000 on request). [VERIFY]
- Preview feature `AllowHighScaleConnectedGroup`: up to 5,000 VNets per connected group in supported regions. [VERIFY]

### Security admin configurations

- Security admin rules are **evaluated before NSG rules**. Rule actions: **Allow** (NSGs evaluate next), **Always Allow** (terminates evaluation, traffic passes), **Deny** (terminates evaluation, traffic dropped).
- Rules specify: priority (1–4096, lower = higher priority), action, direction (inbound/outbound), protocol (TCP, UDP, ICMP, ESP, AH, Any), source/destination (IP addresses, CIDR, or service tags).
- **Only one security admin configuration per region per AVNM instance** — to deploy multiple rule sets, use multiple rule collections within one config.
- Central governance team uses security admin rules as org-wide guard rails; individual teams retain flexibility via NSGs.
- Use **priority ordering** to create exceptions: e.g., Allow SSH for App network group at priority 10, Deny SSH for ALL network group at priority 100.
- Security admin rules are applied at the **VNet level**; NSGs are applied at subnet and NIC level.

**Nonapplication of security admin rules (services that override/skip):**

| Level | Services where security admin rules are skipped by default |
|---|---|
| VNet level | Azure SQL Managed Instance, Azure Databricks |
| Subnet level | Azure Application Gateway (without network isolation), Azure Bastion, Azure Firewall, Azure Route Server, Azure VPN Gateway, Azure Virtual WAN, Azure ExpressRoute Gateway |

- For VNet-level skips: can opt in to Allow-only rules using `AllowRulesOnly` on `securityConfiguration.properties.applyOnNetworkIntentPolicyBasedServices`.
- Security admin rules **do not apply to private endpoints** in managed VNets.
- Uses **eventual consistency** model — newly added resources receive rules after a short delay.

### Routing configurations (UDR management)

- Describe desired routing behavior via **route collections** targeting a network group, containing **route rules** (destination type + next hop).
- Next hop types: Virtual network gateway, Virtual network, Internet, Virtual appliance.
- Supports **Azure Firewall** as next hop (import private IP directly in portal).
- Up to **1,000 UDRs per route table** (AVNM-managed, vs. 400 traditional limit). [VERIFY]
- Route table modes: **ManagedOnly** (AVNM creates/owns route tables in managed resource group) or **UseExisting** (AVNM appends to existing subnet route tables; preview, requires API version 2025-01-01+). [VERIFY]
- Conflicting rules (same destination, different next hops) within or across rule collections targeting same VNet/subnet are not supported; one is applied arbitrarily.
- Managed resource group naming convention: `AVNM_Managed_ResourceGroup_<subscriptionId>`.

### Deployments (goal-state model)

| Fact | Detail |
|---|---|
| **Deploy to take effect** | Configs are inert until deployed to specific regions. |
| **Goal state** | Committing configs C1+C2 to a region establishes them as the goal state. Deploying C1+C3 next removes C2 and adds C3. |
| **Remove all configs** | Deploy `None` to a region. |
| **Multiple connectivity configs** | Additive in a region; all must be redeployed together when any one is modified. |
| **One security admin config per region** | Use multiple rule collections for multiple rule sets. |
| **Config changes ~15-20 min** | Deployment applies within ~15-20 minutes after commit. Network group membership changes reflect in ~10 minutes (manual: immediate; policy-based <1,000 subs: minutes; >1,000 subs: up to 24 hours for policy notification). |
| **Regional availability** | If the AVNM instance's home region goes down, already-deployed configs remain operative on target VNets until those VNets' own region is affected. |

### IP Address Management (IPAM)

- Create hierarchical IP pools: **root pool** (top-level CIDR) → **child pools** (subdivisions, up to 7 layers deep). [VERIFY]
- Automatically allocate non-overlapping CIDRs to VNets from a selected pool.
- Supports IPv4 and IPv6 pools.
- Delegate pool access to other users via **IPAM Pool User** role (+ Network Manager Read for full discoverability).
- Preview: single IPAM pool can span VNets across multiple regions.
- Charged separately from AVNM — per active IP address (associated with a NIC in a VNet associated with an IP pool) at hourly rate. [VERIFY]
- Limitation: removing IPAM-managed address spaces from VNets/subnets is not supported.

### Network Verifier

- Available through a **verifier workspace** child resource on each AVNM instance.
- Workspace permissions can be delegated independently of the parent network manager.
- Analyze reachability between: VMs, VM scale set instances, subnets, internet, Cosmos DB, storage accounts, SQL servers.
- Evaluates: NSG rules, ASG rules, security admin rules, connected groups, VNet peering, route tables, service endpoints/ACLs, private endpoints, Virtual WAN, Azure Firewall (static L4). [VERIFY list completeness]
- Charged per reachability analysis run (separate from AVNM charges). [VERIFY]
- Limitation: subnet source/destination must have at least one running VM for results.

---

## Architecture patterns

### Pattern 1 — Hub-and-spoke at scale (most common)

