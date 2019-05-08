defmodule SparrowTest do
  use Sparrow.Case
  doctest Sparrow

  describe "#capture" do
    test "sends event to Sentry" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert {:ok, %{"message" => ^message}} = Jason.decode(body)

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message)
    end

    test "contains stacktrace started from current location" do
      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert {:ok, %{"stacktrace" => %{"frames" => stacktrace}}} = Jason.decode(body)

        assert [
          %{"filename" => "lib/ex_unit/runner.ex", "function" => "anonymous fn/4 in ExUnit.Runner.spawn_test_monitor/4", "lineno" => 306, "module" => "ExUnit.Runner", "vars" => %{}},
          %{"filename" => "timer.erl", "function" => ":timer.tc/1", "lineno" => 166, "module" => ":timer", "vars" => %{}},
          %{"filename" => "lib/ex_unit/runner.ex", "function" => "ExUnit.Runner.exec_test/1", "lineno" => 355, "module" => "ExUnit.Runner", "vars" => %{}},
          %{"filename" => "test/sparrow_test.exs", "function" => "SparrowTest.\"test #capture contains stacktrace started from current location\"/1", "lineno" => 32, "module" => "SparrowTest", "vars" => %{}}
        ] == stacktrace

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture("test")
    end
  end
end
