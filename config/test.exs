import Config

config :paypal,
  auto_refresh: false,
  url: "https://api-m.sandbox.paypal.com",
  client_id: "1234567890",
  secret: "secret",
  req_options: [plug: {Req.Test, Paypal}]
