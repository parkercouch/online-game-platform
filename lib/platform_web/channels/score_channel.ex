defmodule PlatformWeb.ScoreChannel do
  use PlatformWeb, :channel

  def join("score:platformer", _payload, socket) do
    {:ok, socket}
  end

  def handle_in("broadcast_score", payload, socket) do
    IO.inspect(payload)
    broadcast(socket, "broadcast_score_to_all", payload)
    {:noreply, socket}
  end
end