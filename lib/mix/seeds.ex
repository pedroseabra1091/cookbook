defmodule Mix.Tasks.Seeds do
  use Mix.Task

  alias Cookbook.{Chef, Ingredient, Recipe}
  alias Cookbook.Repo

  import Ecto.Changeset

  require IEx

  def run(_) do
    start_repo()

    # creates chefs and the respective restaurants
    create_seeds_for_entire_assoc(Chef, chef_seeds(), :restaurants, restaurant_seeds())

    # creates recipes for the stored chefs
    create_seeds_for_one_to_many_assoc(Chef, chef_seeds(), :recipes, recipe_seeds())

    # creates ingredients for the stored recipes
    create_seeds_for_many_many_assoc(Recipe, recipe_seeds(), :ingredients, ingredient_seeds())
  end

  defp start_repo, do: Mix.Task.run("app.start")

  defp create_seeds_for_entire_assoc(schema, seeds, schema_assoc, assoc_seeds) do
    seeds
    |> Enum.with_index
    |> Enum.each(&(cast_and_insert(&1, schema, schema_assoc, assoc_seeds)))
  end

  defp cast_and_insert({seed, seed_index}, schema, schema_assoc, assoc_seeds) do
    # Builds the map with the associated seeds according to the schema seed index
    # e.g:
    # [%{name: "Henrique Sá Pessoa"} would merge the following restaurant seeds:
    # [%{name: "Alma"}, %{name: "Mercado da Ribeira"}, %{name: "Tapisco"}]
    seed_map = seed |> Map.merge(%{schema_assoc => Enum.at(assoc_seeds, seed_index)})

    # cast_assoc/3 should be used when working with the entire association at once
    schema
    |> struct(seed_map)
    |> cast(seed, ~w(name)a)
    |> validate_required(~w(name)a)
    |> unique_constraint(:name)
    |> cast_assoc(schema_assoc)
    |> Repo.insert!()
  end

  defp create_seeds_for_one_to_many_assoc(schema, seeds, schema_assoc, assoc_seeds) do
    seeds
    |> Enum.with_index
    |> Enum.each(&(put_and_update(&1, schema, schema_assoc, assoc_seeds)))
  end

  defp create_seeds_for_many_many_assoc(schema, seeds, schema_assoc, assoc_seeds) do
    seeds
    |> Enum.each(&(run_through_nested_seed(&1, schema, schema_assoc, assoc_seeds)))
  end

  def run_through_nested_seed(seed, schema, schema_assoc, assoc_seeds) do
    seed
    |> Enum.with_index
    |> Enum.each(&(put_and_update(&1, schema, schema_assoc, assoc_seeds)))
  end

  defp put_and_update({seed, seed_index}, schema, schema_assoc, assoc_seeds) do
    record = Repo.get_by(schema, seed)

    record
    |> Repo.preload(schema_assoc)
    |> change()
    |> put_assoc(schema_assoc, Enum.at(assoc_seeds, seed_index))
    |> Repo.update!()
  end

  defp ingredient_seeds do
    [
      [%{name: "Ground beef"}, %{name: "Pepper"}, %{name: "Onion"}, %{name: "Tomato"}, %{name: "Mozarella"}, %{name: "Noodles"}],
      [%{name: "Rabbit"}, %{name: "Olive oil"}, %{name: "Tomato"}, %{name: "Basil"}, %{name: "Rosemary"}]
    ]
  end

  defp chef_seeds do
    [%{name: "Henrique Sá Pessoa"}, %{name: "José Avillez"}]
  end

  defp restaurant_seeds do
    [
      [%{name: "Alma"}, %{name: "Mercado da Ribeira"}, %{name: "Tapisco"}],
      [%{name: "Cantinho do Avillez"}, %{name: "Bairro do Avillez"}, %{name: "Belcanto"}]
    ]
  end

  defp recipe_seeds do
    [
      [%{
        name: "Rabbit stew",
        steps: [
          "Joint the rabbits into pieces: the shoulders, ribs, loins and hind legs. Season all of the pieces with salt and pepper and lightly dust with a little flour", "Sauté the rabbit pieces all over in a frying pan over a high heat with a little olive oil. When golden-brown, set the rabbit to one side and discard the oil from the pan", "Pour in some more extra virgin olive oil and add the garlic, shallots and chilli. Cook for a few minutes until the shallots are golden", "Place the pieces of rabbit in the pan again and deglaze with the white wine. After about 5 minutes, add the tomatoes and the vegetable stock", "Leave to cook over medium heat for about 20 minutes", "Add the herbs and continue to cook over high heat until you obtain a thick sauce, for about another 30 minutes", "Garnish with basil leaves and sprigs of rosemary and serve"
        ],
        cooking_time: 120,
        portions: 4
      }],
      [%{
        name: "Lasagna",
        steps: [
          "Start by making the sauce with ground beef, bell peppers, onions, and a combo of tomato sauce, tomato paste, and crushed tomatoes. The three kinds of tomatoes gives the sauce great depth of flavor.", "Let this simmer while you boil the noodles and get the cheese ready.", "From there, it’s just an assembly job. A cup of meat sauce, a layer of noodles, more sauce, followed by a layer of cheese. Repeat until you have three layers and have used up all the ingredients.", "Bake until bubbly and you’re ready to eat!"
        ],
        cooking_time: 40,
        portions: 8,
        category: "meat"
    }],
  ]
  end
end