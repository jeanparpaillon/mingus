defmodule Mg.Model.Auth do
  @moduledoc """
  Defines OCCI Kinds and Mixins for Mingus authentication related stuff
  """
  use OCCI.Model
  alias OCCI.Model.Core

  kind "http://schemas.ogf.org/occi/auth#user",
    parent: Core.Resource,
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
    attributes: [
      "occi.auth.ssh.pub_key": [
        type: OCCI.Types.String,
        required: true,
        description: "Public SSH Key"
      ]
    ]
end
