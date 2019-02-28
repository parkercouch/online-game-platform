defmodule Platform.Products.Gameplay do
  use Ecto.Schema
  import Ecto.Changeset


  schema "gameplays" do
    field :player_score, :integer
    field :game_id, :id
    field :player_id, :id

    timestamps()
  end

  @doc false
  def changeset(gameplay, attrs) do
    gameplay
    |> cast(attrs, [:player_score])
    |> validate_required([:player_score])
  end
end
