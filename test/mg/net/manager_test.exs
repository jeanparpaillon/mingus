defmodule MgTest.Net.Manager do
  use ExUnit.Case
  alias Mg.Net.Manager

  @pool4_27 {{88, 23, 65, 224}, 27}
  @pool6_56 {{0x2001, 0x41D0, 0x009A, 0x0A00, 0, 0, 0, 0}, 56}

  setup ctx do
    {:ok, _} =
      Manager.start_link([
        @pool4_27,
        @pool6_56
      ])

    {:ok, ctx}
  end

  test "Lease on /27 IPv4 pool", _ctx do
    # 30 * different /32 IP available
    leases =
      0..29
      |> Enum.reduce(MapSet.new(), fn _, acc ->
        lease = Manager.lease(@pool4_27)
        assert lease != nil
        MapSet.put(acc, lease)
      end)

    assert MapSet.size(leases) == 30

    # No more leases
    assert Manager.lease(@pool4_27) == nil
  end

  test "Lease on /56 IPv6 pool", _ctx do
    # 256 * different /64 IP available
    leases =
      0..255
      |> Enum.reduce(MapSet.new(), fn _, acc ->
        lease = Manager.lease(@pool6_56, mask: 64)
        assert lease != nil
        MapSet.put(acc, lease)
      end)

    assert MapSet.size(leases) == 256

    # No more leases
    assert Manager.lease(@pool6_56) == nil
  end

  test "Release not leased block" do
    refute Manager.release({{192, 68, 54, 2}, 23})
  end

  test "Release leased block" do
    lease = Manager.lease(@pool4_27, mask: 30)
    assert Manager.release(lease)
  end

  doctest Manager
end
