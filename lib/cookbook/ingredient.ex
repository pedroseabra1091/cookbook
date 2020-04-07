defmodule Cookbook.Ingredient do
  use Ecto.Schema

  schema "ingredients" do
    field :name, :string

    many_to_many :recipes, Cookbook.Recipe, join_through: "recipe_ingredients"

    timestamps()
  end
end