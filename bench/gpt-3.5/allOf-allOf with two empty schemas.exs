defmodule :"allOf-allOf with two empty schemas-gpt-3.5" do
  defmodule MyValidator do
    def validate(%{}) do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  def validate(json) do
    case json do
      %{"allOf" => [_, _]} -> MyValidator.validate(%{})
      %{"type" => "object"} -> MyValidator.validate(%{})
      _ -> :error
    end
  end
end
