# Lieksa

Lieksa takes a file and generates an HTML file. There's plenty of tools that do that right now -- Doxygen, JSDoc, you could even ask an LM -- But all of those complain in some way.

Doxygen has its own documentation. That says enough about it; Lieksa's documentation can be summed up in one line -- which will be done later.
Documentation is for compilers and entire languages, not for tools that just generate documentation.

JSDoc stains your codebase with it's custom comment syntax. If you change your codebase to support JSDoc you may never be able to leave it if you decide you want out.

Language Models are quite appealing: no language barrier, basically no installation process, but AI is surprising and you never know what you are going to get.
With Lieksa, you get the same thing every time without fail; You'll never get an unexpected feature. Also, if you ever decide you want to manually change something, good luck understanding the AI's code.

In other words, Lieksa doesn't hold you hostage.

Right now, Lieksa supports languages with function declaration like:

```
def/function <name>(<arguments>)
```

That includes:
* Ruby
* Elixir
* JavaScript (not arrow functions)
* Python
* PHP

The only comment symbol that is recognized is a hashtag: '#', but I am actively working on expanding the compatability.

Unlike other documentation generators that only consume your special syntax, Lieksa consumes all of your comments no matter what.
The catch is, it only consumes comments above a function. I don't see why you would be commenting above a function for any purpose besides documentation, so this shouldn't cause any problems.

# Use Lieksa

I'd be lying if I said there are no dependencies, but you just need Elixir installed:

For macOS machines using Homebrew you can run:
`brew install elixir`

The installation information for Elixir can be found [here](https://elixir-lang.org/install/)

I built Lieksa using Erlang/OPT version 29 and Elixir version 1.20.2.
I can't give you an exact number of what version to install but installing the latest version is probably the safe choice.

## Actually running it

Get Lieksa on your machine however you want -- git clone, etc.

Then run the one and only command:

```
elixir lieksa.ex <your_file> <new_html_file_name>
```

If you wish, you can generate a (minimal) stylesheet using the `style-it` flag:

```
elixir lieksa.ex <your_file> <new_html_file_name> style-it
```

That's Lieksa. I hope you enjoy.

