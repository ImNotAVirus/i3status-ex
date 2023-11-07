import Config

config :logger,
  backends: [{LoggerFileBackend, :error_log}],
  format: "[$level] $message\n"

config :logger, :error_log,
  path: "/tmp/i3status-ex.log",
  level: :debug
