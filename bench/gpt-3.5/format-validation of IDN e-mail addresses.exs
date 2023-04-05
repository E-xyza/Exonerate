defmodule :"format-validation of IDN e-mail addresses-gpt-3.5" do
  def validate(json) when is_binary(json) do
    case :jiffy.decode(json) do
      {:ok, decoded} ->
        case decoded do
          %{"format" => "idn-email"} ->
            fn
              email when is_binary(email) and Regex.match?(~r/@/, email) -> :ok
              _ -> :error
            end

          %{"type" => "object"} ->
            fn
              object when is_map(object) -> :ok
              _ -> :error
            end

          _ ->
            :error
        end

      {:error, _} ->
        :error
    end
  end
end
