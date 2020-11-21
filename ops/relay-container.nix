{
pkgs ? import <nixpkgs> {}
, version ? "latest"
, name ? "walletconnect/relay"
, relaysrc ? ../dist/relay.tar.gz
}:
let
  relay = import ./relay.nix { inherit pkgs; src = relaysrc; };
  entrypoint = pkgs.writeScript "entrypoint.sh" ''
    #!${pkgs.stdenv.shell}
    set -e
    # Set default variables
    root_domain="''${DOMAIN_URL:-localhost}"
    manage_root_domain="''${MANAGE_ROOT_DOMAIN:-true}"
    email="''${EMAIL:-noreply@gmail.com}"
    app_env="''${APP_ENV:-development}"

    LETSENCRYPT=/etc/letsencrypt/live
    SERVERS=/etc/nginx/servers

    printf "USING ENVVARS: root_domain=$root_domain cert email=$email app_env=$app_env"

    function makeCert () {
      fullDomain=$1
      certDirectory=$2
      if [[ "$fullDomain" =~ .*localhost.* && ! -f "$certDirectory/privkey.pem" ]]
      then
        echo "Developing locally, generating self-signed certs"
        ${pkgs.openssl}/bin/openssl req -x509 -newkey rsa:4096 -keyout $certDirectory/privkey.pem -out $certDirectory/fullchain.pem -days 365 -nodes -subj '/CN=localhost'
      fi

      if [[ ! -f "$certDirectory/privkey.pem" ]]
      then
        echo "Couldnt find certs for $fullDomain, using certbot to initialize those now.."
        if [[ "$${CLOUDFLARE:-false}" == false ]]; then
          ${pkgs.python38Packages.certbot-dns-cloudflare} certonly --standalone -m $email --agree-tos --no-eff-email -d $fullDomain -n
        else
          echo "dns_cloudflare_api_token = $(cat /run/secrets/walletconnect_cloudflare)" > /run/secrets/cloudflare.ini
          ${pkgs.python38Packages.certbot-dns-cloudflare} certonly --dns-cloudflare --dns-cloudflare-credentials /run/secrets/cloudflare.ini -d $fullDomain -m $email --agree-tos --no-eff-email -n
        fi

        if [[ ! $? -eq 0 ]]
        then
          echo "ERROR"
          echo "Sleeping to not piss off certbot"
          ${pkgs.coreutils}/bin/sleep 9999 # FREEZE! Do not pester eff & get throttled
        fi
      fi
    }

    function configRootDomain () {
      domain=$1
      printf "\nConfiguring root domain: $domain\n"
      certDirectory=$LETSENCRYPT/$domain
      ${pkgs.coreutils}/bin/mkdir -vp $certDirectory
      makeCert $domain $certDirectory
    }

    # periodically fork off & see if our certs need to be renewed
    function renewcerts {
      domain=$1
      while true; do
        if [[ -d "$LETSENCRYPT" ]]
        then
          ${pkgs.python38Packages.certbot-dns-cloudflare}/bin/certbot renew --webroot -w /var/www/letsencrypt/ -n
        fi
        ${pkgs.coreutils}/bin/sleep 48h
      done
    }

    function main () {

      ${pkgs.coreutils}/bin/mkdir -vp $LETSENCRYPT
      ${pkgs.coreutils}/bin/mkdir -vp $SERVERS
      ${pkgs.coreutils}/bin/mkdir -vp /var/www/letsencrypt

      configRootDomain $root_domain

      if [[ "$fullDomain" != "localhost" ]]
      then
        echo "Forking renewcerts to the background for $fullDomain..."
        renewcerts $fullDomain &
      fi

      ${pkgs.coreutils}/bin/sleep 4 # give renewcerts a sec to do it's first check

      echo "Entrypoint finished, executing node..."; echo
      ${pkgs.nodejs-14_x}/bin/node ${relay}/dist
    }

    main
  '';
in
pkgs.dockerTools.buildLayeredImage {
  name = name;
  tag = version;
  contents = [ 
    pkgs.python38Packages.certbot-dns-cloudflare
    relay
  ];
  config = {
    Entrypoint = [ entrypoint ];
  };
}
