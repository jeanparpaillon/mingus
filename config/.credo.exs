%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Consistency.SpaceInParentheses, false}
      ]
    }
  ]
}
