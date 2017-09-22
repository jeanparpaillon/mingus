defmodule Mg.Model.Infrastructure do
  @moduledoc """
  Defines OCCI Kinds and Mixins for infrastructure
  """
  use OCCI.Model
  alias OCCI.Types

  extends OCCI.Model.Infrastructure

  mixin "http://schemas.kbrw.fr/occi/infrastructure#host",
    title: "physical host",
    applies: ["http://schemas.ogf.org/occi/infrastructure#compute"],
    attributes: [
      "mg.host.location": [
        type: Types.String,
        required: true,
        description: "Physical host location (datacenter, ...)"
      ]
    ]
end
