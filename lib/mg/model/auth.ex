defmodule Mg.Model.Auth do
  @moduledoc """
  Defines OCCI Kinds and Mixins for Mingus authentication related stuff
  """
  use OCCI.Model,
    scheme: "http://schemas.ogf.org/occi/auth"

  alias OCCI.Model.Core

  kind(
    User,
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
  )

  mixin(
    SshUser,
    term: "ssh_user",
    applies: [User],
    attributes: [
      "occi.auth.ssh.pub_key": [
        type: OCCI.Types.String,
        required: true,
        description: "Public SSH Key"
      ]
    ]
  )
end
