{ self, forAllSystems, ... }:
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.home-manager-option-search;
in
{
  options.home-manager-option-search =
    let
      inherit (lib) mkEnableOption mkOption types;
    in
    {
      enable = mkEnableOption "Enable the Home Manager option search module";
      domain = mkOption {
        type = types.str;
        description = ''The domain for which to build the package / of the virtualHost'';
      };
      enableNginx = mkEnableOption "Create an nginx virtualHost for the domain serving Home Manager option search";
      target-package = mkOption {
        type = types.nullOr types.package;
        description = "The package with the correct domain will be output here";
        default = null;
      };

      patched-package-src = mkOption {
        type = types.nullOr types.package;
        description = "The package source with the correct domain will be output here";
        default = null;
      };
    };

  config = lib.mkIf cfg.enable {
    home-manager-option-search = {
      patched-package-src = lib.mkDefault (
        pkgs.stdenv.mkDerivation {
          src = ./.;
          name = "home-manager-option-search";
          postPatch = ''
            substitute config.yaml config.yaml \
            --replace-warn "home-manager-options.extranix.com" "${cfg.domain}"
            substitute static/opensearch.xml static/opensearch.xml \
            --replace-warn "home-manager-options.extranix.com" "${cfg.domain}"
          '';
          "home-manager-options.extranix.com" = cfg.domain;
        }
      );
      target-package = lib.mkDefault (pkgs.runCommand "public" {} ''
        cd ${cfg.patched-package-src}
        ${pkgs.hugo}/bin/hugo --noBuildLock -d $out
       '');
    };

    services.nginx.virtualHosts = lib.mkIf cfg.enableNginx { ${cfg.domain}.root = cfg.target-package; };

  };
}
