defmodule :"prefixItems with no additional items allowed-gpt-3.5" do
  def validate(object) when is_map(object) and map_size(object) == 2 do
    if Map.has_key?(object, "items") and not Map.has_key?(object, "additionalItems") do
      case object["items"] do
        false ->
          :ok

        [subschema | _rest] ->
          if validate(subschema) == :ok do
            :ok
          else
            :error
          end

        [] ->
          if not Map.has_key?(object, "prefixItems") do
            :ok
          else
            case object["prefixItems"] do
              [] ->
                :ok

              [subschema | _rest] ->
                if validate(subschema) == :ok do
                  :ok
                else
                  :error
                end
            end
          end

        _ ->
          :error
      end
    else
      :error
    end
  end

  def validate(_) do
    :error
  end
end
