defmodule Scotty.Alert do
  use Supervisor
  require Logger
@doc """
Alert is the Supervisor for the Alerting part of Scotty.

It'll spawn 2 websockets and watch over them.

Why 2? To be sure to not miss any alerts. 
For example, our warpscript is checking if in a time-window of one minute, we have a peak.
By starting the second one 30sec after the first, we are sure that in case of a ws error,
we won't forget something

 Scotty.Alert.start_link('pierrezemb.ovh', 8080, '/api/v0/mobius', "<% NOW %> 2000 EVERY", 2000)

"""

    def start_link(ingress, port, path, warpscript, time_window) do
        result = {:ok, pid} = Supervisor.start_link(__MODULE__, %{ingress: ingress, port: port, path: path, warpscript: warpscript})

        beam_second_ws(pid, %{ingress: ingress, port: port, path: path, warpscript: warpscript}, time_window)
        result
    end

    def init(args) do
        children = [
            worker(Scotty.WebSocket, [args, [WS1]], id: 1,restart: :permanent)
        ]
        supervise(children, strategy: :one_for_one)
    end

    defp beam_second_ws(sup, args, time_window) do
        Process.sleep(div(time_window, 2))
        Supervisor.start_child(sup, worker(Scotty.WebSocket, [args, [WS2]], id: 2,restart: :permanent))
    end
end