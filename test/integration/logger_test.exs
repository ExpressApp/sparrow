defmodule Integration.LoggerTest do
  use Sparrow.IntegrationCase, async: false

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
