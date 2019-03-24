defmodule Game.LogicTest do
  use ExUnit.Case
  doctest Game.Logic

  alias Game.Server, as: Server
  alias Game.Logic, as: Logic
  alias Game.Board, as: Board

  test "Select Bullpen" do
    {:ok, pid} = Server.start()
    
    {_, %{selected: selected, bullpen: bullpen}} = Server.move(pid, {:elephant, :select, :bullpen})
    [turn | []] = Server.get_state(pid)

    assert bullpen[:elephant] == 5
    assert selected == :bullpen
    assert turn.selected == :bullpen
  end

  test "Selecting a non-valid piece" do
    {:ok, pid} = Server.start()
    
    # Make sure server rejects selecting an empty square
    {type, _message} = Server.move(pid, {:elephant, :select, {1, 1}})
    assert type == :not_valid

    # There should be no selections
    [turn | []] = Server.get_state(pid)
    assert turn.selected == nil

    # Make sure server rejects selecting a mountain
    {type, _message} = Server.move(pid, {:elephant, :select, {3, 3}})
    assert type == :not_valid

    # There should be no selection
    [turn | []] = Server.get_state(pid)
    assert turn.selected == nil
  end

  test "Trying to issue a move as the wrong player" do
    {:ok, pid} = Server.start()
    current_turn = Server.get_turn(pid)
    {type, _message} = Logic.process_move({:rhino, :select, :bullpen}, current_turn)
    assert type == :not_valid
  end

  test "Trying to target before selecting" do
    {:ok, pid} = Server.start()
    current_turn = Server.get_turn(pid)
    {type, _message} = Logic.process_move({:elephant, :target, {1, 1}}, current_turn)
    assert type == :not_valid
  end

  test "Withdraw piece" do
    {:ok, [current_turn]} = Server.init(1)

    %{board: board, bullpen: bullpen} = current_turn
    current_turn = %{current_turn |
      board: %{board | {1,1} => {:elephant, :up}, {4,4} => {:rhino, :down}},
      bullpen: %{bullpen | elephant: 4, rhino: 4},
    }

    {:continue, updated_turn} = Logic.process_move({:elephant, :select, {1, 1}}, current_turn)
    assert updated_turn.selected == {1, 1}
    {:next, updated_turn, next_turn} = Logic.process_move({:elephant, :target, :bullpen}, updated_turn)
    assert updated_turn.targeted == :bullpen
    assert updated_turn.action == {:withdraw}
    assert next_turn.board[{1, 1}] == {:empty}
    assert next_turn.bullpen[:elephant] == 5

    # Board.pretty_print(updated_turn.board)
    # Board.pretty_print(next_turn.board)

    rhino_turn = %{current_turn | current_player: :rhino}
    {:continue, updated_turn} = Logic.process_move({:rhino, :select, {4, 4}}, rhino_turn)
    assert updated_turn.selected == {4, 4}
    {type, _} = response = Logic.process_move({:elephant, :target, :bullpen}, updated_turn)
    assert type = :not_valid
  end

  test "Move to empty square" do

  end

  test "Move Elephant to Board" do
    {:ok, pid} = Server.start()

    moves = [
      {:elephant, :select, :bullpen},
      {:elephant, :target, {1, 1}},
      {:elephant, :finalize, {:rotate, :up}}
    ]

    Enum.map(
      moves,
      &Server.move(pid, &1)
    )

    state = Server.get_state(pid)
    # IO.inspect(state)
    [next_turn | first_turn] = state

    assert first_turn.board[{1, 1}] == {:empty}
    assert first_turn.current_player == :elephant
    assert first_turn.bullpen[:elephant] == 5
    assert first_turn.turn_number == 0
    assert next_turn.selected == :bullpen
    assert next_turn.targeted == {1, 1}
    assert next_turn.action == {:rotate, :up}

    assert next_turn.board[{1, 1}] == {:elephant, :up}
    assert next_turn.current_player == :rhino
    assert next_turn.bullpen[:elephant] == 4
    assert next_turn.turn_number == 1
    assert next_turn.selected == nil
    assert next_turn.targeted == nil
    assert next_turn.action == nil
  end
end
