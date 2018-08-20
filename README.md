## wavefront-cli-tests

Tests for [my Wavefront
CLI](https://github.com/snltd/wavefront-cli).

These are *potentially destructive* tests, which execute raw CLI
commands, creating, examining, modifying, and destroying, objects on
*a real, live* Wavefront cluster.

The CLI and the SDK
[the SDK](https://github.com/snltd/wavefront-sdk) on which it is
based have full unit test coverage. The tests in this repo are
additional, and unlikely to be of interest to anyone but myself.
