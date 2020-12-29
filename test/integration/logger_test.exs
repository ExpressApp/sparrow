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

      test "error with sparrow: false option" do
        spawn_link(fn ->
          Logger.error("message", sparrow: false)
        end)

        refute_receive %Sparrow.Event{}
      end
    end

    describe "Logger with handler_config option" do
      test "level: :critical" do
        swap_handler_config(level: :critical)

        spawn_link(fn ->
          Logger.error("error")
          Logger.critical("critical")
          Logger.alert("alert")
          Logger.emergency("emergency")
        end)

        refute_receive %Sparrow.Event{message: "error"}
        assert_receive %Sparrow.Event{message: "critical"}
        assert_receive %Sparrow.Event{message: "alert"}
        assert_receive %Sparrow.Event{message: "emergency"}
      end

      test "level: :emergency" do
        swap_handler_config(level: :emergency)

        spawn_link(fn ->
          Logger.error("error")
          Logger.critical("critical")
          Logger.alert("alert")
          Logger.emergency("emergency")
        end)

        refute_receive %Sparrow.Event{message: "error"}
        refute_receive %Sparrow.Event{message: "critical"}
        refute_receive %Sparrow.Event{message: "alert"}
        assert_receive %Sparrow.Event{message: "emergency"}
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
