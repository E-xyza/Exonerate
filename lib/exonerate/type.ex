defmodule Exonerate.Type do
  @moduledoc false

  @type json ::
          %{optional(String.t()) => json}
          | list(json)
          | String.t()
          | number
          | boolean
          | nil

  @module Map.new(
            ~w(string integer number object array boolean null),
            &{&1, Module.concat(Elixir.Exonerate.Type, String.capitalize(&1))}
          )

  def module(type), do: @module[type]
end
