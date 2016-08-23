defmodule Scotty.WebSocket do
    use GenServer
    require Logger

    ## Client API

    @doc """
    Initiates a new WebSocket GenServer (or Process)
    
    Init the websocket with Gun. It's an erlang project, 
    but there's no good ws library in Elixir with active conn ;) 

    To start:
    
    {:ok, pid} = Scotty.WebSocket.start_link('pierrezemb.ovh', 8080, '/api/v0/mobius', '<% NOW %> 2000 EVERY')
    """
    def start_link(ingress, port, path, warpscript) do
        Logger.debug("start_link")
        GenServer.start_link(__MODULE__, %{ingress: ingress, port: port, path: path, warpscript: warpscript}, name: __MODULE__)
    end

    @doc """
    Init is call by GenServer.start_link
    """
    def init(args) do
        {:ok, conn}  = :gun.open(args.ingress, args.port)
        {:ok, :http} = :gun.await_up(conn)
        Logger.debug "upgrading http to ws"
        :gun.ws_upgrade(conn, args.path)
        receive do
            {:gun_ws_upgrade, conn, :ok, _} ->
                Logger.debug "ws is ready"
                :gun.ws_send(conn, {:text, args.warpscript}) ## Sending warpscript
                Logger.debug "ec2 send"
                {:ok, conn}
        end
    end

    ## Server callbacks
    
    @doc """
    Handler for the "gun_ws_upgrade"
    """
    def handle_info({:gun_ws_upgrade, conn, :ok, _}, _state) do
        Logger.debug ":gun_ws_upgrade received"
        {:noreply, conn}
    end

    @doc """
    Handler for the "ws_down" event
    """
    def handle_info({:gun_down, conn, _, _, _, _}, _state) do
        Logger.debug ":gun_down received"
        {:noreply, conn}
    end

    @doc """
    Handler for the ":shutdown" event
    """
    def handle_info(:shutdown, state) do
        Logger.debug(":shutdown received")
        {:noreply, state}        
    end

    @doc """
    Handler for the "gun_response" event
    """
    def handle_info({:gun_response, _, _, _, _, _}, state) do
        Logger.debug("The server does not understand Websocket or refused the upgrade")
        {:noreply, state}
    end

    @doc """
    Handler for the "gun_error" event
    """
    def handle_info({:gun_error, _, _, _}, state) do
        Logger.debug("Error using Gun")
        {:noreply, state}
    end

    @doc """
    Handler for the "gun_ws" event
    """
    def handle_info({:send, data}, state) do
        Logger.debug(data)
        {:noreply, state}
    end
end