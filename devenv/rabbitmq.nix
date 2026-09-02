# devenv/rabbitmq.nix
{
  config,
  ...
}:

let
  tw = config.twake;
in
{
  services.rabbitmq = {
    enable = true;
    listenAddress = "127.0.0.1";
    port = tw.rabbitmq.port;
  };
}
