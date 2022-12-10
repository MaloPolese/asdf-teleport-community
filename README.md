<div align="center">

# asdf-teleport-community [![Build](https://github.com/MaloPolese/asdf-teleport-community/actions/workflows/build.yml/badge.svg)](https://github.com/MaloPolese/asdf-teleport-community/actions/workflows/build.yml) [![Lint](https://github.com/MaloPolese/asdf-teleport-community/actions/workflows/lint.yml/badge.svg)](https://github.com/MaloPolese/asdf-teleport-community/actions/workflows/lint.yml)

[teleport-community](https://github.com/MaloPolese/asdf-teleport-community) plugin for the [asdf version manager](https://asdf-vm.com).

</div>

# Contents

- [Dependencies](#dependencies)
- [Install](#install)
- [Contributing](#contributing)
- [License](#license)

# Dependencies

- `bash`, `curl`, `tar`: generic POSIX utilities.

# Install

Plugin:

```shell
asdf plugin add teleport-community
# or
asdf plugin add teleport-community https://github.com/MaloPolese/asdf-teleport-community.git
```

teleport-community:

```shell
# Show all installable versions
asdf list-all teleport-community

# Install specific version
asdf install teleport-community latest

# Set a version globally (on your ~/.tool-versions file)
asdf global teleport-community latest

# Now teleport-community commands are available
tsh version
tctl version
tbot version
teleport version
```

Check [asdf](https://github.com/asdf-vm/asdf) readme for more instructions on how to
install & manage versions.

# Contributing

Contributions of any kind welcome! See the [contributing guide](contributing.md).

[Thanks goes to these contributors](https://github.com/MaloPolese/asdf-teleport-community/graphs/contributors)!

# License

See [LICENSE](LICENSE) © [Malo Polese](https://github.com/MaloPolese/)
