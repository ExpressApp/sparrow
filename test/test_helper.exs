Application.put_env(:sparrow, :client, Sparrow.ClientVoid)
Application.put_env(:sparrow, :dsn, "https://user:pass@localhost/42")

Sparrow.Application.attach_to_logger_handler()

ExUnit.start(capture_log: true)
