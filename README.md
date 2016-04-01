# Redfish

[![Build Status](https://secure.travis-ci.org/realityforge/redfish.png?branch=master)](http://travis-ci.org/realityforge/redfish)

Redfish is a lightweight ruby library for configuring GlassFish or Payara servers.

# TODO

* Enhance Json DSL
    * Enable removal of un defined jms_resource/admin_object elements.
    * Raise an exception if any unprocessed data unless attribute starts with _
    * Allow global ordering of items across elements. Make priority a string with two numbers? "10:10"

* Add equivalent of secure_admin command

* Enhance domain task to add:
    * Interpreter integration for create/delete

* Extract per glassfish version config files that include all settings that are version specific such as
  logging levels, logging attributes, jvm properties, realm_types etc

* Add tasks to manage realm_types

* Enable restart of app server under conditions such as;
    * update of realm_types
    * update of libraries
    * update of jvm options
    * change the jms host (or maybe just the default jms host?)

* Enable reload of applications under conditions such as;
  - underlying resources updated that are used by application. Do this by extra listeners that use additional rules.

* Add integration level tests

* Make sure sub-properties are cleaned up during cascade deletes of anything with child elements
