defmodule Mg.Data do
  use OCCI.Model, store: %{}

  @ext_core "http://schemas.ogf.org/occi/core#"
  @kind_resource "#{@ext_core}resource"
  @kind_link "#{@ext_core}link"

  @ext_platform "http://schemas.ogf.org/occi/platform#"
  @kind_application "#{@ext_platform}application"
  @kind_component "#{@ext_platform}component"
  @kind_component_link "#{@ext_platform}componentlink"

  extension @ext_platform do
    kind @kind_application extends @kind_resource do
      attr "occi.app.name",
        type: OCCI.Types.String, required: true, description: "Application name"
      attr "occi.app.context",
        type: OCCI.Types.String, required: false, mutable: false,
        description: "URL for contextualizating the app"
      attr "occi.app.url",
        type: OCCI.Types.String, required: true, mutable: false,
        description: "DNS entry"
      attr "occi.app.state",
        type: OCCI.Types.Enum.new([:active, :inactive, :error]),
        required: false, mutable: false,
        description: "State of the application"
      attr "occi.app.state.message",
        type: OCCI.Types.String, required: false,
        description: "Human-readable explanation of the current instance state"
    end

    kind @kind_component extends @kind_resource do
      attr "occi.component.state",
        type: OCCI.State.Enum.new([:active, :inactive, :error]),
        required: true,
        description: "State of the component"
      attr "occi.component.state.message",
        type: OCCI.State.String, required: false,
        description: "Human-readable explanation of the current instance state"
    end

    kind @kind_component_link extends @kind_link
  end

  @ext_kbrw "http://schemas.kbrw.fr/occi#"

  extension "#{@ext_kbrw}" import @ext_platform do
    kind "#{@ext_kbrw}servicelink" extends @kind_link do
      attr "kbrw.service.name",
        type: OCCI.Types.String, required: true, mutable: true,
        description: "FQDN"
    end

    mixin "#{@ext_kbrw}service" do
      attr "kbrw.app.ip",
        type: OCCI.Types.String, required: true, mutable: true,
        description: "Published service IP"
    end

    mixin "#{@ext_kbrw}proxy" depends "#{@ext_kbrw}service" do
      attr "kbrw.app.ip",
        type: OCCI.Types.String, mutable: false,
        description: "IP to access the application"
    end
  end

  resource "app1" kind @kind_application mixins ["#{@ext_kbrw}proxy"]
  state %{ :'occi.app.name' => "Ma super application",
          :'occi.app.url' => "http://myapp.kbrwadventure.com" }
end
