defmodule Mg.Model do
  use OCCI.Model

  kind "http://schemas.ogf.org/occi/infrastructure#network",
    parent: OCCI.Model.Core.Resource,
    attributes: [
      "occi.network.vlan": [
        type: OCCI.Types.Integer,
        description: "802.1q VLAN Identifier"
      ],
      "occi.network.label": [
        type: OCCI.Types.String,
        description: "Tag based VLANs"
      ],
      "occi.network.state": [
        type: [:active, :inactive, :error],
        required: true,
        default: :inactive,
        mutable: false
      ],
      "occi.network.state.message": [
        type: OCCI.Types.String,
        required: false
      ]
    ]

  mixin "http://schemas.ogf.org/occi/infrastructure/network#ipnetwork",
    applies: [ "http://schemas.ogf.org/occi/infrastructure#network" ],
    attributes: [
      "occi.network.address": [
        type: OCCI.Types.CIDR,
        required: false,
        description: "IP Network address"
      ],
      "occi.network.gateway": [
        type: OCCI.Types.CIDR,
        required: false,
        description: "IP Network address"
      ],
      "occi.network.allocation": [
        type: [:dynamic, :static],
        required: false,
        description: "IP allocation type"
      ]
    ]

  kind "http://schemas.ogf.org/occi/platform#application",
    parent: OCCI.Model.Core.Resource,
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
    attributes: [
      "occi.auth.ssh.pub_key": [
        type: OCCI.Types.String,
        required: true,
        description: "Public SSH Key"
      ]
    ]
end
