defmodule Exonerate do

  @type json ::
     %{optional(String.t) => json}
     | list(json)
     | String.t
     | number
     | boolean
     | nil

  @type mismatch :: {:mismatch, {module, atom, [json]}}

  @moduledoc """
    creates the defschema macro.
  """

  alias Exonerate.Annotate
  alias Exonerate.Parser

  defmacro defschema([{method, json} | _opts]) do
    text_json = maybe_desigil(json)
    spec = Jason.decode!(text_json)

    final_ast = method
    |> Parser.root
    |> Parser.build_requested(spec)
    |> Annotate.public
    |> Parser.defp_to_def

    docstr = """
    Matches JSONSchema:
    ```
    #{text_json}
    ```
    """

    docblock = quote do
      @doc (if @schemadoc do
      """
        #{@schemadoc}
        #{unquote(docstr)}
      """
      else
        unquote(docstr)
      end)
    end

    res = quote do
      unquote_splicing([docblock | final_ast])
    end

    IO.puts("======================")
    res |> Macro.to_string |> IO.puts

    res
  end

  ##############################################################################
  ## utilities

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(any), do: any

  @spec mismatch(module, atom, any) :: {:mismatch, {module, atom, [any]}}
  def mismatch(m, f, a) do
    {:mismatch, {m, f, [a]}}
  end

end
