defmodule Exonerate.Filter.Duration do
  @moduledoc false

  # provides special code for a duration filter.  This only needs to be
  # dropped in once.  The macro uses the cache to track if it needs to
  # be created more than once or not.  Creates a function "~duration?"
  # which returns a boolean depending on whether the string is a valid
  # duration.

  alias Exonerate.Cache

  defmacro filter do
    if Cache.register_context(__CALLER__.module, :"~duration?") do
      quote do
        defp unquote(:"~duration?")("P" <> rest) do
          case rest do
            "T" <> _time -> unquote(:"~duration-time?")(rest)
            _ -> unquote(:"~duration-date?")(rest)
          end
        end

        defp unquote(:"~duration?")(_), do: false

        defp unquote(:"~duration-date?")(""), do: true

        defp unquote(:"~duration-date?")(string) do
          case Integer.parse(string) do
            {_, "D" <> rest} -> unquote(:"~duration-time?")(rest)
            {_, "M" <> rest} -> unquote(:"~duration-day?")(rest)
            {_, "Y" <> rest} -> unquote(:"~duration-month?")(rest)
            {_, "W"} -> true
            _ -> false
          end
        end

        defp unquote(:"~duration-month?")(""), do: true

        defp unquote(:"~duration-month?")(time = "T" <> _rest) do
          unquote(:"~duration-time?")(time)
        end

        defp unquote(:"~duration-month?")(string) do
          case Integer.parse(string) do
            {_, "D" <> rest} -> unquote(:"~duration-time?")(rest)
            {_, "M" <> rest} -> unquote(:"~duration-day?")(rest)
            _ -> false
          end
        end

        defp unquote(:"~duration-day?")(""), do: true

        defp unquote(:"~duration-day?")(time = "T" <> _rest) do
          unquote(:"~duration-time?")(time)
        end

        defp unquote(:"~duration-day?")(string) do
          case Integer.parse(string) do
            {_, "D" <> rest} -> unquote(:"~duration-time?")(rest)
            _ -> false
          end
        end

        defp unquote(:"~duration-time?")(""), do: true

        defp unquote(:"~duration-time?")("T" <> string) do
          case Integer.parse(string) do
            {_, "H" <> rest} -> unquote(:"~duration-minute?")(rest)
            {_, "M" <> rest} -> unquote(:"~duration-second?")(rest)
            {_, "S"} -> true
            _ -> false
          end
        end

        defp unquote(:"~duration-minute?")(""), do: true

        defp unquote(:"~duration-minute?")(string) do
          case Integer.parse(string) do
            {_, "M" <> rest} -> unquote(:"~duration-second?")(rest)
            {_, "S"} -> true
            _ -> false
          end
        end

        defp unquote(:"~duration-second?")(""), do: true

        defp unquote(:"~duration-second?")(string) do
          case Integer.parse(string) do
            {_, "S"} -> true
            _ -> false
          end
        end
      end
    end
  end
end
