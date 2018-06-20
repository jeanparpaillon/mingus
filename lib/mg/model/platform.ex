defmodule Mg.Model.Platform do
  @moduledoc """
  Defines OCCI Kinds and Mixins for Mingus platform
  """
  use OCCI.Model,
    scheme: "http://schemas.ogf.org/occi/platform"

  alias OCCI.Model.Core

  kind(
    Application,
    parent: Core.Resource,
    title: "deployable application",
    attributes: [
      "occi.app.name": [
        type: OCCI.Types.String,
        required: true,
        description: "Application name"
      ],
      "occi.app.description": [
        type: OCCI.Types.String,
        required: false,
        description: "Application description"
      ],
      "occi.app.fqdn": [
        type: OCCI.Types.String,
        required: false,
        description: "Application FQDN, when exposed as a service"
      ],
      "occi.app.ip": [
        type: OCCI.Types.CIDR,
        required: false,
        mutable: false,
        description: "Application IP, when exposed as a service"
      ]
    ]
  )

  kind(
    Proxy,
    parent: Core.Link,
    attributes: [
      "occi.app.fqdn": [
        type: OCCI.Types.String,
        required: true,
        description: "Application the proxy is proxying"
      ],
      "occi.app.ip": [
        type: OCCI.Types.CIDR,
        required: true,
        mutable: false,
        description: "IP the proxy is redirecting to"
      ]
    ]
  )
end
