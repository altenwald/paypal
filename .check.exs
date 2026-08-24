[
  tools: [
    {:compiler, command: "mix compile --warnings-as-errors"},
    {:formatter, command: "mix format --check-formatted"},
    {:credo, command: "mix credo"},
    {:doctor, command: "mix doctor"},
    {:dialyzer, command: "mix dialyzer"},
    {:ex_unit, command: "mix test --cover"},
    {:ex_doc, command: "mix docs"},
    {:mix_audit, command: "mix deps.audit"},
    {:unused_deps, command: "mix deps.unlock --check-unused"}
  ]
]
