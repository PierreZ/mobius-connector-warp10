defmodule Scotty.WebSocket do
    use GenServer

    @doc "Start a new websocket"
    def handle_cast({:new, ingress, isSecure, path, warpscript}, _state) do

        socket = Socket.Web.connect!(ingress, secure: isSecure, path: path)
        socket |> Socket.Web.send!({ :text, warpscript })
        socket |> Socket.Web.recv!()
    end
end