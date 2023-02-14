defmodule Integration.GenServerTest do
  use Sparrow.IntegrationCase

  alias Sparrow.Support.GenServer, as: GS

  describe "crashed with" do
    setup do
      {:ok, pid} = GS.start_link()
      {:ok, pid: pid}
    end

    test "exit", %{pid: pid} do
      send(pid, :exit)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception ==
        [%{type: "ErlangError", value: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert trim_lineno(crash.message) ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert [
        %{vars: %{}, filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib"},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 21, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert report.exception ==
        [%{type: "ErlangError", value: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Last message: :exit
        """)

      assert [
        %{vars: %{}, filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib"},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 21, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = report.stacktrace.frames
    end

    test "throw", %{pid: pid} do
      send(pid, :throw)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception ==
        [%{type: "ErlangError", value: "{:bad_return_value, :throwed}"}]

      assert trim_lineno(crash.message) ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) bad return value: :throwed
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_common_reply/8
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_common_reply/8", lineno: _}
      ] = crash.stacktrace.frames

      assert report.exception ==
        [%{type: "ErlangError", value: "{:bad_return_value, :throwed}"}]

      assert report.message ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) bad return value: :throwed
        Last message: :throw
        """)

      assert report.stacktrace.frames == []
    end

    test "raise", %{pid: pid} do
      send(pid, :raise)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(crash.message) ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (ArgumentError) argument error
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_msg/6", lineno: _},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert report.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (ArgumentError) argument error
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Last message: :raise
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = report.stacktrace.frames
    end

    test "badmatch", %{pid: pid} do
      send(pid, :badmatch)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception == [%{type: "MatchError", value: "no match of right hand side value: 2"}]

      assert trim_lineno(crash.message) ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (MatchError) no match of right hand side value: 2
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_msg/6", lineno: _},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 33, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert report.exception == [%{type: "MatchError", value: "no match of right hand side value: 2"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (MatchError) no match of right hand side value: 2
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Last message: :badmatch
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 33, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = report.stacktrace.frames
    end

    test "bad_return", %{pid: pid} do
      send(pid, :bad_return)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception ==
        [%{type: "ErlangError", value: "{:bad_return_value, :bad_return}"}]

      assert trim_lineno(crash.message) ==
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) bad return value: :bad_return
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_common_reply/8
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_common_reply/8", lineno: _}
      ] = crash.stacktrace.frames

      assert report.exception ==
        [%{type: "ErlangError", value: "{:bad_return_value, :bad_return}"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) bad return value: :bad_return
        Last message: :bad_return
        """)

      assert report.stacktrace.frames == []
    end
  end

  describe "GenServer with registered name" do
    setup do
      name = NamedGS

      {:ok, pid} = GS.start_link(name: name)
      {:ok, pid: pid, name: name}
    end

    test "raise", %{pid: pid, name: name} do
      send(pid, :raise)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{extra: %{state: _}}

      assert crash.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(crash.message) ==
        String.trim("""
        Process #{inspect(name)} (#{inspect(pid)}) terminating
        ** (ArgumentError) argument error
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [#{inspect(self())}]
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", module: ":gen_server", vars: %{}, function: ":gen_server.handle_msg/6", lineno: _},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert report.exception == [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        GenServer #{inspect(name)} terminating
        ** (ArgumentError) argument error
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Last message: :raise
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
      ] =  report.stacktrace.frames
    end
  end

  describe "GenServer reports" do
    setup do
      {:ok, pid} = GS.start_link()
      send(pid, :bad_return)

      {:ok, pid: pid}
    end

    test "with state, last message and pid", %{pid: pid} do
      assert_receive %Sparrow.Event{
        extra: %{
          last_message: :bad_return, name: ^pid,
          state: %Sparrow.Support.GenServer.State{a: 1, b: 2, c: %{d: []}}
        }
      }
    end

    test "with simple exception" do
      assert_receive %Sparrow.Event{
        exception: [
          %{type: "ErlangError", value: "{:bad_return_value, :bad_return}"}
        ]
      }
    end

    test "with message", %{pid: pid} do
      assert_receive %Sparrow.Event{message: message}

      assert trim_lineno(message) ==
        String.trim("""
        GenServer #{inspect(pid)} terminating
        ** (stop) bad return value: :bad_return
        Last message: :bad_return
        """)
    end

    test "without stacktrace" do
      assert_receive %Sparrow.Event{
        stacktrace: %{frames: []}
      }
    end
  end
end
