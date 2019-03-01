defmodule Game.ServerTest do
  use ExUnit.Case
  doctest Game.Server

  test "Start Game Server" do
    {:ok, pid_one} = Game.Server.start()
    {:ok, pid_two} = Game.Server.start()

    assert pid_one != nil
    assert pid_one != pid_two
  end

  test "No Undo turn on first turn" do
    {:ok, pid} = Game.Server.start()
    {response, _message} = Game.Server.undo_turn(pid)

    assert response == :error
  end
end
