defmodule Sparrow.Client do
  @moduledoc false
  @behaviour Sparrow.Client.Behaviour

  @sentry_client "sparrow-elixir/#{Mix.Project.config()[:version]}"
  @sentry_version 7

  def send(%Sparrow.Event{} = event, opts \\ []) do
    with {:ok, endpoint, project, headers} <- get_credentials(opts),
         {:ok, encoded} <- Sparrow.Event.encode(%Sparrow.Event{event | project: project}),
         {:ok, body} <- Sparrow.client().request(endpoint, headers, compress(encoded), []),
         {:ok, json} <- Sparrow.json_library().decode(body)
    do
      {:ok, Map.get(json, "id")}
    else
      {:error, reason} ->
        {:error, reason}
    end
  end

  def request(url, headers, body, opts) do
    case :hackney.request(:post, url, headers, body, opts) do
      {:ok, 200, _, ref} -> :hackney.body(ref)
      {:ok, _, _, _ref} -> {:error, :unexpected_response}
      {:error, reason} -> {:error, reason}
    end
  end

  defp compress(binary) do
    binary |> :zlib.compress() |> Base.encode64()
  end

  defp get_credentials(opts) do
    with {:ok, %Sparrow.DSN{endpoint: endpoint, project: project} = dsn} <- get_dsn(opts) do
      {:ok, endpoint, project, authorization_headers(dsn)}
    end
  end

  defp authorization_headers(%Sparrow.DSN{public: public, secret: secret}) do
    [
      {"User-Agent", @sentry_client},
      {"X-Sentry-Auth", authorization_header(public, secret)}
    ]
  end

  defp authorization_header(public, secret) do
    data = [
      sentry_version: @sentry_version,
      sentry_client: @sentry_client,
      sentry_timestamp: System.system_time(:second),
      sentry_key: public,
      sentry_secret: secret
    ]

    query =
      data
      |> Enum.reject(fn({_, value}) -> value in [nil, ""] end)
      |> Enum.map(fn({name, value}) -> "#{name}=#{value}" end)
      |> Enum.join(", ")

    "Sentry " <> query
  end

  defp get_dsn(opts) do
    Sparrow.DSN.parse(Keyword.get_lazy(opts, :dsn, &Sparrow.dsn/0))
  end
end
