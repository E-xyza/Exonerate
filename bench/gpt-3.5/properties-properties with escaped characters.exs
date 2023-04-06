defmodule :"properties-properties with escaped characters-gpt-3.5" do
  def validate(%{
        "foo\tbar" => number,
        "foo\nbar" => number,
        "foo\fbar" => number,
        "foo\rbar" => number,
        "foo\"bar" => number,
        "foo\\bar" => number
      })
      when is_number(number) do
    :ok
  end

  def validate(_) do
    :error
  end
end