# Install Ruby

Installing vagrant plugins may require having an modern version of ruby installed on the host.

There are several ways to install ruby. One way is to use ruby-install, using chruby to manage your ruby installations:

1. Install ruby-install via homebrew:

    ```
    brew install ruby-install
    ```

1. Find the latest stable ruby:

    ```
    curl --fail --location --silent --show-error http://cache.ruby-lang.org/pub/ruby/index.txt | cut -f1 | sort | tail -1 | cut -d'-' -f2
    ```

1. Install ruby via ruby-install:

    ```
    ruby-install ruby <version>
    ```

1. Install chruby via homebrew:

    ```
    brew install chruby
    ```

1. Configure your shell (and `~/.bash_profile`) to source chruby:

    ```
    source '/usr/local/share/chruby/chruby.sh'
    chruby <version>
    ```
