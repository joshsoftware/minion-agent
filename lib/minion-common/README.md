# minion-common

The Minion project has multiple separate codebases which have some dependencies
on the same set of helper libraries and utilities. Those should be extracted into
this common library which the various other codebases can just depend on as a
shard.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     minion-common:
       github: joshsoftware/minion-common
   ```

2. Run `shards install`

## Usage

```crystal
require "minion-common"
```

## Contributors

- [Kirk Haines](https://github.com/wyhaines) - creator and maintainer
