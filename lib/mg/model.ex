defmodule Mg.Model do
  @moduledoc """
  Defines kinds and mixins for Mingus
  """
  use OCCI.Model
  alias OCCI.Model.Core
  alias OCCI.Types

  extends Mg.Model.Infrastructure
  extends Mg.Model.Platform
  extends Mg.Model.Auth

  kind "http://schemas.kbrw.fr/occi/mingus#provider",
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

  mixin "http://schemas.kbrw.fr/occi/mingus/provider#ovh",
    applies: ["http://schemas.kbrw.fr/occi/mingus#provider"],
    title: "OVH data provider"
end
