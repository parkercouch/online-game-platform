defmodule Game.Server do
  @moduledoc """
  GameServer for Siam.
  """
  use GenServer

  alias Game.Logic, as: Logic
  alias Game.Board, as: Board

  @doc """
  Start Game Server Process
  """
  def start do
    GenServer.start(Game.Server, nil)
  end

  @doc """
  Send player move to be processed
  In the form of:
  {player, action, location/direction}
  {:elephant, :select, {1,2}} -- Select the piece at 1,2

  Returns {:ok, new_state} or {:error, message}
  """
  def move(pid, move_data) do
    GenServer.call(pid, {:move, move_data})
  end

  @doc """
  Reset actions on current turn
  """
  def undo_move(pid) do
    GenServer.call(pid, {:undo_move})
  end

  @doc """
  Go back to previous turn
  Current turn in progress is removed
  Last turn becomes current
  All actions in previous (now current) turn
  are reset

  Error is returned on first turn
  """
  def undo_turn(pid) do
    GenServer.call(pid, {:undo_turn})
  end

  @doc """
  Get current turn data
  """
  def get_turn(pid) do
    GenServer.call(pid, {:get_turn})
  end

  @doc """
  Get entire game state (and history)
  """
  def get_state(pid) do
    GenServer.call(pid, {:get_state})
  end

  def init(_) do
    starting_state = %{
      board: Board.new_board(),
      bullpen: %{elephant: 5, rhino: 5},
      current_player: :elephant,
      turn_number: 0,
      winner: nil,
      selected: nil,
      targeted: nil,
      action: nil,
    }

    {:ok, [starting_state]}
  end

  def handle_call({:move, move_data}, _, [current_turn | previous_turns] = state) do
    case Logic.process_move(move_data, current_turn) do
      {:continue, updated_turn} = response ->
        {:reply, response, [updated_turn | previous_turns]}

      {:not_valid, _message} = response ->
        {:reply, response, state}

      {:next, updated_turn, next_turn} ->
        updated_state = [next_turn | [updated_turn | previous_turns]]
        {:reply, {:next, updated_turn, next_turn}, updated_state}

      {:win, updated_turn, final_turn} ->
        updated_state = [final_turn | [updated_turn | previous_turns]]
        {:reply, {:win, updated_turn, final_turn}, updated_state}
    end
  end

  # Return current turn of state
  def handle_call({:get_turn}, _, [current_turn | _previous_turns] = state) do
    {:reply, current_turn, state}
  end

  # Return state
  def handle_call({:get_state}, _, state) do
    {:reply, state, state}
  end

  # Remove actions from current turn
  def handle_call({:undo_move}, _, [current_turn | previous_turns]) do
    updated_turn = %{current_turn | selected: nil, targeted: nil, action: nil}
    {:reply, {:ok, updated_turn}, [updated_turn | previous_turns]}
  end

  # Remove current turn and actions from prev turn
  def handle_call({:undo_turn}, _, [first_turn | []] = state) do
    {:reply, {:error, "Can't undo on first turn!"}, state}
  end

  def handle_call({:undo_turn}, _, [_current_turn | [prev_turn | tail]]) do
    prev_turn = %{prev_turn | selected: nil, targeted: nil, action: nil}
    updated_state = [prev_turn | tail]
    {:reply, {:ok, updated_state}, updated_state}
  end
end
