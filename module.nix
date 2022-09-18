{ pkgs, lib, coder, ... }:

with lib; {
  options.coder = {
    enable = mkEnableOption "coder service";
    accessUrl = mkOption {
      type = types.str;
    };

    agentStatsRefreshInterval = mkOption {
      type = types.str;
      default = null;
    };

    autoImportTemplate = mkOption {
      type = types.str;
      default = null;
    };

    autobuildPollInterval = mkOption {
      type = types.str;
      default = null;
    };

    cacheDir = mkOption {
      type = types.str;
      default = null;
    };

    oauth2GithubAllowSignups = mkOption {
      type = types.bool;
      default = null;
    };

    oauth2GithubAllowedOrgs = mkOption {
      type = with types; listOf (string);
      default = null;
    };

    oauth2GithubAllowedTeams = mkOption {
      type = with types; listOf (string);
      default = null;
    };

    oauth2GithubClientId = mkOption {
      type = types.str;
      default = null;
    };

    oauth2GithubClientSecret = mkOption {
      type = types.str;
      default = null;
    };

    oauth2GithubEnterpriseBaseUrl = mkOption {
      type = types.str;
      default = null;
    };

    oidcAllowSignups = mkOption {
      type = types.bool;
      default = null;
    };

    oidcClientId = mkOption {
      type = types.str;
      default = null;
    };

    oidcClientSecret = mkOption {
      type = types.str;
      default = null;
    };

    oidcEmailDomain = mkOption {
      type = types.str;
      default = null;
    };

    oidcIssuerUrl = mkOption {
      type = types.str;
      default = null;
    };

    oidcScopes = mkOption {
      type = types.str;
      default = null;
    };

    postgresUrl = mkOption {
      type = types.str;
      default = null;
    };

    pprofAddress = mkOption {
      type = types.str;
      default = null;
    };

    pprofEnable = mkEnableOption "pprof";

    prometheusAddress = mkOption {
      type = types.str;
      default = null;
    };
    prometheusEnable = mkEnableOption "prometheus";
    provisionerDaemons = mkOption {
      type = types.int;
      default = null;
    };

    secureAuthCookie = mkEnableOption "secure auth cookie";

    sshKeygenAlgorithm = mkOption {
      type = types.string;
      default = null;
    };

    stunServer = mkOption {
      type = with types; listOf (string);
      default = null;
    };

    telemetry = mkEnableOption "telemetry";

    tlsCertFile = mkOption {
      type = types.str;
      default = null;
    };

    tlsClientAuth = mkOption {
      type = types.str;
      default = null;
    };

    tlsEnable = mkEnableOption "tls";

    tlsKeyFile = mkOption {
      type = types.str;
      default = null;
    };

    tlsMinVersion = mkOption {
      type = types.str;
      default = null;
    };

    trace = mkEnableOption "application tracing";

    tunnel = mkOption {
      type = types.str;
      default = null;
    };

    turnRelayAddress = mkOption {
      type = types.str;
      default = null;
    };
  };
}
