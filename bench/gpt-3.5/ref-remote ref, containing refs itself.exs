defmodule :"ref-remote ref, containing refs itself-gpt-3.5" do
  @spec validate(term) :: :ok | :error
  def validate(object) do
    case %{"$ref" => "https://json-schema.org/draft/2020-12/schema", "type" => "object"} do
      %{"$ref" => "https://json-schema.org/draft/2020-12/schema"} ->
        case %{"$ref" => "#/$defs/object", "$defs" => %{"object" => %{"type" => "object"}}} do
          %{"$ref" => "#/$defs/object"} ->
            case %{"$ref" => "#/$defs/object", "type" => "object"} do
              %{"$ref" => "#/$defs/object"} ->
                def validate(object) when is_map(object) do
                  :ok
                end

                def validate(_) do
                  :error
                end

              _ ->
                :error
            end

          _ ->
            :error
        end

      _ ->
        :error
    end
  end
end