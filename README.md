# Paypal

[![Build Status](https://github.com/altenwald/paypal/actions/workflows/elixir.yml/badge.svg)](https://github.com/altenwald/paypal/actions/workflows/elixir.yml)
[![License: MIT](https://img.shields.io/github/license/altenwald/paypal.svg)](https://raw.githubusercontent.com/altenwald/paypal/main/COPYING)
[![Hex.pm](https://img.shields.io/hexpm/v/paypal.svg)](https://hex.pm/packages/paypal)
[![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/paypal)

PayPal API integration for Elixir using [Req](https://github.com/wojtekmach/req).

This library provides complete and typed support for the following PayPal APIs:

- **Orders API v2**: Create, authorize, and capture orders.
  - Official Docs: [PayPal Orders API v2](https://developer.paypal.com/docs/api/orders/v2/)
- **Payments API v2**: Show, capture, void authorizations, and refund captured payments.
  - Official Docs: [PayPal Payments API v2](https://developer.paypal.com/docs/api/payments/v2/)
- **Subscriptions API v1**: Manage recurring billing, subscriptions, plans, and catalog products.
  - Official Docs: [PayPal Subscriptions API v1](https://developer.paypal.com/docs/api/subscriptions/v1/)
  - Official Docs: [PayPal Catalog Products API v1](https://developer.paypal.com/docs/api/catalog-products/v1/)

## Installation

Add `paypal` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:paypal, "~> 0.2.0"}
  ]
end
```

## Configuration

Configure your PayPal credentials in `config/config.exs` or `config/runtime.exs`:

```elixir
config :paypal,
  url: System.get_env("PAYPAL_URL", "https://api-m.sandbox.paypal.com"),
  client_id: System.get_env("PAYPAL_CLIENT_ID"),
  secret: System.get_env("PAYPAL_SECRET")
```

## Usage

### Orders & Payments

Create an order to charge a user:

```elixir
# Create an order with :capture intent
{:ok, order} = Paypal.Order.create(
  :capture,
  [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
  %{"return_url" => "https://example.com/return", "cancel_url" => "https://example.com/cancel"}
)

# After the buyer approves via the returned approval link:
{:ok, captured_order} = Paypal.Order.capture(order.id)
```

Authorize funds and capture or void later:

```elixir
# Create an order with :authorize intent
{:ok, order} = Paypal.Order.create(
  :authorize,
  [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
  %{"return_url" => "https://example.com/return", "cancel_url" => "https://example.com/cancel"}
)

# Authorize
{:ok, authorized} = Paypal.Order.authorize(order.id)

# Capture authorized payment
auth_id = hd(hd(authorized.purchase_units).payments.authorizations).id
{:ok, captured} = Paypal.Payment.capture(auth_id)

# Or void authorization
:ok = Paypal.Payment.void(auth_id)

# Refund a captured payment
{:ok, refund} = Paypal.Payment.refund(captured.id)
```

### Subscriptions

The Subscriptions API covers products, billing plans, and subscription lifecycles:

#### 1. Create a Catalog Product

```elixir
{:ok, product} = Paypal.Subscription.Product.create(%{
  name: "Pro Streaming Membership",
  type: :service,
  description: "Monthly video streaming subscription",
  category: "SOFTWARE"
})
```

#### 2. Create a Billing Plan

```elixir
{:ok, plan} = Paypal.Subscription.Plan.create(%{
  product_id: product.id,
  name: "Monthly Pro Plan",
  description: "Standard monthly billing",
  status: :active,
  billing_cycles: [
    %{
      frequency: %{"interval_unit" => "MONTH", "interval_count" => 1},
      tenure_type: :regular,
      sequence: 1,
      total_cycles: 0,
      pricing_scheme: %{
        "fixed_price" => %{"currency_code" => "EUR", "value" => "15.00"}
      }
    }
  ],
  payment_preferences: %{
    auto_bill_outstanding: true,
    setup_fee_failure_action: :cancel,
    payment_failure_threshold: 3
  }
})
```

#### 3. Create and Manage Subscriptions

```elixir
# Create a subscription
{:ok, subscription} = Paypal.Subscription.create(%{
  plan_id: plan.id,
  subscriber: %{
    name: %{given_name: "Jane", surname: "Doe"},
    email_address: "jane.doe@example.com"
  },
  application_context: %{
    brand_name: "My App",
    locale: "en-US",
    return_url: "https://example.com/subscription/return",
    cancel_url: "https://example.com/subscription/cancel"
  }
})

# Show subscription details
{:ok, details} = Paypal.Subscription.show(subscription.id)

# Suspend subscription
:ok = Paypal.Subscription.suspend(subscription.id, "Customer requested pause")

# Reactivate subscription
:ok = Paypal.Subscription.activate(subscription.id, "Reactivating subscription")

# Cancel subscription
:ok = Paypal.Subscription.cancel(subscription.id, "Customer cancelled")

# List subscription transactions
{:ok, transactions} = Paypal.Subscription.transactions(
  subscription.id,
  "2026-01-01T00:00:00Z",
  "2026-12-31T23:59:59Z"
)
```

## License

Paypal is licensed under the [MIT License](COPYING).
