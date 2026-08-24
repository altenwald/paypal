defmodule Paypal.MixProject do
  use Mix.Project

  @version "0.2.0"
  @source_url "https://github.com/altenwald/paypal"

  def project do
    [
      app: :paypal,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(),
      name: "Paypal",
      description: "Paypal API v2 & Subscriptions API with Req",
      docs: docs(),
      package: package(),
      test_coverage: [summary: [threshold: 90]],
      preferred_cli_env: [
        check: :test
      ]
    ]
  end

  defp dialyzer do
    [
      plt_local_path: ".plts",
      plt_core_path: ".plts",
      plt_add_apps: [:inets, :ssl, :public_key, :logger],
      flags: [:error_handling, :unknown]
    ]
  end

  defp mermaid(:html) do
    """
    <script src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      document.addEventListener("DOMContentLoaded", function () {
        mermaid.initialize({
          startOnLoad: false,
          theme: document.body.className.includes("dark") ? "dark" : "default"
        });
        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp mermaid(:epub), do: ""

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      mod: {Paypal.Application, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5"},
      {:finch, "~> 0.17"},
      {:countries, "~> 1.6"},
      {:money, "~> 1.12"},
      {:typed_ecto_schema, "~> 0.4"},
      {:ecto, "~> 3.9"},
      {:bypass, "~> 2.1", only: :test},

      # only for dev
      {:dialyxir, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:credo, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:doctor, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:ex_check, "~> 0.14", only: [:dev, :test], runtime: false},
      {:ex_doc, ">= 0.0.0", only: [:dev, :test], runtime: false},
      {:mix_audit, ">= 0.0.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp docs do
    [
      main: "Paypal",
      source_ref: "v#{@version}",
      canonical: "https://hexdocs.pm/paypal",
      source_url: @source_url,
      extras: ["README.md", "COPYING"],
      before_closing_body_tag: &mermaid/1,
      groups_for_modules: [
        Auth: [
          Paypal.Auth,
          Paypal.Auth.Access,
          Paypal.Auth.Request,
          Paypal.Auth.Worker
        ],
        Order: [
          Paypal.Order,
          Paypal.Order.Authorization,
          Paypal.Order.Authorized,
          Paypal.Order.Create,
          Paypal.Order.ExperienceContext,
          Paypal.Order.Info,
          Paypal.Order.Payer,
          Paypal.Order.PurchaseUnit,
          Paypal.Order.PurchaseUnit.Capture,
          Paypal.Order.PurchaseUnit.Item,
          Paypal.Order.PurchaseUnit.PaymentCollection,
          Paypal.Order.UpcCode
        ],
        Payment: [
          Paypal.Payment,
          Paypal.Payment.Captured,
          Paypal.Payment.Info,
          Paypal.Payment.Refund,
          Paypal.Payment.RefundRequest
        ],
        Subscription: [
          Paypal.Subscription,
          Paypal.Subscription.Info,
          Paypal.Subscription.Create,
          Paypal.Subscription.Subscriber,
          Paypal.Subscription.BillingInfo,
          Paypal.Subscription.ReviseResponse,
          Paypal.Subscription.Capture,
          Paypal.Subscription.Transaction,
          Paypal.Subscription.Transactions,
          Paypal.Subscription.Plan,
          Paypal.Subscription.Plan.Info,
          Paypal.Subscription.Plan.Create,
          Paypal.Subscription.Plan.BillingCycle,
          Paypal.Subscription.Plan.PaymentPreferences,
          Paypal.Subscription.Plan.Taxes,
          Paypal.Subscription.Plan.List,
          Paypal.Subscription.Product,
          Paypal.Subscription.Product.Info,
          Paypal.Subscription.Product.Create,
          Paypal.Subscription.Product.List
        ],
        "Common and Helpers": [
          Paypal.Client,
          Paypal.Common.CurrencyValue,
          Paypal.Common.Error,
          Paypal.Common.Link,
          Paypal.Common.Operation,
          Paypal.EctoHelpers
        ]
      ]
    ]
  end

  defp package do
    [
      files: ~w[ lib mix.exs README* COPYING* LICENSE* .formatter.exs ],
      maintainers: ["Manuel Rubio"],
      licenses: ["MIT"],
      links: %{
        "Paypal v2 Docs" => "https://developer.paypal.com/api/rest/",
        "Paypal Subscriptions Docs" => "https://developer.paypal.com/docs/api/subscriptions/v1/",
        "GitHub" => @source_url
      }
    ]
  end
end
