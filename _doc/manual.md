# User manual

Mingus is code-driven orchestrator. Simple. Efficient. Robust.

## Installation

* Clone the repository:

```sh
$ git clone http://gitlab01.priv.cloud.kbrwadventure.com/kbrw/mingus
```

* Copy a public ssh key in `priv/keys`:

```sh
$ cp ~/.ssh/id_rsa.pub mingus/priv/keys/
```

* Launch the app

```sh
$ iex -S mix
```

## Using

Most of Mingus operations are accessible through an SSH CLI. Just
connect to Mingus with you preferred SSH client on port `10022` (by
default).
