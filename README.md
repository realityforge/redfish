# Redfish

[![Build Status](https://secure.travis-ci.org/realityforge/redfish.png?branch=master)](http://travis-ci.org/realityforge/redfish)

Redfish is a lightweight ruby library for configuring GlassFish or Payara servers.

# TODO

Note: Items marked with (C) are required to convert chef infrastructure over, (L) required to
replace setup.sh infrastructure, (D) for docker integration.

* Enhance Json DSL
    * Add tests for domain interpretation - create phase as well as restart_if_required (C), (D), (L)
    * Raise an exception if any unprocessed data unless attribute starts with \_
    * Allow global ordering of items across elements. Make priority a string with two numbers? "10:10" (C), (D), (L)

* Enable reload of applications under conditions such as;
  - underlying resources updated that are used by application. Do this by extra listeners that use additional rules. (C)

* Add integration level tests (C)

* When tmpfs support is improved for osx clients talking to Linux servers add something like the following for
  all builds.


    --tmpfs /tmp:rw,noexec,nosuid,size=65536k --tmpfs /srv/glassfish:rw,noexec,nosuid,size=65536k --read-only

* Disable writing the shared memory mapped files for performance counters via `-XX:+PerfDisableSharedMem`
