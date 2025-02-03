defmodule Paypal.IntegrationTest do
  use Paypal.Case
  alias Paypal.Auth.Worker, as: AuthWorker

  defp wait_for(name) do
    unless Process.whereis(name) do
      Process.sleep(50)
      wait_for(name)
    end
  end

  setup do
    if Process.whereis(Paypal.Auth.Worker) do
      GenServer.stop(Paypal.Auth.Worker)
      wait_for(Paypal.Auth.Worker)
    end

    :ok
  end

  test "order authorized and captured", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/oauth2/token", fn %Plug.Conn{} = conn ->
      response(conn, 200, %{
        "access_token" => "ACCESSTOKEN",
        "app_id" => "APP-ID",
        "expires_in" => 32_400,
        "nonce" => "2024-05-08T22:22:22NONCE",
        "scope" =>
          "https://uri.paypal.com/services/payments/futurepayments https://uri.paypal.com/services/invoicing https://uri.paypal.com/services/vault/payment-tokens/read https://uri.paypal.com/services/disputes/read-buyer https://uri.paypal.com/services/payments/realtimepayment https://uri.paypal.com/services/disputes/update-seller https://uri.paypal.com/services/payments/payment/authcapture openid https://uri.paypal.com/services/disputes/read-seller Braintree:Vault https://uri.paypal.com/services/payments/refund https://api.paypal.com/v1/vault/credit-card https://api.paypal.com/v1/payments/.* https://uri.paypal.com/payments/payouts https://uri.paypal.com/services/vault/payment-tokens/readwrite https://api.paypal.com/v1/vault/credit-card/.* https://uri.paypal.com/services/subscriptions https://uri.paypal.com/services/applications/webhooks",
        "token_type" => "Bearer"
      })
    end)

    assert {:error, :notfound} == Paypal.Auth.get_token()

    AuthWorker.refresh()
    assert "ACCESSTOKEN" == Paypal.Auth.get_token!()

    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders", fn conn ->
      response(conn, 200, %{
        "id" => "5UY53123AX394662R",
        "links" => [
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" => "https://www.sandbox.paypal.com/checkoutnow?token=5UY53123AX394662R",
            "method" => "GET",
            "rel" => "payer-action"
          }
        ],
        "payment_source" => %{"paypal" => %{}},
        "status" => "PAYER_ACTION_REQUIRED"
      })
    end)

    order = %Paypal.Order.Info{
      id: "5UY53123AX394662R",
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href: "https://www.sandbox.paypal.com/checkoutnow?token=5UY53123AX394662R",
          rel: "payer-action",
          method: :get
        }
      ],
      payment_source: %{"paypal" => %{}},
      status: :payer_action_required
    }

    assert {:ok, order} ==
             Paypal.Order.create(
               :authorize,
               [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
               %{"return_url" => "https://return.com", "cancel_url" => "https://cancel.com"}
             )

    Bypass.expect_once(bypass, "GET", "/v2/checkout/orders/5UY53123AX394662R", fn conn ->
      response(conn, 200, %{
        "create_time" => "2024-05-08T16:25:33Z",
        "id" => "5UY53123AX394662R",
        "intent" => "AUTHORIZE",
        "links" => [
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "PATCH",
            "rel" => "update"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R/authorize",
            "method" => "POST",
            "rel" => "authorize"
          }
        ],
        "payer" => %{
          "address" => %{"country_code" => "ES"},
          "email_address" => "buyer@rich.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"},
          "payer_id" => "JWEUL3HMBVGJ6"
        },
        "payment_source" => %{
          "paypal" => %{
            "account_id" => "JWEUL3HMBVGJ6",
            "account_status" => "VERIFIED",
            "address" => %{"country_code" => "ES"},
            "email_address" => "buyer@rich.com",
            "name" => %{"given_name" => "test", "surname" => "buyer"}
          }
        },
        "purchase_units" => [
          %{
            "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
            "payee" => %{
              "email_address" => "sb-7qbag8421184@business.example.com",
              "merchant_id" => "DCPJFLZESR8U8"
            },
            "reference_id" => "default"
          }
        ],
        "status" => "APPROVED"
      })
    end)

    info = %Paypal.Order.Info{
      id: "5UY53123AX394662R",
      create_time: ~U[2024-05-08 16:25:33Z],
      intent: :authorize,
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "update",
          method: :patch
        },
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R/authorize",
          rel: "authorize",
          method: :post
        }
      ],
      payer: %Paypal.Order.Payer{
        payer_id: "JWEUL3HMBVGJ6",
        name: %{"given_name" => "test", "surname" => "buyer"},
        email_address: "buyer@rich.com",
        address: %{"country_code" => "ES"}
      },
      payment_source: %{
        "paypal" => %{
          "account_id" => "JWEUL3HMBVGJ6",
          "account_status" => "VERIFIED",
          "address" => %{"country_code" => "ES"},
          "email_address" => "buyer@rich.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"}
        }
      },
      purchase_units: [
        %Paypal.Order.PurchaseUnit{
          reference_id: "default",
          amount: %Paypal.Common.CurrencyValue{
            currency_code: "EUR",
            value: Decimal.new("10.00")
          },
          payee: %{
            "email_address" => "sb-7qbag8421184@business.example.com",
            "merchant_id" => "DCPJFLZESR8U8"
          }
        }
      ],
      status: :approved
    }

    assert {:ok, info} == Paypal.Order.show(order.id)

    Bypass.expect_once(
      bypass,
      "POST",
      "/v2/checkout/orders/5UY53123AX394662R/authorize",
      fn conn ->
        response(conn, 201, %{
          "id" => "5UY53123AX394662R",
          "links" => [
            %{
              "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
              "method" => "GET",
              "rel" => "self"
            }
          ],
          "payer" => %{
            "address" => %{"country_code" => "ES"},
            "email_address" => "buyer@rich.com",
            "name" => %{"given_name" => "test", "surname" => "buyer"},
            "payer_id" => "JWEUL3HMBVGJ6"
          },
          "payment_source" => %{
            "paypal" => %{
              "account_id" => "JWEUL3HMBVGJ6",
              "account_status" => "VERIFIED",
              "address" => %{"country_code" => "ES"},
              "email_address" => "buyer@rich.com",
              "name" => %{"given_name" => "test", "surname" => "buyer"}
            }
          },
          "purchase_units" => [
            %{
              "payments" => %{
                "authorizations" => [
                  %{
                    "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
                    "create_time" => "2024-05-08T22:22:22Z",
                    "expiration_time" => "2024-06-06T22:22:22Z",
                    "id" => "27A385875N551040L",
                    "links" => [
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
                        "method" => "GET",
                        "rel" => "self"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
                        "method" => "POST",
                        "rel" => "capture"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
                        "method" => "POST",
                        "rel" => "void"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
                        "method" => "POST",
                        "rel" => "reauthorize"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
                        "method" => "GET",
                        "rel" => "up"
                      }
                    ],
                    "seller_protection" => %{
                      "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"],
                      "status" => "ELIGIBLE"
                    },
                    "status" => "CREATED",
                    "update_time" => "2024-05-08T22:22:22Z"
                  }
                ]
              },
              "reference_id" => "default"
            }
          ],
          "status" => "COMPLETED"
        })
      end
    )

    authorized = %Paypal.Order.Authorized{
      id: "5UY53123AX394662R",
      status: :completed,
      payment_source: %{
        "paypal" => %{
          "account_id" => "JWEUL3HMBVGJ6",
          "account_status" => "VERIFIED",
          "address" => %{"country_code" => "ES"},
          "email_address" => "buyer@rich.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"}
        }
      },
      purchase_units: [
        %Paypal.Order.Authorized.PurchaseUnit{
          reference_id: "default",
          payments: %Paypal.Order.Authorized.PurchaseUnit.Payment{
            authorizations: [
              %Paypal.Order.Authorization{
                id: "27A385875N551040L",
                status: :created,
                amount: %Paypal.Common.CurrencyValue{
                  currency_code: "EUR",
                  value: Decimal.new("10.00")
                },
                seller_protection: %Paypal.Order.Authorization.SellerProtection{
                  status: :eligible,
                  dispute_categories: ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"]
                },
                expiration_time: ~U[2024-06-06 22:22:22Z],
                create_time: ~U[2024-05-08 22:22:22Z],
                update_time: ~U[2024-05-08 22:22:22Z],
                links: [
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
                    rel: "self",
                    method: :get
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
                    rel: "capture",
                    method: :post
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
                    rel: "void",
                    method: :post
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
                    rel: "reauthorize",
                    method: :post
                  },
                  %Paypal.Common.Link{
                    href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
                    rel: "up",
                    method: :get
                  }
                ]
              }
            ]
          }
        }
      ],
      payer: %{
        "address" => %{"country_code" => "ES"},
        "email_address" => "buyer@rich.com",
        "name" => %{"given_name" => "test", "surname" => "buyer"},
        "payer_id" => "JWEUL3HMBVGJ6"
      },
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        }
      ]
    }

    assert {:ok, authorized} == Paypal.Order.authorize(order.id)

    Bypass.expect_once(bypass, "GET", "/v2/payments/authorizations/27A385875N551040L", fn conn ->
      response(conn, 200, %{
        "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
        "create_time" => "2024-05-08T22:22:22Z",
        "expiration_time" => "2024-06-06T22:22:22Z",
        "id" => "27A385875N551040L",
        "links" => [
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
            "method" => "POST",
            "rel" => "capture"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
            "method" => "POST",
            "rel" => "void"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
            "method" => "POST",
            "rel" => "reauthorize"
          },
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "up"
          }
        ],
        "payee" => %{
          "email_address" => "sb-7qbag8421184@business.example.com",
          "merchant_id" => "DCPJFLZESR8U8"
        },
        "seller_protection" => %{
          "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"],
          "status" => "ELIGIBLE"
        },
        "status" => "CREATED",
        "supplementary_data" => %{"related_ids" => %{"order_id" => "5UY53123AX394662R"}},
        "update_time" => "2024-05-08T22:22:22Z"
      })
    end)

    payment_info = %Paypal.Payment.Info{
      id: "27A385875N551040L",
      create_time: ~U[2024-05-08 22:22:22Z],
      expiration_time: ~U[2024-06-06 22:22:22Z],
      amount: %Paypal.Common.CurrencyValue{
        currency_code: "EUR",
        value: Decimal.new("10.00")
      },
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href:
            "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
          rel: "capture",
          method: :post
        },
        %Paypal.Common.Link{
          href:
            "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
          rel: "void",
          method: :post
        },
        %Paypal.Common.Link{
          href:
            "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
          rel: "reauthorize",
          method: :post
        },
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "up",
          method: :get
        }
      ],
      payee: %{
        "email_address" => "sb-7qbag8421184@business.example.com",
        "merchant_id" => "DCPJFLZESR8U8"
      },
      status: :created
    }

    assert {:ok, payment_info} == Paypal.Payment.show("27A385875N551040L")

    Bypass.expect_once(
      bypass,
      "POST",
      "/v2/payments/authorizations/27A385875N551040L/capture",
      fn conn ->
        response(conn, 201, %{
          "id" => "5MS70068BM212023M",
          "links" => [
            %{
              "href" => "https://api.sandbox.paypal.com/v2/payments/captures/5MS70068BM212023M",
              "method" => "GET",
              "rel" => "self"
            },
            %{
              "href" =>
                "https://api.sandbox.paypal.com/v2/payments/captures/5MS70068BM212023M/refund",
              "method" => "POST",
              "rel" => "refund"
            },
            %{
              "href" =>
                "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
              "method" => "GET",
              "rel" => "up"
            }
          ],
          "status" => "COMPLETED"
        })
      end
    )

    payment_captured = %Paypal.Payment.Captured{
      id: "5MS70068BM212023M",
      invoice_id: nil,
      custom_id: nil,
      final_capture: false,
      links: [
        %Paypal.Common.Link{
          enc_type: nil,
          href: "https://api.sandbox.paypal.com/v2/payments/captures/5MS70068BM212023M",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          enc_type: nil,
          href: "https://api.sandbox.paypal.com/v2/payments/captures/5MS70068BM212023M/refund",
          rel: "refund",
          method: :post
        },
        %Paypal.Common.Link{
          enc_type: nil,
          href: "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
          rel: "up",
          method: :get
        }
      ],
      status: :completed,
      status_details: nil,
      disbursement_mode: :instant,
      amount: nil,
      create_time: nil,
      update_time: nil
    }

    assert {:ok, payment_captured} == Paypal.Payment.capture("27A385875N551040L")

    Bypass.expect_once(
      bypass,
      "POST",
      "/v2/payments/captures/5MS70068BM212023M/refund",
      fn conn ->
        response(conn, 201, %{
          "id" => "58K15806CS993444T",
          "amount" => %{
            "currency_code" => "USD",
            "value" => "89.00"
          },
          "seller_payable_breakdown" => %{
            "gross_amount" => %{
              "currency_code" => "USD",
              "value" => "89.00"
            },
            "paypal_fee" => %{
              "currency_code" => "USD",
              "value" => "0.00"
            },
            "net_amount" => %{
              "currency_code" => "USD",
              "value" => "89.00"
            },
            "total_refunded_amount" => %{
              "currency_code" => "USD",
              "value" => "100.00"
            }
          },
          "invoice_id" => "OrderInvoice-10_10_2024_12_58_20_pm",
          "status" => "COMPLETED",
          "create_time" => "2024-10-14T15:03:29-07:00",
          "update_time" => "2024-10-14T15:03:29-07:00",
          "links" => [
            %{
              "href" =>
                "https://api.msmaster.qa.paypal.com/v2/payments/refunds/58K15806CS993444T",
              "rel" => "self",
              "method" => "GET"
            },
            %{
              "href" =>
                "https://api.msmaster.qa.paypal.com/v2/payments/captures/7TK53561YB803214S",
              "rel" => "up",
              "method" => "GET"
            }
          ]
        })
      end
    )

    payment_refund = %Paypal.Payment.Refund{
      id: "58K15806CS993444T",
      invoice_id: "OrderInvoice-10_10_2024_12_58_20_pm",
      custom_id: nil,
      links: [
        %Paypal.Common.Link{
          enc_type: nil,
          href: "https://api.msmaster.qa.paypal.com/v2/payments/refunds/58K15806CS993444T",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          enc_type: nil,
          href: "https://api.msmaster.qa.paypal.com/v2/payments/captures/7TK53561YB803214S",
          rel: "up",
          method: :get
        }
      ],
      status: :completed,
      status_details: nil,
      seller_payable_breakdown: %{
        "gross_amount" => %{
          "currency_code" => "USD",
          "value" => "89.00"
        },
        "paypal_fee" => %{
          "currency_code" => "USD",
          "value" => "0.00"
        },
        "net_amount" => %{
          "currency_code" => "USD",
          "value" => "89.00"
        },
        "total_refunded_amount" => %{
          "currency_code" => "USD",
          "value" => "100.00"
        }
      },
      amount: %Paypal.Common.CurrencyValue{
        currency_code: "USD",
        value: Decimal.new("89.00")
      },
      create_time: "2024-10-14T15:03:29-07:00",
      update_time: "2024-10-14T15:03:29-07:00"
    }

    assert {:ok, payment_refund} == Paypal.Payment.refund("5MS70068BM212023M")
  end

  test "order authorized and voided", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/oauth2/token", fn %Plug.Conn{} = conn ->
      response(conn, 200, %{
        "access_token" => "ACCESSTOKEN",
        "app_id" => "APP-ID",
        "expires_in" => 32_400,
        "nonce" => "2024-05-08T22:22:22NONCE",
        "scope" =>
          "https://uri.paypal.com/services/payments/futurepayments https://uri.paypal.com/services/invoicing https://uri.paypal.com/services/vault/payment-tokens/read https://uri.paypal.com/services/disputes/read-buyer https://uri.paypal.com/services/payments/realtimepayment https://uri.paypal.com/services/disputes/update-seller https://uri.paypal.com/services/payments/payment/authcapture openid https://uri.paypal.com/services/disputes/read-seller Braintree:Vault https://uri.paypal.com/services/payments/refund https://api.paypal.com/v1/vault/credit-card https://api.paypal.com/v1/payments/.* https://uri.paypal.com/payments/payouts https://uri.paypal.com/services/vault/payment-tokens/readwrite https://api.paypal.com/v1/vault/credit-card/.* https://uri.paypal.com/services/subscriptions https://uri.paypal.com/services/applications/webhooks",
        "token_type" => "Bearer"
      })
    end)

    assert {:error, :notfound} == Paypal.Auth.get_token()

    AuthWorker.refresh()
    assert "ACCESSTOKEN" == Paypal.Auth.get_token!()

    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders", fn conn ->
      response(conn, 200, %{
        "id" => "5UY53123AX394662R",
        "links" => [
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" => "https://www.sandbox.paypal.com/checkoutnow?token=5UY53123AX394662R",
            "method" => "GET",
            "rel" => "payer-action"
          }
        ],
        "payment_source" => %{"paypal" => %{}},
        "status" => "PAYER_ACTION_REQUIRED"
      })
    end)

    order = %Paypal.Order.Info{
      id: "5UY53123AX394662R",
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href: "https://www.sandbox.paypal.com/checkoutnow?token=5UY53123AX394662R",
          rel: "payer-action",
          method: :get
        }
      ],
      payment_source: %{"paypal" => %{}},
      status: :payer_action_required
    }

    assert {:ok, order} ==
             Paypal.Order.create(
               :authorize,
               [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
               %{"return_url" => "https://return.com", "cancel_url" => "https://cancel.com"}
             )

    Bypass.expect_once(bypass, "GET", "/v2/checkout/orders/5UY53123AX394662R", fn conn ->
      response(conn, 200, %{
        "create_time" => "2024-05-08T16:25:33Z",
        "id" => "5UY53123AX394662R",
        "intent" => "AUTHORIZE",
        "links" => [
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "PATCH",
            "rel" => "update"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R/authorize",
            "method" => "POST",
            "rel" => "authorize"
          }
        ],
        "payer" => %{
          "address" => %{"country_code" => "ES"},
          "email_address" => "buyer@rich.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"},
          "payer_id" => "JWEUL3HMBVGJ6"
        },
        "payment_source" => %{
          "paypal" => %{
            "account_id" => "JWEUL3HMBVGJ6",
            "account_status" => "VERIFIED",
            "address" => %{"country_code" => "ES"},
            "email_address" => "buyer@rich.com",
            "name" => %{"given_name" => "test", "surname" => "buyer"}
          }
        },
        "purchase_units" => [
          %{
            "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
            "payee" => %{
              "email_address" => "sb-7qbag8421184@business.example.com",
              "merchant_id" => "DCPJFLZESR8U8"
            },
            "reference_id" => "default"
          }
        ],
        "status" => "APPROVED"
      })
    end)

    info = %Paypal.Order.Info{
      id: "5UY53123AX394662R",
      create_time: ~U[2024-05-08 16:25:33Z],
      intent: :authorize,
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "update",
          method: :patch
        },
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R/authorize",
          rel: "authorize",
          method: :post
        }
      ],
      payer: %Paypal.Order.Payer{
        payer_id: "JWEUL3HMBVGJ6",
        name: %{"given_name" => "test", "surname" => "buyer"},
        email_address: "buyer@rich.com",
        address: %{"country_code" => "ES"}
      },
      payment_source: %{
        "paypal" => %{
          "account_id" => "JWEUL3HMBVGJ6",
          "account_status" => "VERIFIED",
          "address" => %{"country_code" => "ES"},
          "email_address" => "buyer@rich.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"}
        }
      },
      purchase_units: [
        %Paypal.Order.PurchaseUnit{
          reference_id: "default",
          amount: %Paypal.Common.CurrencyValue{
            currency_code: "EUR",
            value: Decimal.new("10.00")
          },
          payee: %{
            "email_address" => "sb-7qbag8421184@business.example.com",
            "merchant_id" => "DCPJFLZESR8U8"
          }
        }
      ],
      status: :approved
    }

    assert {:ok, info} == Paypal.Order.show(order.id)

    Bypass.expect_once(
      bypass,
      "POST",
      "/v2/checkout/orders/5UY53123AX394662R/authorize",
      fn conn ->
        response(conn, 201, %{
          "id" => "5UY53123AX394662R",
          "links" => [
            %{
              "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
              "method" => "GET",
              "rel" => "self"
            }
          ],
          "payer" => %{
            "address" => %{"country_code" => "ES"},
            "email_address" => "buyer@rich.com",
            "name" => %{"given_name" => "test", "surname" => "buyer"},
            "payer_id" => "JWEUL3HMBVGJ6"
          },
          "payment_source" => %{
            "paypal" => %{
              "account_id" => "JWEUL3HMBVGJ6",
              "account_status" => "VERIFIED",
              "address" => %{"country_code" => "ES"},
              "email_address" => "buyer@rich.com",
              "name" => %{"given_name" => "test", "surname" => "buyer"}
            }
          },
          "purchase_units" => [
            %{
              "payments" => %{
                "authorizations" => [
                  %{
                    "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
                    "create_time" => "2024-05-08T22:22:22Z",
                    "expiration_time" => "2024-06-06T22:22:22Z",
                    "id" => "27A385875N551040L",
                    "links" => [
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
                        "method" => "GET",
                        "rel" => "self"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
                        "method" => "POST",
                        "rel" => "capture"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
                        "method" => "POST",
                        "rel" => "void"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
                        "method" => "POST",
                        "rel" => "reauthorize"
                      },
                      %{
                        "href" =>
                          "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
                        "method" => "GET",
                        "rel" => "up"
                      }
                    ],
                    "seller_protection" => %{
                      "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"],
                      "status" => "ELIGIBLE"
                    },
                    "status" => "CREATED",
                    "update_time" => "2024-05-08T22:22:22Z"
                  }
                ]
              },
              "reference_id" => "default"
            }
          ],
          "status" => "COMPLETED"
        })
      end
    )

    authorized = %Paypal.Order.Authorized{
      id: "5UY53123AX394662R",
      status: :completed,
      payment_source: %{
        "paypal" => %{
          "account_id" => "JWEUL3HMBVGJ6",
          "account_status" => "VERIFIED",
          "address" => %{"country_code" => "ES"},
          "email_address" => "buyer@rich.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"}
        }
      },
      purchase_units: [
        %Paypal.Order.Authorized.PurchaseUnit{
          reference_id: "default",
          payments: %Paypal.Order.Authorized.PurchaseUnit.Payment{
            authorizations: [
              %Paypal.Order.Authorization{
                id: "27A385875N551040L",
                status: :created,
                amount: %Paypal.Common.CurrencyValue{
                  currency_code: "EUR",
                  value: Decimal.new("10.00")
                },
                seller_protection: %Paypal.Order.Authorization.SellerProtection{
                  status: :eligible,
                  dispute_categories: ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"]
                },
                expiration_time: ~U[2024-06-06 22:22:22Z],
                create_time: ~U[2024-05-08 22:22:22Z],
                update_time: ~U[2024-05-08 22:22:22Z],
                links: [
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
                    rel: "self",
                    method: :get
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
                    rel: "capture",
                    method: :post
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
                    rel: "void",
                    method: :post
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
                    rel: "reauthorize",
                    method: :post
                  },
                  %Paypal.Common.Link{
                    href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
                    rel: "up",
                    method: :get
                  }
                ]
              }
            ]
          }
        }
      ],
      payer: %{
        "address" => %{"country_code" => "ES"},
        "email_address" => "buyer@rich.com",
        "name" => %{"given_name" => "test", "surname" => "buyer"},
        "payer_id" => "JWEUL3HMBVGJ6"
      },
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        }
      ]
    }

    assert {:ok, authorized} == Paypal.Order.authorize(order.id)

    Bypass.expect_once(bypass, "GET", "/v2/payments/authorizations/27A385875N551040L", fn conn ->
      response(conn, 200, %{
        "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
        "create_time" => "2024-05-08T22:22:22Z",
        "expiration_time" => "2024-06-06T22:22:22Z",
        "id" => "27A385875N551040L",
        "links" => [
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
            "method" => "POST",
            "rel" => "capture"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
            "method" => "POST",
            "rel" => "void"
          },
          %{
            "href" =>
              "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
            "method" => "POST",
            "rel" => "reauthorize"
          },
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "up"
          }
        ],
        "payee" => %{
          "email_address" => "sb-7qbag8421184@business.example.com",
          "merchant_id" => "DCPJFLZESR8U8"
        },
        "seller_protection" => %{
          "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"],
          "status" => "ELIGIBLE"
        },
        "status" => "CREATED",
        "supplementary_data" => %{"related_ids" => %{"order_id" => "5UY53123AX394662R"}},
        "update_time" => "2024-05-08T22:22:22Z"
      })
    end)

    payment_info = %Paypal.Payment.Info{
      id: "27A385875N551040L",
      create_time: ~U[2024-05-08 22:22:22Z],
      expiration_time: ~U[2024-06-06 22:22:22Z],
      amount: %Paypal.Common.CurrencyValue{
        currency_code: "EUR",
        value: Decimal.new("10.00")
      },
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href:
            "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/capture",
          rel: "capture",
          method: :post
        },
        %Paypal.Common.Link{
          href:
            "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/void",
          rel: "void",
          method: :post
        },
        %Paypal.Common.Link{
          href:
            "https://api.sandbox.paypal.com/v2/payments/authorizations/27A385875N551040L/reauthorize",
          rel: "reauthorize",
          method: :post
        },
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "up",
          method: :get
        }
      ],
      payee: %{
        "email_address" => "sb-7qbag8421184@business.example.com",
        "merchant_id" => "DCPJFLZESR8U8"
      },
      status: :created
    }

    assert {:ok, payment_info} == Paypal.Payment.show("27A385875N551040L")

    Bypass.expect_once(
      bypass,
      "POST",
      "/v2/payments/authorizations/27A385875N551040L/void",
      &response(&1, 204, nil)
    )

    assert :ok == Paypal.Payment.void("27A385875N551040L")
  end

  test "order captured", %{bypass: bypass} do
    Bypass.expect_once(bypass, "POST", "/v1/oauth2/token", fn %Plug.Conn{} = conn ->
      response(conn, 200, %{
        "access_token" => "ACCESSTOKEN",
        "app_id" => "APP-ID",
        "expires_in" => 32_400,
        "nonce" => "2024-05-08T22:22:22NONCE",
        "scope" =>
          "https://uri.paypal.com/services/payments/futurepayments https://uri.paypal.com/services/invoicing https://uri.paypal.com/services/vault/payment-tokens/read https://uri.paypal.com/services/disputes/read-buyer https://uri.paypal.com/services/payments/realtimepayment https://uri.paypal.com/services/disputes/update-seller https://uri.paypal.com/services/payments/payment/authcapture openid https://uri.paypal.com/services/disputes/read-seller Braintree:Vault https://uri.paypal.com/services/payments/refund https://api.paypal.com/v1/vault/credit-card https://api.paypal.com/v1/payments/.* https://uri.paypal.com/payments/payouts https://uri.paypal.com/services/vault/payment-tokens/readwrite https://api.paypal.com/v1/vault/credit-card/.* https://uri.paypal.com/services/subscriptions https://uri.paypal.com/services/applications/webhooks",
        "token_type" => "Bearer"
      })
    end)

    assert {:error, :notfound} == Paypal.Auth.get_token()

    AuthWorker.refresh()
    assert "ACCESSTOKEN" == Paypal.Auth.get_token!()

    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders", fn conn ->
      response(conn, 200, %{
        "id" => "5UY53123AX394662R",
        "links" => [
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
            "method" => "GET",
            "rel" => "self"
          },
          %{
            "href" => "https://www.sandbox.paypal.com/checkoutnow?token=5UY53123AX394662R",
            "method" => "GET",
            "rel" => "payer-action"
          }
        ],
        "payment_source" => %{"paypal" => %{}},
        "status" => "PAYER_ACTION_REQUIRED"
      })
    end)

    order = %Paypal.Order.Info{
      id: "5UY53123AX394662R",
      links: [
        %Paypal.Common.Link{
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/5UY53123AX394662R",
          rel: "self",
          method: :get
        },
        %Paypal.Common.Link{
          href: "https://www.sandbox.paypal.com/checkoutnow?token=5UY53123AX394662R",
          rel: "payer-action",
          method: :get
        }
      ],
      payment_source: %{"paypal" => %{}},
      status: :payer_action_required
    }

    assert {:ok, order} ==
             Paypal.Order.create(
               :capture,
               [%{"amount" => %{"currency_code" => "EUR", "value" => "10.00"}}],
               %{"return_url" => "https://return.com", "cancel_url" => "https://cancel.com"}
             )

    Bypass.expect_once(bypass, "POST", "/v2/checkout/orders/#{order.id}/capture", fn conn ->
      response(conn, 201, %{
        "id" => "7D653782TH669712A",
        "links" => [
          %{
            "href" => "https://api.sandbox.paypal.com/v2/checkout/orders/7D653782TH669712A",
            "method" => "GET",
            "rel" => "self"
          }
        ],
        "payer" => %{
          "address" => %{"country_code" => "ES"},
          "email_address" => "payment-buyer@altenwald.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"},
          "payer_id" => "JWEUL3HMBVGJ6"
        },
        "payment_source" => %{
          "paypal" => %{
            "account_id" => "JWEUL3HMBVGJ6",
            "account_status" => "VERIFIED",
            "address" => %{"country_code" => "ES"},
            "email_address" => "payment-buyer@altenwald.com",
            "name" => %{"given_name" => "test", "surname" => "buyer"}
          }
        },
        "purchase_units" => [
          %{
            "payments" => %{
              "captures" => [
                %{
                  "amount" => %{"currency_code" => "EUR", "value" => "10.00"},
                  "create_time" => "2024-05-10T12:19:16Z",
                  "final_capture" => true,
                  "id" => "58A90337V3530010E",
                  "links" => [
                    %{
                      "href" =>
                        "https://api.sandbox.paypal.com/v2/payments/captures/58A90337V3530010E",
                      "method" => "GET",
                      "rel" => "self"
                    },
                    %{
                      "href" =>
                        "https://api.sandbox.paypal.com/v2/payments/captures/58A90337V3530010E/refund",
                      "method" => "POST",
                      "rel" => "refund"
                    },
                    %{
                      "href" =>
                        "https://api.sandbox.paypal.com/v2/checkout/orders/7D653782TH669712A",
                      "method" => "GET",
                      "rel" => "up"
                    }
                  ],
                  "seller_protection" => %{
                    "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"],
                    "status" => "ELIGIBLE"
                  },
                  "seller_receivable_breakdown" => %{
                    "gross_amount" => %{"currency_code" => "EUR", "value" => "10.00"},
                    "net_amount" => %{"currency_code" => "EUR", "value" => "9.31"},
                    "paypal_fee" => %{"currency_code" => "EUR", "value" => "0.69"}
                  },
                  "status" => "COMPLETED",
                  "update_time" => "2024-05-10T12:19:16Z"
                }
              ]
            },
            "reference_id" => "default"
          }
        ],
        "status" => "COMPLETED"
      })
    end)

    info = %Paypal.Order.Info{
      id: "7D653782TH669712A",
      links: [
        %Paypal.Common.Link{
          enc_type: nil,
          href: "https://api.sandbox.paypal.com/v2/checkout/orders/7D653782TH669712A",
          rel: "self",
          method: :get
        }
      ],
      payer: %Paypal.Order.Payer{
        payer_id: "JWEUL3HMBVGJ6",
        name: %{"given_name" => "test", "surname" => "buyer"},
        email_address: "payment-buyer@altenwald.com",
        address: %{"country_code" => "ES"}
      },
      payment_source: %{
        "paypal" => %{
          "account_id" => "JWEUL3HMBVGJ6",
          "account_status" => "VERIFIED",
          "address" => %{"country_code" => "ES"},
          "email_address" => "payment-buyer@altenwald.com",
          "name" => %{"given_name" => "test", "surname" => "buyer"}
        }
      },
      purchase_units: [
        %Paypal.Order.PurchaseUnit{
          payments: %Paypal.Order.PurchaseUnit.PaymentCollection{
            captures: [
              %Paypal.Order.PurchaseUnit.Capture{
                amount: %Paypal.Common.CurrencyValue{
                  currency_code: "EUR",
                  value: Decimal.new("10.00")
                },
                create_time: "2024-05-10T12:19:16Z",
                final_capture: true,
                id: "58A90337V3530010E",
                links: [
                  %Paypal.Common.Link{
                    href: "https://api.sandbox.paypal.com/v2/payments/captures/58A90337V3530010E",
                    method: :get,
                    rel: "self"
                  },
                  %Paypal.Common.Link{
                    href:
                      "https://api.sandbox.paypal.com/v2/payments/captures/58A90337V3530010E/refund",
                    method: :post,
                    rel: "refund"
                  },
                  %Paypal.Common.Link{
                    href: "https://api.sandbox.paypal.com/v2/checkout/orders/7D653782TH669712A",
                    method: :get,
                    rel: "up"
                  }
                ],
                seller_protection: %{
                  "dispute_categories" => ["ITEM_NOT_RECEIVED", "UNAUTHORIZED_TRANSACTION"],
                  "status" => "ELIGIBLE"
                },
                seller_receivable_breakdown: %{
                  "gross_amount" => %{"currency_code" => "EUR", "value" => "10.00"},
                  "net_amount" => %{"currency_code" => "EUR", "value" => "9.31"},
                  "paypal_fee" => %{"currency_code" => "EUR", "value" => "0.69"}
                },
                status: "COMPLETED",
                update_time: "2024-05-10T12:19:16Z"
              }
            ]
          }
        }
      ],
      status: :completed
    }

    assert {:ok, ^info} = Paypal.Order.capture(order.id)
  end
end
