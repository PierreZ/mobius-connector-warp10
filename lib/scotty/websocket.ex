defmodule Scotty.WebSocket do
    use GenServer
    require Logger

    ## Client API

    @doc """
    Initiates a new WebSocket GenServer (or Process)
    
    Init the websocket with Gun. It's an erlang project, 
    but there's no good ws library in Elixir with active conn ;) 

    To start:
    
    {:ok, pid} = Scotty.WebSocket.start_link('pierrezemb.ovh', 8080, '/api/v0/mobius', "<% NOW %> 2000 EVERY")
    """
    def start_link(args, opts) do
        Logger.debug("Starting a WS")
        GenServer.start_link(__MODULE__, args, opts)
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
                {:ok, conn}
        end
    end

    ## Server callbacks
    
    @doc """
    Response from Mobius
    http://ninenines.eu/docs/en/gun/1.0/guide/websocket/
    """
    def handle_info({:gun_ws, _, frame}, state) do
        Logger.debug(elem(frame, 1))
        ## Todo: forward frame to a Queue
        {:noreply, state}
    end

    @doc """
    Handler for the "gun_response" event
    """
    def handle_info({:gun_response, _, _, _, status, _}, state) do
        Logger.error("The server does not understand Websocket or refused the upgrade")
        {:stop, status, state}
    end

    @doc """
    Handler for the "gun_down" event
    """
    def handle_info({:gun_down, _, _, reason, _, _}, state) do
        Logger.error("Error using Gun")
        {:stop, reason, state}
    end

    @doc """
    Handler for the "gun_error" event
    """
    def handle_info({:gun_error, _, _, reason}, state) do
        Logger.error("Error using Gun")
        {:stop, reason, state}
    end
end