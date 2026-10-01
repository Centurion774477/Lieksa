
# returns a string of file contents
read_file = fn file ->
  case File.read(file) do
    {:ok, contents} ->
      contents
    {:error, :enoent} ->
      IO.puts("The given file: #{file} does not exist in this context.")
      System.stop()
    {:error, reason} ->
      IO.puts("Something went wrong while trying to read #{file}: #{reason}")
      System.stop()
  end
end

write_out = fn
  data, file ->
    case File.write(file, data, [:append]) do
      :ok ->
        true
      {:error, reason} ->
        IO.puts("Failed to write to #{file}. Reason: #{reason}")
    end
end

generate_html = fn
  nil, _buffer ->
    # return a string instead of nil so everything else like the file writing works fine
    ""

  groups, buffer ->
    functionName = groups["function_name"]
    arguments = groups["arguments"]

    argumentsText = case arguments do
      "" ->
        "Receives no arguments"
      _ ->
        "Receives: #{arguments}"
    end

    """
    <h2 class="lieksa-function-name" id="#{functionName}">#{functionName}</h2>

    <h3 class="lieksa-function-arguments">#{argumentsText}</h3>

    <p class="lieksa-function-description">
    #{buffer}
    </p>

    """
end

generate_nav = fn functions ->
  links = Enum.map(functions, fn function ->
    "    <li><a href='##{function}'>#{function}</a></li>"
  end)

  nav_opening = """
  <nav id="lieksa-nav">
    <ol>
  """

  nav_closing = """
    </ol>
  </nav>

  """

  [nav_opening] ++ links ++ [nav_closing]
  |> Enum.join("\n")
end

add_nav = fn lines, fileToCreate ->
  Enum.reduce(lines, [], fn line, accumulator ->
    # save this regex pattern as a variable later
    if String.starts_with?(line, "def") do
      groups = Regex.named_captures(~r/def (?<function_name>.*?)\((?<arguments>.*?)\)/, line)
      accumulator ++ [groups["function_name"]]
    else
      accumulator
    end
  end)
  |> generate_nav.()
  |> write_out.(fileToCreate)
end

# returns true if any Lieksa was detected in a given file
ensure_html_was_generated = fn file ->
  lines = read_file.(file)
  |> String.split("\n")

  if Enum.any?(lines, fn line ->
    String.contains?(line, "class=\"lieksa-function-name\"")
  end) do
    true
  else
    false
  end
end



[fileToRead, fileToCreate | flags] = case System.argv() do
  [fileToRead, fileToCreate | flags] ->
    [fileToRead, fileToCreate | flags]
  _ ->
    IO.puts("Please provide your code and your desired output file name as the first and second arguments.")
    System.stop()
end



generate_stylesheet = Enum.member?(flags, "style-it") # generate a stylesheet and link it to the HTML file
generate_nav = Enum.member?(flags, "create-nav") # add a <nav> element to the HTML file with links

link_element = case generate_stylesheet do
  true ->
    """
    body {
      display: flex;
      flex-direction: column;
      align-items: center;
    }
    """ |> write_out.("lieksa.css")

    "<link rel='stylesheet' href='lieksa.css'>"
  false ->
    ""
end

"""
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title>Lieksa Documentation</title>
  #{link_element}
</head>
<body>

<!--Generated with Lieksa-->

""" |> write_out.(fileToCreate)

lines = read_file.(fileToRead)
|> String.split("\n")

if generate_nav == true do
  add_nav.(lines, fileToCreate)
end

Enum.each(lines, fn line ->
  IO.puts(line)
end)

Enum.reduce(lines, [], fn line, accumulator ->
  cond do
    # comments get added to the buffer
    String.starts_with?(line, ["#", "//"]) ->
      accumulator ++ [line]

    String.starts_with?(line, ["def", "function"]) ->
      groups = Regex.named_captures(~r/(def|function) (?<function_name>.*?)\((?<arguments>.*?)\)/, line)

      cleaned_buffer = accumulator
      |> Enum.map(&String.replace_prefix(&1, "# ", "")) # remove the comment hashtags
      |> Enum.map(&String.replace_prefix(&1, "// ", ""))
      |> Enum.join("<br>\n") # add HTML newlines and normal newlines

      generate_html.(groups, cleaned_buffer)
      |> write_out.(fileToCreate)

      []
    String.match?(line, ~r/(.*) = (\(.*\) )?(->|=>)/) -> # handle CoffeeScript/JS arrow functions
      IO.puts("matched: #{line}")
      # I know this is repetitive
      groups = Regex.named_captures(~r/(?<name>.*) = (?<arguments>\(\) )?(->|=>)/, line)

      cleaned_buffer = accumulator
      |> Enum.map(&String.replace_prefix(&1, "# ", "")) # remove the comment hashtags
      |> Enum.map(&String.replace_prefix(&1, "// ", ""))
      |> Enum.join("<br>\n") # add HTML newlines and normal newlines

      generate_html.(groups, cleaned_buffer)
      |> write_out.(fileToCreate)

      []
    true ->
      accumulator
  end
end)

# close the opened HTML tags
"""
</body>
</html>
""" |> write_out.(fileToCreate)

if ensure_html_was_generated.(fileToCreate) == false do
  IO.puts("Lieksa didn't find any functions to generate in #{fileToRead}")
  System.stop()
  # should probably delete the file too
else
  IO.puts("Successfully generated your HTML in #{fileToCreate}. Cheers!")
end
