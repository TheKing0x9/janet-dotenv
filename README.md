# janet-dotenv

A small, compliant dotenv parser for the [Janet programming language](https://janet-lang.org/).

This library parses .env-style files into a Janet dictionary and can optionally set the parsed values into the running process environment. It supports quoted values, escaping, variable interpolation (including parameter expansion forms), export and source directives, and nested source inclusion.

## Features

- Parse dotenv files and strings into a dictionary
- Set parsed values into process environment
- Support for single-quoted (literal), double-quoted, backtick and unquoted values
- Escape sequences for common character escapes and hex/unicode escapes
- Variable interpolation and parameter expansion.
- Recognizes `export KEY=value` and `source filepath` directives (source includes another file)

## Installation

Place the `janet-dotenv` folder on your Janet load path, or require it relative to your project.

Example (from project root):

```janet
# require relative path
(import ./janet-dotenv/)
```

Alternatively, clone the project and run `janet --install .` to install it globally.

```sh
git clone https://github.com/theking0x9/janet-dotenv.git
cd janet-dotenv
janet --install .
```

## Usage

Parse a .env string:

```janet
(def env-str "FOO=bar\nNAME=\"Jane Doe\"")
(def dict (load-as-dict env-str))
# dict => {"FOO" "bar" "NAME" "Jane Doe"}
```

Parse a .env file:

```janet
(def dict (load-as-dict ".env" true))
```

Load and set into process environment:

```janet
(def dict (load-dotenv ".env" true))
# now FOO, NAME etc. are set via os/setenv
```

## Dotenv Specification

The implementation follows the [dotenvx](https://dotenvx.com/docs/env-file) specification as closely as possible, with some extensions for additional features. The following rules apply to .env files

### Keys

Keys must start with a letter or underscore, followed by letters, digits or underscores. For example:

```sh
MYVAR           # Valid Key
2ND_VAR         # Invalid (starts with a digit)
_PRIVATE_VAR    # Valid 
_SUPER_VAR*A    # Invalid (contains an asterisk)
```

### Values

Values follow a variable assignment, and can be quoted or unquoted. The following forms are supported:

- Unquoted: `KEY=value` (value is trimmed to end of line, supports interpolation)
- Single-quoted: `KEY='value'` (literal, no interpolation or escapes)
- Double-quoted: `KEY="value"` (supports interpolation and escapes)
- Backticked: KEY=\`value\` (supports interpolation and escapes)

### Syntax

The following syntax is supported in .env

- Lines beginning with `#` are comments and ignored.
- Blank lines are ignored.
- Unquoted, double-quoted and backticked values support variable interpolation and escape sequences.
- Lines starting with `export` are accepted (e.g. `export KEY=value`)
- Lines starting with `source` are accepted and will include and parse the specified file
- Inline comments must be preceded by whitespace (e.g. `KEY=value # comment` is valid) or a closing delimiter (e.g. `KEY="value" #comment` is valid)

### Variable Interpolation

The following interpolation styles are supported. 

- `$HOME` or `${HOME}` : Return value of environment variable `HOME`
- ${USER:-default}     : use `default` if `USER` is unset or set and not empty.
- ${USER-default}      : use `default` if `USER` is unset.
- ${FLAG:+alt}         : substitute `alt` when `FLAG` is set and not-empty.
- ${FLAG:+alt}         : substitute `alt` when `FLAG` is set.

### Quoting behavior

- Single quotes ('...') are literal; no interpolation or escape processing
- Double quotes ("...") and backticks (`...`) support interpolation and escapes
- Unquoted values are trimmed to end-of-line and support interpolation

### Source 

`.env` files can include other `.env` files within them by using the source command. Any files loaded via source will be parsed and their variables included in the resulting dictionary and process environment. For example:

```bash
# .env
source ~/common.env
```

Values of conflicting variables will be overridden by the last one parsed, so in the above example if `common.env` contains `FOO=bar` and `.env` contains `FOO=baz`, the resulting value of `FOO` will be `baz`.

## API Reference

- load-as-dict [env &opt is-file?]
  - env: string content or path (when is-file? true)
  - returns a Janet dictionary of key → value pairs

- load-dotenv [env &opt is-file?]
  - same as load-as-dict but also sets each key into the current process environment
  - returns the parsed dictionary

## Examples

.env file:

```bash
# Sample .env
FOO=bar
GREETING="Hello, $USER"
CONFIG=`/path/to/config`
export PATH="/custom/bin:$PATH"
source ./defaults.env
```

Janet usage:

```janet
(import "janet-dotenv/init")
(def env (load-as-dict "./.env" true))
(print env)
(load-dotenv "./.env" true) ;; sets os env vars
```

## Testing

Tests are present in the `test` directory and have a dependency on the `spork` module. To run tests, ensure that `janet-pm` is in your `PATH` and then execute

```bash
janet-pm test
```

Refer to the official Janet Documentation for details on how to install `spork`.

## Contributing

Contributions, bug reports and pull requests are welcome. 

### Reporting a Bug / Suggesting an Improvement

Please open an issue describing the bug or improvement, including steps to reproduce and any relevant code snippets.

### Submitting a Pull Request

1. Fork the repository and create your branch from `main`.
2. Make your changes and ensure tests pass.
3. Add tests for any new features or bug fixes.
4. Submit a pull request with a clear description of your changes.
5. Your PR will be reviewed and merged if it meets the contribution guidelines.

## Known Limitations

At the moment, the following issues are known to exist

- Command substitution with `$(command)` does not currently execute the command; This is a known limitation and will be addressed in future releases.
- Handling of escape sequences needs to be tested more thoroughly.
- Error handling is a bit basic and could be improved to provide more informative messages.
