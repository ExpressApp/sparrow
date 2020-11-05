defmodule Integration.SupervisorTest do
  use Sparrow.IntegrationCase, async: false

  setup do
    {:ok, pid} = start_supervised(Sparrow.Support.Supervisor)
    {:ok, pid: pid}
  end

  describe "crashed with" do
    setup do
      {:ok, value: [1, 2, 3]}
    end

    test "exit" do
      pid = Process.whereis(Sparrow.Support.GenServer)
      send(Sparrow.Support.GenServer, :exit)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive gs_report = %Sparrow.Event{extra: %{state: _}}
      assert_receive sup_report = %Sparrow.Event{}

      assert crash.exception ==
        [%{type: "ErlangError", value: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert trim_lineno(crash.message) =~
        String.trim("""
        Process #{inspect(Sparrow.Support.GenServer)} (#{inspect(pid)}) terminating
        ** (exit) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [Sparrow.Support.Supervisor,
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{vars: %{}, filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server"},
        %{vars: %{}, filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server"},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 21, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert gs_report.exception ==
        [%{type: "ErlangError", value: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert trim_lineno(gs_report.message) =~
        String.trim("""
        GenServer #{inspect(Sparrow.Support.GenServer)} terminating
        ** (stop) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Last message: :exit
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 21, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = gs_report.stacktrace.frames

      assert sup_report.exception ==
        [%{type: "ErlangError", value: "{:bang, %{very_complex_exit_message: <<1, 2, 3>>}}"}]

      assert trim_lineno(sup_report.message) ==
        String.trim("""
        Child #{inspect(Sparrow.Support.GenServer)} of Supervisor #{inspect(Sparrow.Support.Supervisor)} terminated
        ** (exit) {:bang, %{very_complex_exit_message: <<1, 2, 3>>}}
        Pid: #{inspect(pid)}
        Start Call: #{inspect(Sparrow.Support.GenServer)}.start_link([name: #{inspect(Sparrow.Support.GenServer)}])
        """)

      assert sup_report.stacktrace.frames == []
    end

    test "raise" do
      pid = Process.whereis(Sparrow.Support.GenServer)
      send(Sparrow.Support.GenServer, :raise)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive gs_report = %Sparrow.Event{extra: %{state: _}}
      assert_receive sup_report = %Sparrow.Event{}

      assert crash.exception ==
        [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(crash.message) =~
        String.trim("""
        Process #{inspect(Sparrow.Support.GenServer)} (#{inspect(pid)}) terminating
        ** (ArgumentError) argument error
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [Sparrow.Support.Supervisor,
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{vars: %{}, filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server"},
        %{vars: %{}, filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server"},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert gs_report.exception ==
        [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(gs_report.message) =~
        String.trim("""
        GenServer #{inspect(Sparrow.Support.GenServer)} terminating
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
      ] = gs_report.stacktrace.frames

      assert sup_report.exception ==
        [%{type: "ArgumentError", value: "argument error"}]

      assert trim_lineno(sup_report.message) ==
        String.trim("""
        Child #{inspect(Sparrow.Support.GenServer)} of Supervisor #{inspect(Sparrow.Support.Supervisor)} terminated
        ** (exit) an exception was raised:
            ** (ArgumentError) argument error
                (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
                (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
                (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
                (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Pid: #{inspect(pid)}
        Start Call: #{inspect(Sparrow.Support.GenServer)}.start_link([name: #{inspect(Sparrow.Support.GenServer)}])
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 29, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = sup_report.stacktrace.frames
    end

    test "badmatch" do
      pid = Process.whereis(Sparrow.Support.GenServer)
      send(Sparrow.Support.GenServer, :badmatch)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive gs_report = %Sparrow.Event{extra: %{state: _}}
      assert_receive sup_report = %Sparrow.Event{}

      assert crash.exception ==
        [%{type: "MatchError", value: "no match of right hand side value: 2"}]

      assert trim_lineno(crash.message) =~
        String.trim("""
        Process #{inspect(Sparrow.Support.GenServer)} (#{inspect(pid)}) terminating
        ** (MatchError) no match of right hand side value: 2
            (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
            (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
            (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: Sparrow.Support.GenServer.init/1
        Ancestors: [Sparrow.Support.Supervisor,
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{vars: %{}, filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server"},
        %{vars: %{}, filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server"},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 33, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = crash.stacktrace.frames

      assert gs_report.exception ==
        [%{type: "MatchError", value: "no match of right hand side value: 2"}]

      assert trim_lineno(gs_report.message) =~
        String.trim("""
        GenServer #{inspect(Sparrow.Support.GenServer)} terminating
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
      ] = gs_report.stacktrace.frames

      assert sup_report.exception ==
        [%{type: "MatchError", value: "no match of right hand side value: 2"}]

      assert trim_lineno(sup_report.message) ==
        String.trim("""
        Child #{inspect(Sparrow.Support.GenServer)} of Supervisor #{inspect(Sparrow.Support.Supervisor)} terminated
        ** (exit) an exception was raised:
            ** (MatchError) no match of right hand side value: 2
                (#{appb(:sparrow)}) test/support/errors/gen_server.ex Sparrow.Support.GenServer.handle_info/2
                (#{appb(:stdlib)}) gen_server.erl :gen_server.try_dispatch/4
                (#{appb(:stdlib)}) gen_server.erl :gen_server.handle_msg/6
                (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Pid: #{inspect(pid)}
        Start Call: #{inspect(Sparrow.Support.GenServer)}.start_link([name: #{inspect(Sparrow.Support.GenServer)}])
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.handle_msg/6", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "gen_server.erl", function: ":gen_server.try_dispatch/4", lineno: _, module: ":gen_server", vars: %{}},
        %{filename: "test/support/errors/gen_server.ex", function: "Sparrow.Support.GenServer.handle_info/2", lineno: 33, module: "Sparrow.Support.GenServer", vars: %{}}
      ] = sup_report.stacktrace.frames
    end
  end
end
