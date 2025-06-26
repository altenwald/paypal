defmodule Paypal.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :paypal,
      version: @version,
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "Paypal",
      description: "Paypal API v2",
      docs: docs(),
      package: package(),
      preferred_cli_env: [
        check: :test
      ]
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
      {:tesla, "~> 1.9"},
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
      # logo: "guides/images/paypal.png",
      # extra_section: "GUIDES",
      source_url: "https://github.com/altenwald/paypal",
      # extras: extras(),
      # groups_for_extras: groups_for_extras(),
      # before_closing_head_tag: &before_closing_head_tag/1,
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
        "Common and Helpers": [
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
      files: ~w[ lib mix.* *.md COPYING ],
      maintainers: ["Manuel Rubio"],
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/altenwald/paypal",
        "Docs" => "https://hexdocs.pm/paypal"
      }
    ]
  end
end
