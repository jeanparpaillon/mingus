![Mingus Logo](/priv/mingus_medium.png)

Mingus is an orchestrator. Simple, efficient, fully distributed.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add `mingus` to your list of dependencies in `mix.exs`:

    ```elixir
    def deps do
      [{:mingus, "~> 0.1.0"}]
    end
    ```

  2. Ensure `mingus` is started before your application:

    ```elixir
    def application do
      [applications: [:mingus]]
    end
    ```

## Rationale

### Actual architecture

Actual infrastructure is made of numerous 3rd party components glued
together with Chef configuration manager.

3rd party components includes:
* DNS directory: `bind9`,
* Build system: `jenkins` + build vms,
* Monitoring: `Zabbix`,
* Logging: `rsyslogd`,
* Integrated code repository: `git` daemon + hooks
* Load-balancing: `HaProxy`,
* Fault-tolerance: `keepalived`


| Actual | Issue | Mingus | Benefit |
|--------|-------|--------|---------|
| 3rd party components | Need expertise for each component | Single, Elixir app | Setup, maintenance cost |
| One configuration per component | Synchronisation through external configuration manager (Chef) | A single data base: no synchronisation, all services consume the same data | Reliability, no de-synchronisation |
| No orchestrator | No elasticity, new workload requires new VM, placed by hand (at least 1-2 hours) | Integrated orchestrator | No cost when adapting workload |
| No orchestrator | Limited and costly fault-tolerance: redundant vms are always up, and statically linked to a host | supervisor_ring is responsible for placement of services on physical host, in a dynamic and automatic way | No need to deal manually with app placement, better reliability: whole infra can work until one physical node is alive |
