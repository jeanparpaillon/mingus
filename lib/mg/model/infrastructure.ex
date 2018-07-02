defmodule Mg.Model.Infrastructure do
  @moduledoc """
  Defines OCCI Kinds and Mixins for infrastructure
  """
  use OCCI.Model,
    scheme: "http://schemas.kbrw.fr/occi/infrastructure"

  alias OCCI.Types

  require Types.String

  extends(OCCI.Model.Infrastructure)

  mixin Host,
    title: "physical host",
    applies: [OCCI.Model.Infrastructure.Compute] do
    attribute(
      "mg.host.location",
      type: Types.String,
      required: true,
      description: "Physical host location (datacenter, ...)"
    )
  end
end
