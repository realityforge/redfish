# Redfish

[![Build Status](https://secure.travis-ci.org/realityforge/redfish.png?branch=master)](http://travis-ci.org/realityforge/redfish)

Redfish is a lightweight ruby library for configuring GlassFish or Payara servers.

# TODO

Note: Items marked with (C) are required to convert chef infrastructure over, (L) required to
replace setup.sh infrastructure, (D) for docker integration.

* Enhance Json DSL
    * Enhance domain configuration so can be shutdown if "created" (L), (D)
    * Add tests for domain interpretation - create phase as well as restart_if_required (C), (D), (L)
    * Enable removal of un defined jms_resource/admin_object elements. (C)
    * Raise an exception if any unprocessed data unless attribute starts with \_
    * Allow global ordering of items across elements. Make priority a string with two numbers? "10:10" (C), (D), (L)

* Extract per glassfish version config files that include all settings that are version specific such as
  logging levels, logging attributes, jvm properties, realm_types etc

* Enhance this project or another addon lib (buildr_plus?) to pragmatically generate the json definition.
  Add all sorts of short cuts as per our current chef infrastructure. Also new short cuts such as if the
  "secure" flag is set then define an admin realm. (D), (L)

* Add tasks to manage realm_types (C), (D), (L)

* Enable restart of app server under conditions such as;
    * update of realm_types (C), (D), (L)

* Enable reload of applications under conditions such as;
  - underlying resources updated that are used by application. Do this by extra listeners that use additional rules.

* Add integration level tests (C)

* Make sure sub-properties are cleaned up during cascade deletes of anything with child elements
