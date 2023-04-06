defmodule :"if-then-else-ignore then without if-gpt-3.5" do
  def validate(object) when is_map(object) do
    if Map.get(object, "then", nil) != nil do
      if Map.get(object, "const", nil) == 0 do
        :ok
      else
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