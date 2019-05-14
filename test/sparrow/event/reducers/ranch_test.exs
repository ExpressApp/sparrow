defmodule Sparrow.Event.Reducers.RanchTest do
  use ExUnit.Case

  alias Sparrow.Event.Reducers.Ranch

  setup do
    {:ok, conn: Plug.Test.conn(:get, "/path", %{}), event: Sparrow.Event.new()}
  end

  test "no route error", %{conn: conn, event: event} do
    assert event = Ranch.reduce(log_event(log_report(conn, {%Plug.BadRequestError{}, example_stacktrace()})), event)

    assert event.exception == [%{type: "Plug.BadRequestError", value: "could not process the request due to client error"}]

    assert event.stacktrace.frames ==
      [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: 249, module: ":proc_lib", vars: %{}},
        %{filename: "/my_app/deps/cowboy/src/cowboy_stream_h.erl", function: ":cowboy_stream_h.request_process/3", lineno: 274, module: ":cowboy_stream_h", vars: %{}},
        %{filename: "/my_app/deps/cowboy/src/cowboy_stream_h.erl", function: ":cowboy_stream_h.execute/3", lineno: 296, module: ":cowboy_stream_h", vars: %{}},
        %{filename: "/my_app/deps/cowboy/src/cowboy_handler.erl", function: ":cowboy_handler.execute/2", lineno: 41, module: ":cowboy_handler", vars: %{}},
        %{filename: "lib/phoenix/endpoint/cowboy2_handler.ex", function: "Phoenix.Endpoint.Cowboy2Handler.init/2", lineno: 33, module: "Phoenix.Endpoint.Cowboy2Handler", vars: %{}},
        %{filename: "lib/my_app_web/endpoint.ex", function: "MyAppWeb.Endpoint.call/2", lineno: 1, module: "MyAppWeb.Endpoint", vars: %{}},
        %{filename: "lib/plug/debugger.ex", function: "MyAppWeb.Endpoint.\"call (overridable 3)\"/2", lineno: 122, module: "MyAppWeb.Endpoint", vars: %{}},
        %{filename: "lib/my_app_web/endpoint.ex", function: "MyAppWeb.Endpoint.plug_builder_call/2", lineno: 1, module: "MyAppWeb.Endpoint", vars: %{}},
        %{filename: "lib/phoenix/router.ex", function: "MyAppWeb.Router.call/2", lineno: 304, module: "MyAppWeb.Router", vars: %{}},
        %{filename: "lib/my_app_web/router.ex", function: "MyAppWeb.Router.__match_route__/4", lineno: 1, module: "MyAppWeb.Router", vars: %{}}
      ]

    assert event.extra == %{plug: MyAppWeb.Endpoint}

    assert event.request == %{
      url: "http://www.example.com/path",
      method: "GET",
      headers: %{"content-type" => "multipart/mixed; boundary=plug_conn_test"},
      query_string: "",
      env: []
    }
  end

  test "reason without stacktrace", %{conn: conn, event: event} do
    assert event = Ranch.reduce(log_event(log_report(conn, {:timeout, {:m, :f, [:a1, :a2]}})), event)

    assert event.exception == [%{type: "ErlangError", value: "Erlang error: {:timeout, {:m, :f, [:a1, :a2]}}"}]
    assert event.stacktrace.frames == []

    assert event.extra == %{plug: MyAppWeb.Endpoint}

    assert event.request == %{
      url: "http://www.example.com/path",
      method: "GET",
      headers: %{"content-type" => "multipart/mixed; boundary=plug_conn_test"},
      query_string: "",
      env: []
    }
  end

  defp log_event(message) do
    %{level: :error, msg: message, meta: %{}}
  end

  defp log_report(conn, reason) do
    {:report, %{
      args: [
        MyAppWeb.Endpoint.HTTP,
        self(), 1, self(),
        {
          reason, {MyAppWeb.Endpoint, :call, [conn, []]}
        },
        [
          {Phoenix.Endpoint.Cowboy2Handler, :init, 2, [file: 'lib/phoenix/endpoint/cowboy2_handler.ex', line: 42]},
          {:cowboy_handler, :execute, 2, [file: '/my_app/deps/cowboy/src/cowboy_handler.erl', line: 41]},
          {:cowboy_stream_h, :execute, 3, [file: '/my_app/deps/cowboy/src/cowboy_stream_h.erl', line: 296]},
          {:cowboy_stream_h, :request_process, 3, [file: '/my_app/deps/cowboy/src/cowboy_stream_h.erl', line: 274]},
          {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 249]}
        ]
      ],
      format: 'Ranch listener ~p, connection process ~p, stream ~p had its request process ~p exit with reason ~999999p and stacktrace ~999999p~n',
      label: {:error_logger, :error_msg}
    }}
  end

  defp example_stacktrace do
    [
      {MyAppWeb.Router, :__match_route__, 4, [file: 'lib/my_app_web/router.ex', line: 1]},
      {MyAppWeb.Router, :call, 2, [file: 'lib/phoenix/router.ex', line: 304]},
      {MyAppWeb.Endpoint, :plug_builder_call, 2, [file: 'lib/my_app_web/endpoint.ex', line: 1]},
      {MyAppWeb.Endpoint, :"call (overridable 3)", 2, [file: 'lib/plug/debugger.ex', line: 122]},
      {MyAppWeb.Endpoint, :call, 2, [file: 'lib/my_app_web/endpoint.ex', line: 1]},
      {Phoenix.Endpoint.Cowboy2Handler, :init, 2, [file: 'lib/phoenix/endpoint/cowboy2_handler.ex', line: 33]},
      {:cowboy_handler, :execute, 2, [file: '/my_app/deps/cowboy/src/cowboy_handler.erl', line: 41]},
      {:cowboy_stream_h, :execute, 3, [file: '/my_app/deps/cowboy/src/cowboy_stream_h.erl', line: 296]},
      {:cowboy_stream_h, :request_process, 3, [file: '/my_app/deps/cowboy/src/cowboy_stream_h.erl', line: 274]},
      {:proc_lib, :init_p_do_apply, 3, [file: 'proc_lib.erl', line: 249]}
    ]
  end
end
