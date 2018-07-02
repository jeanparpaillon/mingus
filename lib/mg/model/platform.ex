defmodule Mg.Model.Platform do
  @moduledoc """
  Defines OCCI Kinds and Mixins for Mingus platform
  """
  use OCCI.Model,
    scheme: "http://schemas.ogf.org/occi/platform"

  alias OCCI.Model.Core

  require OCCI.Types.String
  require OCCI.Types.CIDR

  kind Application,
    parent: Core.Resource,
    title: "deployable application" do
    attribute(
      "occi.app.name",
      type: OCCI.Types.String,
      required: true,
      description: "Application name"
    )

    attribute(
      "occi.app.description",
      type: OCCI.Types.String,
      required: false,
      description: "Application description"
    )

    attribute(
      "occi.app.fqdn",
      type: OCCI.Types.String,
      required: false,
      description: "Application FQDN, when exposed as a service"
    )

    attribute(
      "occi.app.ip",
      type: OCCI.Types.CIDR,
      required: false,
      mutable: false,
      description: "Application IP, when exposed as a service"
    )
  end

  kind Proxy,
    parent: Core.Link do
    attribute(
      "occi.app.fqdn",
      type: OCCI.Types.String,
      required: true,
      description: "Application the proxy is proxying"
    )

    attribute(
      "occi.app.ip",
      type: OCCI.Types.CIDR,
      required: true,
      mutable: false,
      description: "IP the proxy is redirecting to"
    )
  end
end
