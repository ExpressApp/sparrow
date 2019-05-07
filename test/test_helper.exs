Application.put_env(:sparrow, :client, Sparrow.ClientMock)
Application.put_env(:sparrow, :dsn, "https://user:pass@localhost/42")

ExUnit.start(capture_log: true)
