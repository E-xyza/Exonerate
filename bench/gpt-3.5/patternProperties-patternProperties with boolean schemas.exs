defmodule :"patternProperties with boolean schemas" do
  
defmodule :"patternProperties-patternProperties with boolean schemas" do
  def validate(object) when is_map(object) do
    for {pattern, valid} <- object, regex = Regex.compile("^#{pattern}$") do
      for {key, value} <- object do
        if Regex.match?(regex, key) do
          if valid == true and not(is_map(value)) do
            return :error
          elsif valid == false and is_map(value) do
            return :error
          end
        end
      end
    end
    :ok
  end
  def validate(_), do: :error
end

end
