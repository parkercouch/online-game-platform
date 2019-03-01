defmodule Game.Board do
  @moduledoc """
  Game board creation and manipulation
  A board is just a normal map:
  %{{x,y} => {player, direction}}
  example:
  %{{1,1} => {:elephant, :up}} Is an elephant piece at 1,1 facing up

  Possible Pieces:
  :elephant, :rhino, :mountain, :empty

  Possible Directions:
  :up, :down, :left, :right, :neutral
  """

  @doc """
  Create the default starting board
  __,__,__,__,__
  __,__,__,__,__
  __, ⛰, ⛰, ⛰,__
  __,__,__,__,__
  __,__,__,__,__
  """
  def new_board() do
    # Generate empty board
    starting_board =
      for x <- Enum.to_list(1..5), y <- Enum.to_list(1..5), into: %{}, do: {{x, y}, {:empty}}

    # Add starting mountains in middle
    %{
      starting_board
      | {2, 3} => {:mountain, :neutral},
        {3, 3} => {:mountain, :neutral},
        {4, 3} => {:mountain, :neutral}
    }
  end

  @doc """
  Prints board to console. Useful for debugging
  """
  def pretty_print(b) do
    IO.puts("""
    --------------------------
    | #{f(b[{1, 5}])} | #{f(b[{2, 5}])} | #{f(b[{3, 5}])} | #{f(b[{4, 5}])} | #{f(b[{5, 5}])} |
    --------------------------
    | #{f(b[{1, 4}])} | #{f(b[{2, 4}])} | #{f(b[{3, 4}])} | #{f(b[{4, 4}])} | #{f(b[{5, 4}])} |
    --------------------------
    | #{f(b[{1, 3}])} | #{f(b[{2, 3}])} | #{f(b[{3, 3}])} | #{f(b[{4, 3}])} | #{f(b[{5, 3}])} |
    --------------------------
    | #{f(b[{1, 2}])} | #{f(b[{2, 2}])} | #{f(b[{3, 2}])} | #{f(b[{4, 2}])} | #{f(b[{5, 2}])} |
    --------------------------
    | #{f(b[{1, 1}])} | #{f(b[{2, 1}])} | #{f(b[{3, 1}])} | #{f(b[{4, 1}])} | #{f(b[{5, 1}])} |
    --------------------------
    """)
  end

  # Pick emoji for print... just for fun!
  defp f({:empty}), do: "  "

  defp f({player, direction}) do
    direction_symbol =
      case direction do
        :up ->
          "⬆️"

        :down ->
          "⬇️"

        :left ->
          "⬅️"

        :right ->
          "➡️"

        _ ->
          ""
      end

    player_symbol =
      case player do
        :elephant ->
          "🐘"

        :rhino ->
          "🦏"

        :mountain ->
          "⛰️ "

        _ ->
          ""
      end

    "#{player_symbol}#{direction_symbol}"
  end

  @doc """
  Pulls out player info from piece tuple
  """
  def get_player_at({:empty}), do: :empty
  def get_player_at({piece, _}), do: piece

  @doc """
  Pulls out the direction info from a piece
  """
  def get_direction_of({:empty}), do: :neutral
  def get_direction_of({_, direction}), do: direction

  @doc """
  Checks if coordinate is on the
  edge of the board

  {x,y} -> Bool
  """
  def on_edge?({1, _y}), do: true 
  def on_edge?({5, _y}), do: true 
  def on_edge?({_x, 1}), do: true 
  def on_edge?({_x, 5}), do: true 
  def on_edge?(_), do: false

  @doc """
  Checks if coordinate is on a corner
  
  {x, y} -> Bool
  """
  def on_corner?({1, 1}), do: true
  def on_corner?({1, 5}), do: true
  def on_corner?({5, 1}), do: true
  def on_corner?({5, 5}), do: true
  def on_corner?(_), do: false

  @doc """
  Checks if two coordinates are within 1 space
  and not diagonal

  {x, y}, {x, y} -> Bool
  """
  def is_orthogonal?({x1, y1}, {x2, y2}) do
    delta_x = delta(x1, x2)
    delta_y = delta(y1, y2)
    delta_x + delta_y < 2
  end

  defp delta(a, b) when a >= b, do: a - b
  defp delta(a, b) when a < b, do: b - a

  @doc """
  Moves a piece from one location to another
  This assumes the end location is empty

  board, {x,y}, {x,y} -> board
  """
  def move_piece(board, start, target) do
    %{board | target => board[start], start => {:empty}}
  end

  @doc """
  Checks if location is in front of piece

  board, {x, y}, {x, y} -> Bool 
  """
  def is_in_front?(board, selected, target) do
    direction = get_direction_of(board[selected])
    in_front_helper(direction, selected, target)
  end

  defp in_front_helper(:up, {x1, y1}, {x2, y2}), do: x1 == x2 and y2 - y1 == 1
  defp in_front_helper(:down, {x1, y1}, {x2, y2}), do: x1 == x2 and y1 - y2 == 1
  defp in_front_helper(:left, {x1, y1}, {x2, y2}), do: y1 == y2 and x1 - x2 == 1
  defp in_front_helper(:right, {x1, y1}, {x2, y2}), do: y1 == y2 and x2 - x1 == 1

  @doc """
  Takes a board and index and returns a row

  Row is left to right
  Index 0 -> x: 1
  [{:empty}, {:mountain, :neutral},...]
  """
  def get_row(board, index) do
    board
    |> Map.to_list()
    |> Stream.filter(fn {{_x, y}, _piece} -> y == index end)
    |> Enum.map(fn {_, piece} -> piece end)
  end

  @doc """
  Takes a board and index and returns a column

  Column is bottom to top
  Index 0 -> y: 1
  [{:empty}, {:mountain, :neutral},...]
  """
  def get_column(board, index) do
    board
    |> Map.to_list()
    |> Stream.filter(fn {{x, _y}, _piece} -> x == index end)
    |> Enum.map(fn {_coord, piece} -> piece end)
  end

  @doc """
  Assign push strength

  Pass in direction and a tuple of modifiers is returned
  Mountains are -0.67 for x and y
  2 mountains = -1.34
  3 mountains = -2.01
  (Rounding errors would be an issue if we needed more mountains,
  but only 3 can exist in this game)
  This is because mountains require one pusher to move
  per mountain, but it doesn't count as a pusher itself
  Using an round number instead would make things tie and not push
  """
  def get_push_strength({_, :up}), do: {0, 1}
  def get_push_strength({_, :down}), do: {0, -1}
  def get_push_strength({_, :left}), do: {-1, 0}
  def get_push_strength({_, :right}), do: {1, 0}
  def get_push_strength({_, :neutral}), do: {-0.67, -0.67}

  @doc """
  Takes a list that has the pusher str as head
  And the rest of the pieces str as tail

  [1, 0, -0.67, -1] -> False
  1 > 1.67 -> False
  """
  def calculate_push([pusher_str | rest_str]) do
    sum_of_rest = Enum.sum(rest_str)
    abs(pusher_str) > abs(sum_of_rest)
  end

  @doc """
  Gets all pieces involved in current push
  Takes a list with pusher as head and the rest of the row as tail
  Returns a list with pusher at head and only involved pieces as tail

  [1, 0, -0.67, :empty, -1] -> [1, 0, -0.67]
  """
  def get_involved_pieces(pieces) do
    List.foldr(pieces, [], 
      fn piece, acc ->
        case piece do
          {:empty} -> []
          _ -> [piece | acc]
        end
      end)
  end

  @doc """
  Changes general push str to specific direction only
  """
  def applicable_str(pieces = [pusher | rest]) do
    case pusher do
      {0, _} ->
        Enum.map(pieces, &(elem(&1, 2)))
      {_, 0} ->
        Enum.map(pieces, &(elem(&1, 1)))
    end
  end

  @doc """
  Drops pieces behind the pusher from the list
  """
  def remove_pieces_behind(pieces, pusher) do
    List.drop(pieces, pusher)
  end

  @doc """
  Pass in pusher and board and it will calculate if
  the push is valid
  """
  def is_pushable?(board, pusher_coords) do
    pusher_direction = get_direction_of(pusher_coords)
    board
    |> get_row(1)
    |> get_involved_pieces()
    |> Enum.map(&(get_push_strength(&1)))
    |> applicable_str()
    |> calculate_push()

  end


end
