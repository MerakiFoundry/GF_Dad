# GF Dad Lightsail foundation

Provisioned October 2, 2026. This is hosting infrastructure, not a deployed recipe application.

## Inventory and runtime decision

Provisioning credentials identified as the authenticated AWS account root. Those credentials were not copied to the instance or GitHub. Prefer a scoped administrative role for future AWS management.

Before provisioning, all 15 Lightsail regions within the account's 17 enabled AWS regions had no instances, static IPs, instance/disk snapshots, extra disks, databases, load balancers, containers or buckets. Regional resource-tag searches found no GF Dad matches. Route 53 had no zones. Existing S3, CloudFormation and EC2 resources identified in us-east-1 belonged to an unrelated project and were untouched. Tag searches are not an exhaustive inventory of untagged AWS resources.

`MerakiFoundry/GF_Dad` contains recipe Markdown, templates and documentation only. `Schiavo-Enterprises/GF` contains an older ZIP of recipe material, also without application code. The other visible repository, `site-insight`, is an unrelated application. No GF Dad website repository was identified among accessible repositories. The initial foundation had no application runtime. At the user’s subsequent request, Node.js 24 LTS and build tools were added as described below. No Docker, database or application systemd service is installed. When Lovable or another tool produces the website, inspect its build, SSR and server-function requirements first.

## Application build tools

Added October 2, 2026 at the user’s request; this supersedes the initial decision to defer Node installation.

- Node.js **24.21.0 LTS (Krypton)** with bundled npm **11.19.0** and npx.
- Official Linux x64 archive installed under `/opt/node/node-v24.21.0-linux-x64`; `/opt/node/current` selects the version, and `/usr/local/bin` provides node/npm/npx.
- Download verified against the SHA-256 manifest retrieved from nodejs.org over HTTPS. Node updates are deliberate: Ubuntu unattended-upgrades does not update this installation. Check Node security releases and update the pinned installer/version after compatibility tests.
- Ubuntu `build-essential` (GCC/G++/make), Python 3, pkg-config, CA certificates, xz, unzip, Git, curl and rsync.
- A 2 GB swap file at `/swapfile-gfdad`, mode 0600, enabled persistently via `/etc/fstab`, swappiness 10. It consumes existing SSD capacity with no additional AWS charge. Swap helps absorb memory spikes but does not make large builds fast or guarantee they fit.
- Writable build/source directories: `/var/www/gfdad/source` and `/var/www/gfdad/builds`, owned by gfdad and outside Nginx’s document root.

Reproduce this addition by uploading `infra/lightsail/install-app-tools.sh` to `/tmp/` and running `sudo bash /tmp/install-app-tools.sh` after the baseline bootstrap.

Run package installation and builds as **gfdad**, never root. For an actual npm application, commit `.nvmrc` containing `24.21.0`, declare its Node engine/package-manager requirements, commit `package-lock.json`, and use `npm ci` followed by the application’s documented build/test commands. These files belong in the future application repository; they are not being added to the recipe collection. If the application uses pnpm, Yarn or Bun, install the exact package manager specified by that repository instead of replacing its lockfile.

Verified as gfdad: npm dependency installation and clean `npm ci`, TypeScript bundling with esbuild, execution of the resulting JavaScript, and compilation/execution of a small native C program. Temporary test files were removed. npm reported an unapproved esbuild install script; the test used the downloaded platform package successfully without broadly allowing lifecycle scripts. Review required package install scripts for the real application. Swap is active with root-only permissions, Nginx health still passes, and no new public listeners were added.

Nginx, Certbot and systemd are already available for hosting. No framework, development server, dummy application, paid service or additional public port was added. A production app service, proxy route and application-aware health check must be configured against the actual server entry point. Prefer workstation/CI builds for larger applications on this 1 GB instance.

## Created resources and cost

| Resource | Configuration | Expected monthly cost |
|---|---|---:|
| gfdad-web-01 | us-east-1a, Ubuntu 24.04 LTS, micro_3_0, 1 GB RAM, 2 vCPU, 40 GB SSD, 2,048 GB transfer, IPv4 | $7 |
| gfdad-web-ip | 18.206.101.202, attached to gfdad-web-01 | $0 while attached |
| SSH key pair | gfdad-admin, public key only in Lightsail | $0 |
| Snapshots | Disabled; none created | $0 |
| DNS | Existing provider retained; no AWS zone created | $0 new AWS cost |
| Other AWS resources | None created | $0 |
| **New GF Dad total** | Before tax/transfer overages; no promotional credit assumed | **$7** |

Unrelated account charges and existing domain registration fees are excluded. A detached static IP may incur charges; keep it attached. Snapshots are optional at $0.05 per stored GB-month: 40 GB of billable snapshot storage would be $2/month. Actual incremental storage varies; automatic snapshots retain seven daily restore points and are not a flat $2 add-on. No recurring backup spending is enabled. Source: https://aws.amazon.com/lightsail/pricing/

## Access and security

Admin from this Mac:

```sh
ssh -i ~/.ssh/gfdad-lightsail-admin-rsa ubuntu@18.206.101.202
```

Deployment account (no sudo):

```sh
ssh -i ~/.ssh/gfdad-lightsail-deploy gfdad@18.206.101.202
```

Private keys exist only under the administrator’s local `~/.ssh/`, mode 0600; the directory is 0700. They are unencrypted local keys, so protect this Mac and retain a secure backup. The RSA admin public key was imported into Lightsail; the Ed25519 deployment key was installed directly on the server. Neither private key is in the repository. Initial SSH host trust was established on first connection to the freshly allocated address; preserve the known_hosts entry.

Lightsail allows TCP 80 and 443 from all IPv4 addresses, and TCP 22 only from the administrator’s current public IPv4 `/32`. IPv6 is disabled. UFW denies other incoming traffic and permits these same three ports, with SSH source filtering at Lightsail. Browser SSH is intentionally unavailable under that rule. If your home IP changes, sign into Lightsail in Chrome, open this instance → Networking, and replace the SSH source with your new single `/32`; do not open SSH to everyone. No database, development or Docker ports are public.

SSH password and root login are disabled. Only ubuntu and gfdad can SSH; forwarding is disabled for gfdad. Fail2ban protects SSH. Automatic security updates are enabled, with automatic reboot disabled. Reboot deliberately after updates when `/var/run/reboot-required` exists. Timezone is UTC. No AWS credentials or application secrets were installed.

## Layout and services

- `/var/www/gfdad/releases/RELEASE_ID`: complete, prebuilt deployment artifacts; owned by gfdad.
- `/var/www/gfdad/current`: atomically replaced symlink to the active release; absent until the first real deployment.
- `/var/www/gfdad/shared`: future runtime/generated data, outside the public document root.
- `/etc/gfdad/app.env`: empty environment file, root:gfdad 0640, parent 0750. Use `sudoedit`; never commit secrets. A future systemd unit should reference it with `EnvironmentFile=`.
- `/etc/nginx/sites-available/gfdad`: active HTTP site, symlinked from sites-enabled.
- `/etc/nginx/sites-available/gfdad-https.prepared`: inactive HTTPS configuration; requires certificates before activation.
- `/etc/systemd/system/`: future application unit location; no gfdad application service exists yet.
- `/usr/local/bin/gfdad-deploy-static`: non-root static artifact activation helper.
- `/var/log/nginx/gfdad-access.log` and `gfdad-error.log`: web logs, covered by Ubuntu's Nginx log rotation.
- `/var/log/gfdad/`: optional future application file logs with weekly rotation, four retained compressed rotations.
- Future application stdout/stderr should go to journald; persistent journal capped at 100 MB.

```sh
sudo systemctl status nginx fail2ban unattended-upgrades
sudo journalctl -u nginx --since today
sudo tail -n 50 /var/log/nginx/gfdad-error.log
sudo tail -n 50 /var/log/nginx/gfdad-access.log
sudo ufw status verbose
sudo sshd -T
sudo nginx -t
```

`GET /health` returns `200 web-ready`. This checks Nginx only, not a nonexistent application. The root path returns 503 until a real artifact is deployed. Replace the health route with application readiness when an application is installed.

## Minimal deployment procedure

Build/test in the actual application repository on a workstation or CI, using its lockfile and documented production command. Do not deploy the recipe repository itself, source trees, .env files or node_modules as static content.

For a confirmed static site, from the directory containing a reviewed build output named `dist`:

```sh
release=$(date -u +%Y%m%dT%H%M%SZ)
ssh -i ~/.ssh/gfdad-lightsail-deploy gfdad@18.206.101.202 "mkdir /var/www/gfdad/releases/$release"
rsync -rt --exclude='.*' -e 'ssh -i ~/.ssh/gfdad-lightsail-deploy' dist/ "gfdad@18.206.101.202:/var/www/gfdad/releases/$release/"
ssh -i ~/.ssh/gfdad-lightsail-deploy gfdad@18.206.101.202 "gfdad-deploy-static $release"
curl --fail http://18.206.101.202/health
curl --fail -H 'Host: gfdad.com' http://18.206.101.202/
```

Validate actual pages/assets too: `/health` alone does not prove artifact correctness. To roll back, run `gfdad-deploy-static PREVIOUS_RELEASE_ID`. Keep immutable, unique release directories and remove old artifacts only after reviewing them. No privileged restart is needed for static deployment. No SPA fallback or long-lived asset cache is assumed until the actual router and hashed-asset conventions are known.

For Node/TanStack Start, first inspect SSR/server functions and the production server entry point. Node.js 24 LTS is available; confirm that the application supports it. Build outside this 1 GB instance where practical, use a systemd unit with `User=gfdad`, and bind to `127.0.0.1:3000`. Replace the Nginx static location with an appropriate reverse proxy. Do not use a development server. Reassess memory using real measurements before selecting 2 GB.

No GitHub Actions workflow is enabled because no application/build exists. The manual artifact path above needs no AWS credentials. A future SSH workflow would need `LIGHTSAIL_HOST`, `LIGHTSAIL_USER`, `LIGHTSAIL_SSH_KEY` (a dedicated deployment key, not the administrator key), and `LIGHTSAIL_KNOWN_HOSTS` pinned from a trusted admin connection. Use a runner with a stable, explicitly allowed egress IP; standard GitHub-hosted runners cannot connect through the current home-IP-only rule. Do not solve that by globally exposing SSH or placing root AWS credentials in GitHub.

## Domain and HTTPS cutover (not performed)

Nameservers remain `ns45.domaincontrol.com` and `ns46.domaincontrol.com`. At inspection, the apex resolved to `13.248.243.5` and `76.223.105.230`, with www aliasing the apex. DNS was not modified.

After explicit cutover authorization and a ready application, replace the existing web records at the current DNS provider with:

| Type | Name | Value | Suggested TTL |
|---|---|---|---|
| A | @ | 18.206.101.202 | 300 seconds |
| CNAME | www | gfdad.com | 300 seconds |

Preserve email/TXT records. Remove conflicting web A/AAAA records only as part of that authorized cutover. This server has no IPv6, so do not publish an AAAA record. Verify both names resolve to the new server and check any CAA records permit Let's Encrypt.

Certbot and its renewal timer are installed but no certificate has been requested. Once DNS is correct, run on the server, supplying a real certificate contact email and accepting the CA terms through Certbot:

```sh
sudo certbot certonly --webroot -w /var/www/letsencrypt -d gfdad.com -d www.gfdad.com
sudo cp /etc/nginx/sites-available/gfdad-https.prepared /etc/nginx/sites-available/gfdad
sudo nginx -t && sudo systemctl reload nginx
sudo install -d /etc/letsencrypt/renewal-hooks/deploy
printf '#!/bin/sh\nnginx -t && systemctl reload nginx\n' | sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx >/dev/null
sudo chmod 755 /etc/letsencrypt/renewal-hooks/deploy/reload-nginx
sudo certbot renew --dry-run
curl --fail https://gfdad.com/health
curl -I https://www.gfdad.com/
```

Canonical URL is `https://gfdad.com`; HTTP and HTTPS www redirect there after activation. TCP 443 is permitted but no TLS listener exists until certificates are issued. Do not load the prepared TLS file early. Adapt its content-serving locations to the actual application before activation.

## Reproduction and backups

`infra/lightsail/bootstrap.sh` captures the baseline for a new dedicated Ubuntu server. It must not be run on an unrelated workload. Upload it, `deploy-static.sh` and the deployment public key (as `/tmp/gfdad-deploy.pub`) to `/tmp/`, then run it with sudo. It updates packages, creates users/directories, configures SSH/UFW/Nginx/fail2ban, and installs the activation helper. Upload `gfdad-https.nginx` separately to the inactive path above. A completion marker prevents accidental reruns. Review the script before applying updates; package versions track Ubuntu security updates rather than a frozen machine image.

No server backups are enabled. Git tracks recipes and infrastructure configuration, but it does not back up secrets, private SSH keys, runtime files or future uploads. Manual and automatic Lightsail snapshots can restore an instance; neither substitutes for future independent database, media and secret backups. Do not put irreplaceable data on this server until its backup policy is chosen.

## Validation

Completed successfully:

- AWS console in Chrome confirmed running instance, static IP attachment, IPv4-only networking, exact 22/80/443 firewall rules and disabled automatic snapshots.
- Fresh SSH logins worked for both ubuntu and gfdad; gfdad had no sudo privilege.
- Nginx configuration passed `nginx -t`; security headers were present on public HTTP responses.
- Public `/health` returned HTTP 200 with `web-ready`.
- A temporary static artifact was activated as gfdad and served publicly; it survived a Nginx restart and full instance reboot.
- After reboot, nginx, fail2ban and unattended-upgrades were active, no systemd units were failed, and no reboot remained pending.
- Listening sockets exposed only SSH and HTTP; DNS listeners were loopback-only. Port 443 is permitted for future TLS but has no listener yet.
- SSH root/password login was disabled; UFW and fail2ban were active; secret-file permissions were verified as root:gfdad 0640.
- Web logs were readable by the administrator and logrotate configuration was checked.
- The temporary artifact was removed; the final root path returns 503 and `/health` remains 200.
- Shell scripts passed Bash syntax checks and the Git diff passed whitespace checks.

HTTPS and application-runtime checks are intentionally pending: DNS points elsewhere and no application exists. Chrome blocked direct plain-HTTP IP navigation, so public HTTP checks used terminal curl. No certificate or DNS changes were attempted.
