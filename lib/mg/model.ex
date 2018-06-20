defmodule Mg.Model do
  @moduledoc """
  Defines kinds and mixins for Mingus
  """
  use OCCI.Model,
    scheme: "http://schemas.kbrw.fr/occi/mingus"

  alias OCCI.Model.Core
  alias OCCI.Types

  extends(Mg.Model.Infrastructure)
  extends(Mg.Model.Platform)
  extends(Mg.Model.Auth)

  kind(
    Provider,
    parent: Core.Resource,
    title: "Mingus data provider",
    attributes: [
      "mg.provider.state": [
        type: [:active, :inactive, :error],
        description: "Provider status"
      ],
      "mg.provider.state.message": [
        type: Types.String,
        description: "Human-readable explanation of the current instance state"
      ]
    ]
  )

  mixin(
    Provider.Ovh,
    applies: [Provider],
    title: "OVH data provider"
  )
end
