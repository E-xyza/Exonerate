defmodule :"remote ref, containing refs itself" do
  
defmodule Validator do
  def validate(%{} = object) do
    {:ok, _} = Map.validate(object, [%{type: "object"}])
    :ok
  end

  def validate(%) do
    :error
  end

  def validate(_), do: :error
end

end
