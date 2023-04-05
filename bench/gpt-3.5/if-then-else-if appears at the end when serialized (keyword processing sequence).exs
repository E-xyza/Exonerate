defmodule :"if-then-else-if appears at the end when serialized (keyword processing sequence)-gpt-3.5" do
  def validate(object) when is_map(object) do
    case object do
      %{
        "else" => %{"const" => "other"},
        "if" => %{"maxLength" => 4},
        "then" => %{"const" => "yes"}
      } ->
        :ok

      _ ->
        :error
    end
  end

  def validate(_) do
    :error
  end
end
