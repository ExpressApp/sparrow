defmodule SparrowTest do
  use Sparrow.Case

  doctest Sparrow

  describe "#capture" do
    test "sends event to Sentry" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(url, _headers, body, _opts) ->
        assert url == "https://sentry.host/api/store/"
        assert %{"message" => ^message, "project" => "42"} = decode(body)

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "https://p:s@sentry.host/42")
    end

    test "contains stacktrace started from current location" do
      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert %{"stacktrace" => %{"frames" => stacktrace}} = decode(body)

        assert [
          %{"filename" => "lib/ex_unit/runner.ex", "function" => "anonymous fn/4 in ExUnit.Runner.spawn_test_monitor/4", "lineno" => _, "module" => "ExUnit.Runner", "vars" => %{}},
          %{"filename" => "timer.erl", "function" => ":timer.tc/1", "lineno" => _, "module" => ":timer", "vars" => %{}},
          %{"filename" => "lib/ex_unit/runner.ex", "function" => "ExUnit.Runner.exec_test/1", "lineno" => _, "module" => "ExUnit.Runner", "vars" => %{}},
          %{"filename" => "test/sparrow_test.exs", "function" => "SparrowTest.\"test #capture contains stacktrace started from current location\"/1", "lineno" => 34, "module" => "SparrowTest", "vars" => %{}}
        ] = stacktrace

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture("test")
    end

    test "with custom stacktrace" do
      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert json = decode(body)
        refute Map.get(json, "stacktrace")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture("test", stacktrace: [])
    end

    test "formatted extra" do
      expect(Sparrow.ClientMock, :request, fn(_url, _headers, body, _opts) ->
        assert json = decode(body)
        assert %{
          "key" => ":value",
          "key2" => "[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, " <>
                    "21, 22,\n 23, 24, 25, 26, 27, 28, 29, 30]"
        } == Map.get(json, "extra")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture("test", extra: %{key: :value, key2: (1..30) |> Enum.to_list()})
    end

    test "sends event to Sentry with public and secret keys" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(_url, headers, _body, _opts) ->
        assert {"X-Sentry-Auth", sentry_auth} = List.keyfind(headers, "X-Sentry-Auth", 0)
        assert [_version, _client, _time, " sentry_key=public", " sentry_secret=secret"] = String.split(sentry_auth, ",")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "https://public:secret@sentry.local/42")
    end

    test "sends event to Sentry with public key only" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(_url, headers, _body, _opts) ->
        assert {"X-Sentry-Auth", sentry_auth} = List.keyfind(headers, "X-Sentry-Auth", 0)
        assert [_version, _client, _time, " sentry_key=public"] = String.split(sentry_auth, ",")

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "https://public@sentry.local/42")
    end

    test "sends event to Sentry through proxy" do
      message = "test message"

      expect(Sparrow.ClientMock, :request, fn(url, _headers, body, _opts) ->
        assert url == "http://proxy/service/suffix/api/store/"
        assert %{"project" => "31"} = decode(body)

        {:ok, ~s({"id":0})}
      end)

      assert {:ok, _id} = Sparrow.capture(message, dsn: "http://public:secret@proxy/service/suffix/31")
    end

    test "returns :dsn_empty when DSN id empty" do
      assert {:error, :dsn_empty} == Sparrow.capture("test message", dsn: nil)
      assert {:error, :dsn_empty} == Sparrow.capture("test message", dsn: "")
    end

    test "returns :dsn_invalid when DSN id invalid" do
      assert {:error, {:dsn_invalid, %URI{}}} =
        Sparrow.capture("test message", dsn: "invalid dsn")
    end
  end

  defp decode(binary) do
    binary |> Base.decode64!() |> :zlib.uncompress() |> Jason.decode!()
  end
end
