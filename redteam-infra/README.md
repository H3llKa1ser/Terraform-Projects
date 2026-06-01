# Red Team Infra

# 1. Direct shell on the team server (jump through bastion)

    ssh -J ubuntu@<bastion_ip> ubuntu@<team_server_private_ip>

# 2. Reach the C2 management console locally via SSH tunnel

    ssh -J ubuntu@<bastion_ip> -L 31337:<team_server_private_ip>:31337 ubuntu@<team_server_private_ip>

# then point your C2 client at localhost:31337

# 3. Access GoPhish

# Tunnel the admin UI through the bastion

    ssh -J ubuntu@<bastion_ip> -L 3333:<gophish_private_ip>:3333 ubuntu@<gophish_private_ip>

# Then browse to:

    #   https://localhost:3333
    # (accept the self-signed cert)

# Get the initial admin password (run on the GoPhish box):

    journalctl -u gophish | grep -i "please login"

Or add this to ~/.ssh/config to make it seamless:

    Host rt-bastion
        HostName <bastion_ip>
        User ubuntu
    
    Host rt-teamserver
        HostName <team_server_private_ip>
        User ubuntu
        ProxyJump rt-bastion
        LocalForward 31337 <team_server_private_ip>:31337

    Host rt-gophish
        HostName <gophish_private_ip>
        User ubuntu
        ProxyJump rt-bastion
        LocalForward 3333 <gophish_private_ip>:3333

Then just: ssh rt-teamserver.

# Operational notes specific to this design

1) Team server is unreachable from the internet. SSH only via bastion; HTTPS C2 only via the HTTP redirector; DNS C2 only via the DNS redirector. Every ingress is source_security_group_id-scoped, not CIDR-open.

2) DNS delegation must point at your domain. If your C2 domain is registered elsewhere (not Cloudflare), set the NS/glue records at that registrar instead of using dns.tf. The DNS redirector's public IP becomes your authoritative nameserver for the delegated zone.

3) socat relay is intentionally dumb/transparent — it just forwards 53 to the team server's DNS listener (e.g., Sliver/Cobalt Strike DNS listener). Confirm your C2's DNS listener binds to the team server's private interface on dns_listener_port.

4) NAT gateway cost — as noted, swap for a NAT instance or drop egress entirely if you want $0. The team server can still receive beacons without outbound internet; it only needs egress for updates/tooling pulls.

5) Bastion hardening — consider adding session logging on the bastion (e.g., auditd + tlog) for your engagement audit trail.

6) Teardown: terraform destroy, then remove any registrar-side NS delegation and rotate tokens.

The Terraform code I wrote is **C2-agnostic** — it doesn't install or assume any specific C2 framework. It only stands up the *hosting infrastructure* (hardened hosts, network, redirectors, bastion). You install and configure the actual C2 yourself after provisioning.

That said, here's where the config makes C2-shaped assumptions you'd need to match to whatever you run:

## What the code assumes (and where to adjust)

| Setting | Default | What it maps to |
|---|---|---|
| `c2_listener_port` | `443` | Your C2's **HTTPS listener** port on the team server |
| `dns_listener_port` | `53` | Your C2's **DNS listener** port on the team server |
| C2 console port | `31337` | The **management/operator console** port (the SG rule + SSH tunnel use this) |
| Redirector proxy | Nginx → `https://<team_server>:443` | Forwards HTTP(S) beacons to the C2's HTTPS listener |
| DNS redirector | `socat` UDP/TCP 53 → team server | Forwards DNS beacons to the C2's DNS listener |

The `31337` port and the heredoc comments (e.g., *"Sliver/Mythic console"*) are just illustrative placeholders — I picked them as examples, not because the code targets a particular framework.

## Matching it to common frameworks

- **Sliver** — HTTPS + DNS listeners are native; multiplayer/operator port is typically **31337**, so the defaults line up almost directly. Probably the least adjustment needed.
- **Mythic** — Web UI/operator interface runs on a different port (often 7443); you'd change the console SG rule + tunnel port, and HTTP/DNS C2 profiles come from your chosen Mythic C2 profile (e.g., `http`, `dns`).
- **Cobalt Strike** — Team server uses **50050** for the client; HTTPS/DNS listeners are defined via Malleable C2 profiles. You'd change `31337 → 50050` and align the redirector profile to your Malleable config.
- **Havoc / Covenant / etc.** — Same idea: adjust the console port and listener ports.

## To adapt it
1. Set `c2_listener_port` / `dns_listener_port` to your framework's listener ports.
2. Change the `31337` references (in `security_groups.tf` and the `outputs.tf` tunnel command) to your framework's operator/console port.
3. Make sure the C2's listeners **bind to the team server's private IP** so the redirectors can reach them.

