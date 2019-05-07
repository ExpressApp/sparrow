defmodule Sparrow.Client do
  @moduledoc false
  @behaviour Sparrow.Client.Behaviour

  @version Mix.Project.config()[:version]

  @sentry_client "sparrow-elixir/#{@version}"
  @sentry_version 7

  def send(%Sparrow.Event{} = event) do
    with {:ok, endpoint, headers} <- get_headers_and_endpoint(),
         {:ok, encoded} <- Sparrow.Event.encode(event),
         {:ok, body} <- Sparrow.client().request(endpoint, headers, encoded, []),
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

  defp get_headers_and_endpoint do
    with {:ok, endpoint, public, secret} <- get_dsn() do
      {:ok, endpoint, authorization_headers(public, secret)}
    end
  end

  defp authorization_headers(public, secret) do
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
      |> Enum.map(fn({name, value}) -> "#{name}=#{value}" end)
      |> Enum.join(", ")

    "Sentry " <> query
  end

  def get_dsn do
    dsn = Sparrow.dsn()

    with {:ok, %{userinfo: userinfo, host: host, port: port, path: path, scheme: scheme}} <- parse_dsn(dsn),
         {:ok, public, secret} <- split_keys(userinfo)
    do
      {:ok, "#{scheme}://#{host}:#{port}/api/#{parse_project(path)}/store/", public, secret}
    end
  end

  defp parse_dsn(val) when val in [nil, ""] do
    {:error, :invalid_dsn}
  end

  defp parse_dsn(dsn) do
    case URI.parse(dsn) do
      %URI{userinfo: userinfo, path: path} = uri when is_binary(path) and is_binary(userinfo) ->
        {:ok, uri}

      %URI{} ->
        {:error, :invalid_dsn}
    end
  end

  defp parse_project(path) do
    path |> String.replace_prefix("/", "")
  end

  defp split_keys(userinfo) do
    case String.split(userinfo, ":", parts: 2) do
      [public, secret] -> {:ok, public, secret}
      [public] -> {:ok, public, nil}
      _ -> {:error, :invalid_dsn}
    end
  end
end
