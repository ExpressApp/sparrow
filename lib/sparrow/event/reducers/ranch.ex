defmodule Sparrow.Event.Reducers.Ranch do
  @moduledoc false
  @behaviour Sparrow.Event.Reducer

  # handle formatted messages
  def reduce(%{msg: {:report, %{format: ~c'Ranch listener' ++ _ = _format, args: args}}}, event) do
    ranch_args(event, args)
  end

  # skip cowboy crash reports
  def reduce(%{msg: {:report, %{label: {:proc_lib, :crash}, report: [[{:initial_call, {:cowboy_stream_h, _, _}} | _] = _crashed, _linked]}}}, _event) do
    :skip
  end

  def reduce(_, event) do
    event
  end

  # cowboy 1.x.x

  defp ranch_args(event, [_ref, _protocol, _pid, reason]) do
    ranch_reason(event, reason)
  end

  # cowboy 2.x.x

  defp ranch_args(event, [_ref, _conn_pid, _stream_id, _stream_pid, reason, _ranch_stacktrace]) do
    ranch_reason(event, reason)
  end

  # other ranch events

  defp ranch_args(event, _) do
    event
  end

  # reasons

  defp ranch_reason(event, {reason, {mod, :call, [%{__struct__: Plug.Conn} = conn, _opts]}}) do
    plug_conn(event, reason, mod, conn)
  end

  defp ranch_reason(event, reason) do
    Sparrow.Event.put_error(event, reason)
  end

  # parse conn metadata

  defp plug_conn(event, reason, plug_mod, plug_conn) do
    event
    |> Sparrow.Event.put_error(reason)
    |> Sparrow.Event.put_extra(%{plug: plug_mod})
    |> Sparrow.Event.put_plug_conn(plug_conn)
  end
end
