Definitions.

INT              = [0-9]+
WHITESPACE       = [\s\t\n\r]

Rules.

{INT}              : {token, {int, TokenChars}}.
app                : {token, {atom, app}}.
user               : {token, {atom, user}}.
list               : {token, {atom, list}}.
new                : {token, {atom, new}}.
h                  : {token, {atom, help}}.
help               : {token, {atom, help}}.
q                  : {token, {atom, quit}}.
quit               : {token, {atom, quit}}.
{WHITESPACE}+      : skip_token.

Erlang code.
