# Red Team Infra

# 1. Direct shell on the team server (jump through bastion)

    ssh -J ubuntu@<bastion_ip> ubuntu@<team_server_private_ip>

# 2. Reach the C2 management console locally via SSH tunnel

    ssh -J ubuntu@<bastion_ip> -L 31337:<team_server_private_ip>:31337 ubuntu@<team_server_private_ip>

# then point your C2 client at localhost:31337

Or add this to ~/.ssh/config to make it seamless:

    Host rt-bastion
        HostName <bastion_ip>
        User ubuntu
    
    Host rt-teamserver
        HostName <team_server_private_ip>
        User ubuntu
        ProxyJump rt-bastion
        LocalForward 31337 <team_server_private_ip>:31337

Then just: ssh rt-teamserver.

# Operational notes specific to this design

1) Team server is unreachable from the internet. SSH only via bastion; HTTPS C2 only via the HTTP redirector; DNS C2 only via the DNS redirector. Every ingress is source_security_group_id-scoped, not CIDR-open.

2) DNS delegation must point at your domain. If your C2 domain is registered elsewhere (not Cloudflare), set the NS/glue records at that registrar instead of using dns.tf. The DNS redirector's public IP becomes your authoritative nameserver for the delegated zone.

3) socat relay is intentionally dumb/transparent — it just forwards 53 to the team server's DNS listener (e.g., Sliver/Cobalt Strike DNS listener). Confirm your C2's DNS listener binds to the team server's private interface on dns_listener_port.

4) NAT gateway cost — as noted, swap for a NAT instance or drop egress entirely if you want $0. The team server can still receive beacons without outbound internet; it only needs egress for updates/tooling pulls.

5) Bastion hardening — consider adding session logging on the bastion (e.g., auditd + tlog) for your engagement audit trail.

6) Teardown: terraform destroy, then remove any registrar-side NS delegation and rotate tokens.

