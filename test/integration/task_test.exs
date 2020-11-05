defmodule Integration.TaskTest do
  use Sparrow.IntegrationCase, async: false

  setup do
    {:ok, pid} = start_supervised({Task.Supervisor, name: __MODULE__})
    {:ok, pid: pid}
  end

  describe "crashed with" do
    setup do
      {:ok, value: [1, 2, 3]}
    end

    test "exit" do
      {:ok, pid} = Task.Supervisor.start_child(__MODULE__, fn ->
        exit(:task_crashed)
      end)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{}

      assert crash.exception ==
        [%{type: "ErlangError", value: ":task_crashed"}]

      assert trim_lineno(crash.message) =~
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (exit) :task_crashed
            test/integration/task_test.exs anonymous fn/0 in Integration.TaskTest."test crashed with exit"/1
            (#{appb(:elixir)}) lib/task/supervised.ex Task.Supervised.invoke_mfa/2
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: anonymous fn/0 in Integration.TaskTest."test crashed with exit"/1
        Ancestors: [Integration.TaskTest,
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "lib/task/supervised.ex", function: "Task.Supervised.invoke_mfa/2", lineno: _, module: "Task.Supervised", vars: %{}},
        %{filename: "test/integration/task_test.exs", function: "anonymous fn/0 in Integration.TaskTest.\"test crashed with exit\"/1", lineno: 16, module: "Integration.TaskTest", vars: %{}}
      ] = crash.stacktrace.frames

      assert report.exception ==
        [%{type: "ErlangError", value: ":task_crashed"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        Child :undefined of Supervisor #{inspect(__MODULE__)} terminated
        ** (exit) :task_crashed
        Pid: #{inspect(pid)}
        Start Call: Task.Supervised.start_link/?
        """)

      assert report.stacktrace.frames == []
    end

    test "raise" do
      {:ok, pid} = Task.Supervisor.start_child(__MODULE__, fn ->
        raise RuntimeError, "test crash"
      end)

      assert_receive crash = %Sparrow.Event{extra: %{initial_call: _}}
      assert_receive report = %Sparrow.Event{}

      assert crash.exception ==
        [%{type: "RuntimeError", value: "test crash"}]

      assert trim_lineno(crash.message) =~
        String.trim("""
        Process #{inspect(pid)} terminating
        ** (RuntimeError) test crash
            test/integration/task_test.exs anonymous fn/0 in Integration.TaskTest."test crashed with raise"/1
            (#{appb(:elixir)}) lib/task/supervised.ex Task.Supervised.invoke_mfa/2
            (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Initial Call: anonymous fn/0 in Integration.TaskTest."test crashed with raise"/1
        Ancestors: [Integration.TaskTest,
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "lib/task/supervised.ex", function: "Task.Supervised.invoke_mfa/2", lineno: _, module: "Task.Supervised", vars: %{}},
        %{filename: "test/integration/task_test.exs", function: "anonymous fn/0 in Integration.TaskTest.\"test crashed with raise\"/1", lineno: _, module: "Integration.TaskTest", vars: %{}}
      ] = crash.stacktrace.frames

      assert report.exception ==
        [%{type: "RuntimeError", value: "test crash"}]

      assert trim_lineno(report.message) ==
        String.trim("""
        Child :undefined of Supervisor #{inspect(__MODULE__)} terminated
        ** (exit) an exception was raised:
            ** (RuntimeError) test crash
                test/integration/task_test.exs anonymous fn/0 in Integration.TaskTest.\"test crashed with raise\"/1
                (#{appb(:elixir)}) lib/task/supervised.ex Task.Supervised.invoke_mfa/2
                (#{appb(:stdlib)}) proc_lib.erl :proc_lib.init_p_do_apply/3
        Pid: #{inspect(pid)}
        Start Call: Task.Supervised.start_link/?
        """)

      assert [
        %{filename: "proc_lib.erl", function: ":proc_lib.init_p_do_apply/3", lineno: _, module: ":proc_lib", vars: %{}},
        %{filename: "lib/task/supervised.ex", function: "Task.Supervised.invoke_mfa/2", lineno: _, module: "Task.Supervised", vars: %{}},
        %{filename: "test/integration/task_test.exs", function: "anonymous fn/0 in Integration.TaskTest.\"test crashed with raise\"/1", lineno: _, module: "Integration.TaskTest", vars: %{}}
      ] = report.stacktrace.frames
    end
  end
end
