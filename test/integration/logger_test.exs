defmodule Integration.LoggerTest do
  use Sparrow.IntegrationCase, async: false

  if Version.compare(System.version(), "1.11.0") != :lt do
    require Logger

    describe "Logger" do
      test "warn" do
        spawn_link(fn ->
          Logger.warn("message")
        end)

        refute_receive %Sparrow.Event{}
      end

      test "error" do
        spawn_link(fn ->
          Logger.error("message")
        end)

        assert_receive %Sparrow.Event{exception: exception, message: message, stacktrace: %{frames: frames}}

        assert exception ==
          [%{type: "ErlangError", value: "message"}]

        assert message == "message"
        assert frames == []
      end
    end
  end

  describe ":logger" do
    test "error" do
      spawn_link(fn ->
        :logger.error('error with some params: ~p', [42])
      end)

      assert_receive %Sparrow.Event{exception: exception, message: message, stacktrace: %{frames: frames}}

      assert exception ==
        [%{type: "ErlangError", value: "error with some params: 42"}]

      assert message == "nil"
      assert frames == []
    end
  end
end
