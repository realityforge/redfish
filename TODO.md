# TODO

* Enhance Json DSL
    * Enable removal of un defined elements. Controllable per-element.
    * Raise an exception if any unprocessed data unless attribute starts with _
    * Allow global ordering of items across elements. Make priority a string with two numbers? "10:10"

* Update DSL to allow updates to logging properties through tasks

* Enable restart of app server under conditions such as;
    * update of libraries
    * update of jvm options
    * change the jms host (or maybe just the default jms host?)

* Enable reload of applications under conditions such as;
  - underlying resources updated that are used by application. Do this by extra listeners that use additional rules.

* Add integration level tests
