defmodule :"oneOf-oneOf with boolean schemas, all true-gpt-3.5" do
  defmodule MySchemaModule do
    def validate(true) do
      :ok
    end

    def validate(_) do
      :error
    end
  end

  defmodule MyModule do
    def validate(decoded_json) do
      case decoded_json do
        %{"oneOf" => [true, true, true]} -> MySchemaModule.validate(true)
        _ -> MySchemaModule.validate(false)
      end
    end
  end
end
