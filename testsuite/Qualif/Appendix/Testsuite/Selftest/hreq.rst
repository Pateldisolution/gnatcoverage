Sanity check the harness FAILure detection capability.
======================================================

By construction, the set of tool qualification testcases are expected to all
PASS. This section is to sanity-check the harness operation with a specific
requirement and set of testcases expected to FAIL. This is not a GNATcoverage
tool requirement per se and is *not* meant as full fledged qualification
material for the harness.

Requirement(s)
--------------

The test harness shall comply to the following requirements:

* A test that does not run to completion shall FAIL;

* Presence in the ouput report of an unexpected violation applicable to the
  test category shall cause FAILure.  Unexpected here means either nothing
  stated at all or an explicit ``0`` expectation stating that nothing is
  expected.

* Absence of an expected violation from the output report shall cause FAILure

* Presence in the output report of violations not applicable to the test
  category shall be ignored

