defmodule :"minProperties validation-gpt-3.5" do
  def validate(object) when is_map(object) do
    :ok
  end

  def validate(_) do
    :error
  end

  def validate_schema(%{"minProperties" => num}) do
    fn object ->
      if Map.size(object) >= num do
        :ok
      else
        :error
      end
    end
  end

  def validate_schema(_) do
    fn _ -> :ok end
  end
end
