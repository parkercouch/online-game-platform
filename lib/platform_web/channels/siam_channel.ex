defmodule PlatformWeb.SiamChannel do
  use PlatformWeb, :channel

  alias Game.Server, as: Game

  def join("siam:game", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("request_state", _payload, socket) do
    current_state = Game.get_turn()
    current_player = current_state.current_player

    broadcast(socket, "get_state", %{:player => current_player})
    {:noreply, socket}
  end
end