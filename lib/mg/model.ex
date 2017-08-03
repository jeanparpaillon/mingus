defmodule Mg.Model do
  @moduledoc """
  Defines kinds and mixins for Mingus
  """
  use OCCI.Model

  extends OCCI.Model.Infrastructure

  kind "http://schemas.ogf.org/occi/platform#application",
    parent: OCCI.Model.Core.Resource,
    alias: Platform.Application,
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

  kind "http://schemas.ogf.org/occi/platform#proxy",
    parent: OCCI.Model.Core.Link,
    alias: Platform.Proxy,
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

  kind "http://schemas.ogf.org/occi/auth#user",
    parent: OCCI.Model.Core.Resource,
    alias: Auth.User,
    title: "platform user",
    attributes: [
      "occi.auth.login": [
        type: OCCI.Types.String,
        required: true,
        description: "User login"
      ],
      "occi.auth.uid": [
        type: OCCI.Types.Integer,
        required: true,
        description: "User ID"
      ],
      "occi.auth.gid": [
        type: OCCI.Types.Integer,
        required: true,
        description: "User group ID"
      ]
    ]

  mixin "http://schemas.ogf.org/occi/auth#ssh_user",
    applies: [ "http://schemas.ogf.org/occi/auth#user" ],
    alias: Auth.SSHUser,
    attributes: [
      "occi.auth.ssh.pub_key": [
        type: OCCI.Types.String,
        required: true,
        description: "Public SSH Key"
      ]
    ]
end
