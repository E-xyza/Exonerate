defmodule Benchmark.GPT do
  @openapi_url "https://api.openai.com/v1/chat/completions"

  def prompt(schema, title \\ nil) do
    title = if title, do: ~s(please name the module with the atom `:"#{title}"`)

    """
    Hi, ChatGPT! I would love your help writing an Elixir public function `validate/1`, which takes
    one parameter, which is a decoded JSON value.  The function should return :ok if the following
    jsonschema validates, and an error if it does not:

    ```
    #{schema}
    ```

    The function should NOT store or parse the schema, it should translate the instructions in the schema directly as
    elixir code.  For example:

    ```
    {"type": "object"}
    ```

    should emit the following code:

    ```
    def validate(object) when is_map(object), do: :ok
    def validate(_), do: :error
    ```

    DO NOT STORE THE SCHEMA or EXAMINE THE SCHEMA anywhere in the code.  There should not be any
    `schema` variables anywhere in the code.  #{title}

    Thank you!
    """
  end

  def ensure_cached!(schema, model) do
    model_dir =
      __DIR__
      |> Path.join("../gpt-#{model}")
      |> Path.expand()

    unless File.dir?(model_dir), do: raise("model code directory #{model_dir} doesn't exist!")

    script_file = Path.join(model_dir, "#{escape(schema.description)}.exs")

    unless File.exists?(script_file) do
      raw_code =
        schema.schema
        |> Jason.encode!()
        |> fetch_schema_code!(model)
        |> trim_elixir

      code =
        try do
          raw_code
          |> Code.string_to_quoted!()
          |> strip_module()
          |> into_module(schema.description, model)
          |> Macro.to_string()
        rescue
          _ ->
            # just put the raw code in the template directly.
            code = """
            defmodule :"#{schema.description}" do
              #{raw_code}
            end
            """
        end

      File.write!(script_file, code)
    end

    schema
  end

  @model_ids %{"3.5" => "gpt-3.5-turbo", "4" => "gpt-4"}

  def fetch_schema_code!(schema, model) do
    api_key = System.fetch_env!("CHATGPT_SECRET_KEY")

    payload =
      Jason.encode!(%{
        model: Map.fetch!(@model_ids, model),
        messages: [
          %{
            role: :user,
            content: prompt(schema)
          }
        ]
      })

    %{status: 200, body: body} =
      Req.post!(
        @openapi_url,
        headers: [content_type: "application/json", authorization: "Bearer #{api_key}"],
        body: payload,
        receive_timeout: :infinity
      )

    body
    |> get_in(["choices", Access.at!(0), "message", "content"])
    |> String.split("```")
    |> Enum.at(1)
  end

  defp trim_elixir(string) do
    # the code might have ```elixir at the beginning.
    String.trim_leading(string, "elixir")
  end

  defp strip_module({:defmodule, _, [_, [do: code]]}), do: code
  defp strip_module(code), do: code

  def module_name(description, model), do: :"#{description}-gpt-#{model}"

  defp into_module(code, description, model) do
    module_name = module_name(description, model)

    quote do
      defmodule unquote(module_name) do
        unquote(code)
      end
    end
  end

  defp escape(string) do
    String.replace(string, "/", "-")
  end
end
