defmodule Paypal do
  @moduledoc """
  Paypal is a payments platform that helps you accept payments and manage subscriptions
  in an easy way for your website or application.

  This library provides, using [Tesla](https://hex.pm/packages/tesla), an Elixir
  integration covering PayPal API v2 (Orders and Payments) and PayPal Subscriptions API v1
  (Catalog Products, Billing Plans, and Subscriptions).

  ## Main Modules

  - `Paypal.Auth` - OAuth2 token retrieval and automatic background refresh.
  - `Paypal.Order` - Create, show, capture, and authorize orders.
    [PayPal Orders API v2](https://developer.paypal.com/docs/api/orders/v2/)
  - `Paypal.Payment` - Capture authorized payments, void authorizations, and issue refunds.
    [PayPal Payments API v2](https://developer.paypal.com/docs/api/payments/v2/)
  - `Paypal.Subscription` - Create and manage subscriptions and recurring billing.
    [PayPal Subscriptions API v1](https://developer.paypal.com/docs/api/subscriptions/v1/)
  - `Paypal.Subscription.Plan` - Create and configure billing plans and cycles.
    [PayPal Billing Plans API v1](https://developer.paypal.com/docs/api/subscriptions/v1/#plans)
  - `Paypal.Subscription.Product` - Create and manage catalog products.
    [PayPal Catalog Products API v1](https://developer.paypal.com/docs/api/catalog-products/v1/)
  """
end
