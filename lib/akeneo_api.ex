defmodule AkeneoApi do
  use Application

  def start(_type, _args) do
    children = [
      AkeneoApi.Connection
    ]
    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
