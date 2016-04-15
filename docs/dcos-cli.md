# DC/OS CLI

The [DC/OS CLI](https://dcos.io/docs/latest/usage/cli/) is used to install DC/OS services and marathon apps from package repositories.

As of DC/OS 1.6.1, the Cosmos component manages package repositories on the server side, instead of the CLI doing it on the client side.

## Universe

The DC/OS CLI by default uses the [Mesosphere Universe package repository](https://github.com/mesosphere/universe).

## Multiverse

As of DC/OS 1.7.0, the Multiverse has been deprecated and merged into the Universe. So adding the Multiverse repo is no longer required.

For DC/OS 1.6.1 and earlier, DC/OS CLI is configurable to use multiple universe-like package repositories, like [Mesosphere Multiverse package repository](https://github.com/mesosphere/multiverse).

In [DC/OS CLI 0.4.0](https://github.com/mesosphere/dcos-cli/releases/tag/0.4.0) (DC/OS 1.6.1), how to add remote repositories changed. Follow the instructions appropriate to the version you have installed.

- DC/OS >= 1.6.1 (>= DC/OS CLI 0.4.0, universe schema 2.x)

    ```
    dcos package repo add multiverse https://github.com/mesosphere/multiverse/archive/version-2.x.zip
    ```
- DC/OS <= 1.6.0 (<= DC/OS CLI 0.3.x, universe schema 1.x)

    ```
    dcos config prepend package.sources https://github.com/mesosphere/multiverse/archive/version-1.x.zip
    dcos package update --validate
    ```
