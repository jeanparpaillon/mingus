Definitions.

D                = [0-9]
L                = [A-Za-z]
P                = [/_]
WS               = [\s\t\n\r]
SIGN             = [+-]

Rules.

{SIGN}?{D}+        : {token, {int, list_to_integer(TokenChars)}}.
{SIGN}?{D}+\.{D}+  : {token, {float, list_to_float(TokenChars)}}.
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
({L}|{P})+({L}|{P}|{D}|{SIGN})* :
                     {token, {word, TokenChars}}.
'[^\']+'           : {token, string_(TokenChars, TokenLen)}.
{WS}+              : skip_token.

Erlang code.

string_(Chars, Len) ->
  {string, lists:sublist(Chars, 2, Len - 2)}.
