defmodule Scotty.WebSocket do
    use GenServer
    require Logger

    ## Client API

    @doc """
    Initiates a new WebSocket GenServer (or Process)
    
    To start it:

    Scotty.WebSocket.start_link("pierrezemb.ovh:8080", false, "api/v0/mobius","21 2 *", 1)
    or 
    Scotty.WebSocket.init("pierrezemb.ovh:8080", false, "api/v0/mobius","21 2 *", 1)
    ?
    
    """
    def start_link(ingress, isSecure, path, warpscript, time) do
        GenServer.start_link(__MODULE__, {ingress, isSecure, path, warpscript, time}, name: __MODULE__)
    end

    @doc """
    Init is call by GenServer.start_link
    """
    def init(ingress, isSecure, path, warpscript, time) do

        schedule_ws(ingress, isSecure, path, warpscript, time)
    end

    ## Thanks to https://stackoverflow.com/questions/32085258/how-to-run-some-code-every-few-hours-in-phoenix-framework
    defp schedule_ws(ingress, isSecure, path, warpscript, time) do
        Process.send_after(self(), {:start, ingress, isSecure, path, warpscript, time}, time * 60 * 1000) # In time minutes
    end

    ## Server Callbacks

    @doc """
    This callback is actually starting the websocket connection
    """
    def handle_info({:start, ingress, isSecure, path, warpscript, time}, state) do

        Logger.debug "handle_info"

        socket = Socket.Web.connect!(ingress, secure: isSecure, path: path)
        socket |> Socket.Web.send!({ :text, warpscript })
        socket |> Socket.Web.recv!() |> Logger.debug 
        
        schedule_ws(ingress, isSecure, path, warpscript, time) # Reschedule once more
        {:noreply, state}
    end
end