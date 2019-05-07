defmodule Integration.ProcTest do
  use IntegrationCase

  describe "crashed with" do
    setup do
      {:ok, value: [1, 2, 3]}
    end

    test "exit can't be caught" do
      spawn_link(fn ->
        exit({:bang, %{very_complex_exit_message: <<1, 2, 3>>}})
      end)

      refute_receive %Sparrow.Event{}, 100
    end

    test "throw" do
      pid = spawn_link(fn ->
        throw({:error, :reason})
      end)

      assert_receive %Sparrow.Event{exception: exception, message: message, stacktrace: %{frames: frames}}

      assert exception ==
        [%{type: "ErlangError", value: "Erlang error: {:nocatch, {:error, :reason}}"}]

      assert message ==
        String.trim("""
        Process #{inspect(pid)} raised an exception
        ** (ErlangError) Erlang error: {:nocatch, {:error, :reason}}
            test/integration/proc_test.exs:19: anonymous fn/0 in Integration.ProcTest."test crashed with throw"/1
        """)

      assert frames ==
        [
          %{filename: "test/integration/proc_test.exs",
            function: "anonymous fn/0 in Integration.ProcTest.\"test crashed with throw\"/1",
            lineno: 19, module: Integration.ProcTest, vars: %{}}
        ]
    end

    test "raise" do
      pid = spawn_link(fn ->
        raise RuntimeError, "test crash"
      end)

      assert_receive %Sparrow.Event{exception: exception, message: message, stacktrace: %{frames: frames}}

      assert exception ==
        [%{type: "RuntimeError", value: "test crash"}]

      assert message ==
        String.trim("""
        Process #{inspect(pid)} raised an exception
        ** (RuntimeError) test crash
            test/integration/proc_test.exs:44: anonymous fn/0 in Integration.ProcTest."test crashed with raise"/1
        """)

      assert frames ==
        [
          %{filename: "test/integration/proc_test.exs",
            function: "anonymous fn/0 in Integration.ProcTest.\"test crashed with raise\"/1",
            lineno: 44, module: Integration.ProcTest, vars: %{}}
        ]
    end

    test "badmatch", %{value: value} do
      pid = spawn_link(fn ->
        [] = value
      end)

      assert_receive %Sparrow.Event{exception: exception, message: message, stacktrace: %{frames: frames}}

      assert exception ==
        [%{type: "MatchError", value: "no match of right hand side value: #{inspect(value)}"}]

      assert message ==
        String.trim("""
        Process #{inspect(pid)} raised an exception
        ** (MatchError) no match of right hand side value: #{inspect(value)}
            test/integration/proc_test.exs:69: anonymous fn/1 in Integration.ProcTest."test crashed with badmatch"/1
        """)

      assert frames ==
        [
          %{filename: "test/integration/proc_test.exs",
            function: "anonymous fn/1 in Integration.ProcTest.\"test crashed with badmatch\"/1",
            lineno: 69, module: Integration.ProcTest, vars: %{}}
        ]
    end
  end
end
