defmodule :"if-then-else-if with boolean schema false-gpt-3.5" do
  def validate(decoded_json) do
    case decoded_json do
      %{"else" => %{"const" => "else"}, "if" => false, "then" => %{"const" => "then"}} ->
        :ok

      %{"type" => "object"} ->
        def validate(object) when is_map(object) do
          :ok
        end

        def validate(_) do
          :error
        end

      _ ->
        :error
    end
  end
end
