import Config

config :paypal,
  url: System.get_env("PAYPAL_URL"),
  client_id: System.get_env("PAYPAL_CLIENT_ID"),
  secret: System.get_env("PAYPAL_SECRET")
