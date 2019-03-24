defmodule Game.BoardTest do
  use ExUnit.Case
  doctest Game.Board

  alias Game.Board, as: Board

  test "On edge of board" do
    assert Board.on_edge?({1, 1}) == true
    assert Board.on_edge?({1, 2}) == true
    assert Board.on_edge?({1, 3}) == true
    assert Board.on_edge?({1, 4}) == true
    assert Board.on_edge?({1, 5}) == true
    assert Board.on_edge?({2, 1}) == true
    assert Board.on_edge?({2, 2}) == false
    assert Board.on_edge?({2, 3}) == false
    assert Board.on_edge?({2, 4}) == false
    assert Board.on_edge?({2, 5}) == true
    assert Board.on_edge?({3, 1}) == true
    assert Board.on_edge?({3, 2}) == false
    assert Board.on_edge?({3, 3}) == false
    assert Board.on_edge?({3, 4}) == false
    assert Board.on_edge?({4, 5}) == true
    assert Board.on_edge?({4, 1}) == true
    assert Board.on_edge?({4, 2}) == false
    assert Board.on_edge?({4, 3}) == false
    assert Board.on_edge?({4, 4}) == false
    assert Board.on_edge?({4, 5}) == true
    assert Board.on_edge?({5, 1}) == true
    assert Board.on_edge?({5, 2}) == true
    assert Board.on_edge?({5, 3}) == true
    assert Board.on_edge?({5, 4}) == true
    assert Board.on_edge?({5, 5}) == true
  end

  test "Get player from piece tuple" do
    board = Board.new_board()
    board = %{board | {1,1} => {:elephant, :up}, {1, 2} => {:rhino, :down}}
    elephant = Board.get_player_at(board[{1,1}])
    rhino = Board.get_player_at(board[{1,2}])
    mountain = Board.get_player_at(board[{3,3}])
    empty = Board.get_player_at(board[{5,5}])

    assert elephant == :elephant
    assert rhino == :rhino
    assert mountain == :mountain
    assert empty == :empty
  end

  test "If orthogonal" do
    center = {2, 2}
    up = {2, 3}
    down = {2, 1}
    left = {1, 2}
    right = {3, 2}
    diagonal = {3, 3}
    far_away_y = {2, 5}
    far_away_x = {5, 2}

    assert Board.is_orthogonal?(center, up) == true
    assert Board.is_orthogonal?(center, down) == true
    assert Board.is_orthogonal?(center, left) == true
    assert Board.is_orthogonal?(center, right) == true
    assert Board.is_orthogonal?(center, diagonal) == false
    assert Board.is_orthogonal?(center, far_away_y) == false
    assert Board.is_orthogonal?(center, far_away_x) == false
  end

  test "Is in front?" do
    board = Board.new_board()
    board = %{board |
      {2, 2} => {:elephant, :right},
      {2, 4} => {:rhino, :up},
      {4, 2} => {:elephant, :down},
      {4, 4} => {:rhino, :left},
    }

    # up
    assert Board.is_in_front?(board, {2, 2}, {2, 3}) == false
    # down
    assert Board.is_in_front?(board, {2, 2}, {2, 1}) == false
    # left
    assert Board.is_in_front?(board, {2, 2}, {1, 2}) == false
    # right
    assert Board.is_in_front?(board, {2, 2}, {3, 2}) == true
    # somewhere else
    assert Board.is_in_front?(board, {2, 2}, {3, 1}) == false

    # up
    assert Board.is_in_front?(board, {2, 4}, {2, 5}) == true
    # down
    assert Board.is_in_front?(board, {2, 4}, {2, 3}) == false
    # left
    assert Board.is_in_front?(board, {2, 4}, {1, 4}) == false
    # right
    assert Board.is_in_front?(board, {2, 4}, {3, 4}) == false
    # somewhere else
    assert Board.is_in_front?(board, {2, 4}, {3, 3}) == false

    # up
    assert Board.is_in_front?(board, {4, 2}, {4, 3}) == false
    # down
    assert Board.is_in_front?(board, {4, 2}, {4, 1}) == true
    # left
    assert Board.is_in_front?(board, {4, 2}, {3, 2}) == false
    # right
    assert Board.is_in_front?(board, {4, 2}, {5, 2}) == false
    # somewhere else
    assert Board.is_in_front?(board, {4, 2}, {3, 1}) == false

    # up
    assert Board.is_in_front?(board, {4, 4}, {4, 5}) == false
    # down
    assert Board.is_in_front?(board, {4, 4}, {4, 3}) == false
    # left
    assert Board.is_in_front?(board, {4, 4}, {3, 4}) == true
    # right
    assert Board.is_in_front?(board, {4, 4}, {5, 4}) == false
    # somewhere else
    assert Board.is_in_front?(board, {4, 4}, {3, 3}) == false
  end

  test "Get specified row" do
    board = Board.new_board()
    board = %{board | {1, 3} => {:elephant, :up}}

    [one, two, three, four, five] = Board.get_row(board, 3)

    assert one == {:elephant, :up}
    assert two == {:mountain, :neutral}
    assert three == {:mountain, :neutral}
    assert four == {:mountain, :neutral}
    assert five == {:empty}
  end

  test "Get specified column" do
    board = Board.new_board()
    board = %{board | {3, 1} => {:elephant, :up}}

    [one, two, three, four, five] = Board.get_column(board, 3)

    assert one == {:elephant, :up}
    assert two == {:empty}
    assert three == {:mountain, :neutral}
    assert four == {:empty}
    assert five == {:empty}
  end

  test "Get pieces involved in push" do
    row = [{:elephant, :right}, {:mountain, :neutral}, {:rhino, :up}, {:empty}, {:rhino, :left}]
    assert Board.get_involved_pieces(row) == [{:elephant, :right}, {:mountain, :neutral}, {:rhino, :up}]
  end
end
