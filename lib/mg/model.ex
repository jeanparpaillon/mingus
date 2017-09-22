defmodule Mg.Model do
  @moduledoc """
  Defines kinds and mixins for Mingus
  """
  use OCCI.Model

  extends Mg.Model.Infrastructure
  extends Mg.Model.Platform
  extends Mg.Model.Auth
end
