defmodule Scotty.Alert do
  use Supervisor
  require Logger
@doc """
Alert is the Supervisor for the Alerting part of Scotty.

 Scotty.Alert.start_link('pierrezemb.ovh', 8080, '/api/v0/mobius', "<% NOW %> 2000 EVERY", 2000)

"""

    def start_link(ingress, port, path, warpscript, time_window) do
        result = {:ok, pid} = Supervisor.start_link(__MODULE__, %{ingress: ingress, port: port, path: path, warpscript: warpscript})
        result
    end

    def init(args) do
        children = [
            worker(Scotty.WebSocket, [args, [WS1]], id: 1,restart: :permanent)
        ]
        supervise(children, strategy: :one_for_one)
    end
end