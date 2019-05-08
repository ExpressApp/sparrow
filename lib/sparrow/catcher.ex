defmodule Sparrow.Catcher do
  @moduledoc false

  require Logger

  @doc """
  Hook required by Erlang `:logger`, should be fast as possible, because it calls on the client process
  """
  @spec log(:logger.log_event(), config :: map) :: any
  def log(log, config) do
    send(Sparrow.Coordinator, {__MODULE__, log, config})
  end

  def async_log(%{level: _, msg: msg, meta: meta} = log, config) do
    with {{kind, reason, stacktrace, extra}, message} <- reason_stacktrace(msg),
         %Sparrow.Event{} = event <- make_event(kind, reason, stacktrace, extra, message, meta, log),
         _ = maybe_notify(config, event),
         {:ok, id} <- Sparrow.Client.send(event)
    do
      {:ok, id}
    else
      {:error, :invalid_dsn} ->
        Logger.warn("sparrow has invalid DSN configuration")

      any ->
        any
    end

  rescue
    exception ->
      Logger.warn("sparrow caused an exception\n" <>
        Exception.format(:error, exception, System.stacktrace()))

  catch
    kind, value ->
      Logger.warn("sparrow caused an error #{inspect(kind)} #{inspect(value)}\n" <>
        Exception.format_stacktrace(System.stacktrace()))

  end

  defp make_event(kind, reason, stacktrace, extra, message, meta, log) do
    Sparrow.Event.new(meta.time)
    |> Sparrow.Event.put_extra(extra)
    |> Sparrow.Event.put_message(message)
    |> Sparrow.Event.put_exception(kind, reason, stacktrace)
    |> Sparrow.Event.put_stacktrace(stacktrace)
    |> Sparrow.Event.put_fingerprint(kind, reason, meta.pid)
    |> reduce(log)
  end

  defp maybe_notify(%{notify: pid}, %Sparrow.Event{} = event) when is_pid(pid) do
    send(pid, event)
  end

  defp maybe_notify(_config, _event) do
    :skip
  end

  defp reduce(origin_event, log) do
    Enum.reduce_while(Sparrow.event_reducers(), origin_event, fn(reducer, e) ->
      case reducer.reduce(log, e) do
        :skip -> {:halt, :skip}
        event -> {:cont, event}
      end
    end)
  end

  # ...

  defp reason_stacktrace({:string, string}) do
    {{:error, string, [], %{}}, string}
  end

  defp reason_stacktrace({:report, %{label: label, report: report} = complete}) when map_size(complete) == 2 do
    report_format_maybe_translate(
      fn -> report(label, report) end,
      fn -> translate(:report, {label, report}) end
    )
  end

  defp reason_stacktrace({:report, %{label: {:error_logger, _}, format: format, args: args}}) do
    report_format_maybe_translate(
      fn -> format(format, args) end,
      fn -> translate(:format, {format, args}) end
    )
  end

  defp reason_stacktrace({:report, report}) do
    report_format_maybe_translate(
      fn -> report(:logger, report) end,
      fn -> translate(:report, {:logger, report}) end
    )
  end

  defp reason_stacktrace({format, args}) do
    report_format_maybe_translate(
      fn -> format(format, args) end,
      fn -> translate(:format, {format, args}) end
    )
  end

  defp report_format_maybe_translate(report_format_fn, translate_fn) do
    case report_format_fn.() do
      :skip -> :skip
      value -> {value, translate_fn.()}
    end
  end

  # ...

  defp translate(kind, data) do
    %{translators: translators} = Logger.Config.__data__()

    translate(translators, kind, data)
  end

  defp translate([{mod, fun} | t], kind, data) do
    case apply(mod, fun, [:error, :error, kind, data]) do
      {:ok, chardata, _transdata} -> chardata
      {:ok, chardata} -> chardata
      :skip -> nil
      :none -> translate(t, kind, data)
    end
  end

  defp translate([], _kind, _data) do
    nil
  end

  # ...

  defp report(:logger, %{label: label} = report) do
    case label do
      {:gen_server, :terminate} ->
        report_gen_server_terminate(report)

      {:gen_event, :terminate} ->
        report_gen_event_terminate(report)

      _ ->
        :skip
    end
  end

  defp report({:proc_lib, :crash}, data) do
    report_crash(data)
  end

  defp report({:supervisor, :progress}, _data) do
    :skip
  end

  # TODO do we need supervisor child_terminated?
  defp report({:supervisor, _}, _data) do
    :skip
  end

  defp report({:application_controller, :progress}, _data) do
    :skip
  end

  # TODO do we need application exit?
  defp report({:application_controller, :exit}, _data) do
    :skip
  end

  defp format(format, args) do
    reason =
      format
      |> Logger.Utils.scan_inspect(args, 8192)
      |> :io_lib.build_text()
      |> IO.chardata_to_string()

    {:error, reason, [], %{}}
  end

  # ...

  defp report_gen_server_terminate(%{reason: reason} = report) do
    {reason, stacktrace} = Sparrow.format_reason(reason)
    {:exit, reason, stacktrace, Map.take(report, [:name, :state, :last_message])}
  end

  defp report_gen_event_terminate(%{reason: reason} = report) do
    {reason, stacktrace} = Sparrow.format_reason(reason)
    {:exit, reason, stacktrace, Map.take(report, [:name, :state, :last_message])}
  end

  defp report_crash([crashed, _linked]) do
    crashed = Enum.into(crashed, %{})
    {{kind, reason, stacktrace}, extra} = Map.pop(crashed, :error_info)

    {kind, reason, stacktrace, extra}
  end
end
