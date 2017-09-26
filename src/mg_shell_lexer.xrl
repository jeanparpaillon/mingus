Definitions.

INT              = [0-9]+
WHITESPACE       = [\s\t\n\r]

Rules.

{INT}              : {token, {int, TokenChars}}.
host               : {token, {atom, host}}.
app                : {token, {atom, app}}.
user               : {token, {atom, user}}.
list               : {token, {atom, list}}.
provider           : {token, {atom, provider}}.
new                : {token, {atom, new}}.
get                : {token, {atom, get}}.
delete             : {token, {atom, delete}}.
help               : {token, {atom, help}}.
quit               : {token, {atom, quit}}.
{WHITESPACE}+      : skip_token.

Erlang code.
