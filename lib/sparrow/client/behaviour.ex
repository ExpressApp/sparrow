defmodule Sparrow.Client.Behaviour do
  @callback request(url :: String.t, headers :: Enum.t, body, opts :: Keyword.t)
    :: {:ok, body} | {:error, term}
      when body: String.t
end
