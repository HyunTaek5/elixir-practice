defmodule ElixirPractice.Factory do
  @moduledoc false
  use ExMachina.Ecto, repo: ElixirPractice.Repo

  # This is a sample factory to make sure our setup is working correctly.
  def name_factory(_) do
    Faker.Person.name()
  end
end
