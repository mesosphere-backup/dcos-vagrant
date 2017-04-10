semi-semantic
=============

[![Build Status](https://travis-ci.org/pivotal-cf-experimental/semi_semantic.svg?branch=master)](https://travis-ci.org/pivotal-cf-experimental/semi_semantic)

A Ruby library for parsing/formatting/comparing semi-semantic versions.

### Why not just use Semantic Versioning?
The purpose of this library is to _support, but not require_ semantic versioning.

### How is this different than Semantic Versioning?
Unlike SemVer, Semi-Semantic does not define exactly how it must be used. 

Semi-Semantic...
- Allows unlimited version segment components separated by periods (accessed by array index).
    - Does not have named concept of 'major', 'minor', or 'patch' versions.
- Supports underscores, to allow compatibility with ruby gem conventions and timestamps.

### Usage

```Ruby
require 'semi_semantic/version'
...
version_string = '1.0.2-alpha.1+build.10'
version = SemiSemantic::Version.parse(version_string)

p version.release.to_s
# '1.0.2'

p version.pre_release.to_s
# 'alpha.1'

p version.post_release.to_s
# 'build.10'

# increment post-release number
p SemiSemantic::Version.new(version.release, version.pre_release, version.post_release.increment)
# '1.0.2-alpha.1+build.11'

# increment pre-release number
p SemiSemantic::Version.new(version.release, version.pre_release.increment)
# '1.0.2-alpha.2'

# increment release number
p SemiSemantic::Version.new(version.release.increment)
# '1.0.3'

# increment 'major' release number
p SemiSemantic::Version.new(version.release.increment(0))
# '2.0.0'

# increment 'minor' release number
p SemiSemantic::Version.new(version.release.increment(1))
# '1.1.0'

# increment second most least significant release number
p SemiSemantic::Version.new(version.release.increment(-2))
# '1.1.0'

```
