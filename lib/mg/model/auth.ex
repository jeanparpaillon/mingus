defmodule Mg.Model.Auth do
  @moduledoc """
  Defines OCCI Kinds and Mixins for Mingus authentication related stuff
  """
  use OCCI.Model,
    scheme: "http://schemas.ogf.org/occi/auth"

  require OCCI.Types.String
  require OCCI.Types.Integer

  alias OCCI.Model.Core

  kind User,
    parent: Core.Resource,
    title: "platform user" do

    attribute "occi.auth.login",
      type: OCCI.Types.String,
      required: true,
      description: "User login"

    attribute "occi.auth.uid",
      type: OCCI.Types.Integer,
      required: true,
      description: "User ID"

    attribute "occi.auth.gid",
      type: OCCI.Types.Integer,
      required: true,
      description: "User group ID"
  end

  mixin SshUser,
    term: "ssh_user",
    applies: [User] do

    attribute "occi.auth.ssh.pub_key",
      type: OCCI.Types.String,
      required: true,
      description: "Public SSH Key"
  end
end
