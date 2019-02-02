defmodule Exonerate do

  @moduledoc """
    creates the defschema macro.
  """

  @type json ::
     %{optional(String.t) => json}
     | list(json)
     | String.t
     | number
     | boolean
     | nil

  @type mismatch :: {:mismatch, {module, atom, [json]}}

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
      if Module.get_attribute(__MODULE__, :schemadoc) do
        @doc """
        #{@schemadoc}
        #{unquote(docstr)}
        """
      else
        @doc unquote(docstr)
      end
    end

    quote do
      unquote_splicing([docblock | final_ast])
    end
  end

  ##############################################################################
  ## utilities

  defp maybe_desigil(s = {:sigil_s, _, _}) do
    {bin, _} = Code.eval_quoted(s)
    bin
  end
  defp maybe_desigil(any), do: any

  defmacro mismatch(m, f, a) do
    quote do
      {:mismatch, {unquote(m), unquote(f), [unquote(a)]}}
    end
  end

end
