# Redfish

[![Build Status](https://secure.travis-ci.org/realityforge/redfish.png?branch=master)](http://travis-ci.org/realityforge/redfish)

Redfish is a lightweight ruby library for configuring GlassFish or Payara servers.

# TODO

* Enhance Json DSL
    * Enable removal of un defined elements. Controllable per-element.
      - jms_resource/admin_object
    * Raise an exception if any unprocessed data unless attribute starts with _
    * Allow global ordering of items across elements. Make priority a string with two numbers? "10:10"

* Update DSL to specify payara specific arg when setting non-standard logging properties

* Enhance domain task to add:
    * ensure_admin_ready action? And also invoke from within restart?
    * Interpreter integration for create/delete

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
