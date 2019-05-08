defmodule Sparrow.Event do
  @type t :: %Sparrow.Event{}

  @rfc_4122_variant10 2
  @uuid_v4_identifier 4
  @max_message_length 8_192

  defstruct [
    event_id: nil,
    # culprit: nil, # TODO deprecated
    timestamp: nil,
    message: nil,
    tags: %{},
    level: "error",
    platform: "elixir",
    server_name: nil,
    environment: nil,
    exception: nil,
    release: nil,
    stacktrace: %{
      frames: []
    },
    request: %{},
    extra: %{},
    user: %{},
    breadcrumbs: [],
    fingerprint: [],
    modules: %{}
  ]

  def new(unix_timestamp \\ System.system_time(:second)) do
    %__MODULE__{
      event_id: event_id(),
      timestamp: timestamp(unix_timestamp),
      tags: Sparrow.tags(),
      server_name: Sparrow.server_name(),
      environment: Sparrow.environment(),
    }
  end

  def put_extra(event, extra) when is_map(extra) do
    %__MODULE__{event | extra: Map.merge(event.extra, extra)}
  end

  def put_message(event, message) when is_binary(message) do
    %__MODULE__{event | message: message}
  end

  def put_message(event, message) when is_list(message) do
    %__MODULE__{event | message: IO.iodata_to_binary(message)}
  end

  def put_message(event, message) do
    %__MODULE__{event | message: inspect(message)}
  end

  def put_exception(event, kind, exception, stacktrace \\ []) do
    normalize = Exception.normalize(kind, exception, stacktrace)
    exception = [%{type: exception_type(normalize), value: exception_message(kind, normalize)}]

    %__MODULE__{event | exception: exception}
  end

  def put_stacktrace(event, stacktrace) do
    %__MODULE__{event | stacktrace: %{frames: stacktrace_to_frames(stacktrace)}}
  end

  def put_fingerprint(event, _kind, _reason, _pid) do
    # TODO do we need to provide out own fingerprint for every event?
    # %__MODULE__{event | fingerprint: ["{{ default }}", inspect(kind), inspect(reason), inspect(pid)]}
    event
  end

  def put_plug_conn(event, %{__struct__: Plug.Conn} = conn) do
    # TODO extract meta for sentry http interface
    # https://docs.sentry.io/development/sdk-dev/interfaces/http/
    put_extra(event, %{conn: conn})
  end

  def encode(event) do
    event_json =
      event
      |> encode_extra()
      |> truncate_message()
      |> Map.from_struct()
      |> maybe_drop_stacktrace()

    Sparrow.json_library().encode(event_json)
  end

  defp encode_extra(%__MODULE__{extra: extra} = event) do
    %__MODULE__{event | extra: Enum.into(extra, %{}, fn({k, v}) -> {k, inspect(v)} end)}
  end

  defp truncate_message(%__MODULE__{message: message} = event) do
    %__MODULE__{event | message: String.slice(message, 0..@max_message_length)}
  end

  defp maybe_drop_stacktrace(%{stacktrace: %{frames: []}} = event_map) do
    Map.delete(event_map, :stacktrace)
  end

  defp maybe_drop_stacktrace(event_map) do
    event_map
  end

  defp exception_type(%{__struct__: module}) do
    inspect(module)
  end

  defp exception_type(error) do
    inspect(error)
  end

  defp exception_message(_kind, %{__exception__: true} = exception) do
    Exception.message(exception)
  end

  defp exception_message(kind, normalized) do
    kind
    |> Exception.format_banner(normalized)
    |> String.trim("*")
    |> String.trim()
  end

  defp stacktrace_to_frames(stacktrace) do
    Enum.map(stacktrace, fn({mod, function, arity_or_args, location} = line) ->
      arity = arity_to_integer(arity_or_args)
      file = Keyword.get(location, :file)
      file = if(file, do: String.Chars.to_string(file), else: file)
      line_number = Keyword.get(location, :line)

      %{filename: file && to_string(file),
        function: Exception.format_mfa(mod, function, arity),
        module: inspect(mod),
        lineno: line_number,
        vars: args_from_stacktrace([line])}
    end)
    |> Enum.reverse()
  end

  defp args_from_stacktrace([{_m, _f, args, _} | _]) when is_list(args) do
    args
    |> Enum.with_index()
    |> Enum.into(%{}, fn({arg, index}) -> {"arg#{index}", inspect(arg)} end)
  end

  defp args_from_stacktrace(_) do
    %{}
  end

  defp arity_to_integer(arity) when is_list(arity), do: Enum.count(arity)
  defp arity_to_integer(arity) when is_integer(arity), do: arity

  defp timestamp(unix) do
    unix |> DateTime.from_unix!(:microsecond) |> DateTime.to_iso8601() |> String.replace_trailing("Z", "")
  end

  defp event_id do
    <<time_low_mid::48, _version::4, time_high::12, _reserved::2, rest::62>> =
      :crypto.strong_rand_bytes(16)

    <<time_low_mid::48, @uuid_v4_identifier::4, time_high::12, @rfc_4122_variant10::2, rest::62>>
    |> Base.encode16(case: :lower)
  end
end
