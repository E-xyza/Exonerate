defmodule Exonerate.Filter.Const do
  @moduledoc false

  @behaviour Exonerate.Filter

  alias Exonerate.Type
  alias Exonerate.Validator

  @impl true
  def parse(validation = %Validator{}, %{"const" => const}) do
    type = %{Type.of(const) => nil}
    |> IO.inspect(label: "12")

    %{validation | types: Type.intersection(validation.types, type)}
  end

end
