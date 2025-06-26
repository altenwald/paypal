defmodule Paypal do
  @moduledoc """
  Paypal is a micro-payments platform that helps you to get payments in an easy
  way for your website. You only need to open an account, retrieve the API key
  information and you can start.

  The aim for this project is to provide, using [Tesla](https://hex.pm/packages/tesla),
  a complete Paypal API v2 implementation easily and completely covered by
  different data structures that makes the integration easy.

  The most important starting points are:

  - `Paypal.Auth`. We are retrieving an OAuth2 token to perform the calls.
  - `Paypal.Order`. Create orders to be paid by your users.
  - `Paypal.Payment`. Get more control of the payments and refunds.
  """
end
