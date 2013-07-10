Core expectations for Decision Coverage
=======================================

Core expectations for Decision Coverage
(DC) assessments. All the other DC related sections rely on this one.


Requirement(s)
--------------



A *decision* is defined to be any Boolean expression that directly controls
the behavior of IF, WHILE and EXIT-WHEN control-flow constructs. Only the
expression as a whole is considered a decision; subexpressions are not
decisions on their own.  The types involved need not be restricted to the
standard Boolean type; they may subtypes or types derived from the Ada
fundamental type.

In this context, and in addition to the rules governing Statement Coverage,
the following set of extra rules shall be obeyed for Decision Coverage (DC)
assessements:

======  ======================================================================
Rule #  Description
======  ======================================================================
1       When the control-flow statement influenced by a decision has not been
        executed, that statement shall be reported as not covered and nothing
        shall be reported about the decision.

2       When a decision is evaluated only True or False, it shall be reported
        as only partially covered. In this case as in the previous one, the
        tool shall designate the decision with an unambiguous
        file-name:line#:col# reference.

3       When a decision is evaluated both True and False, no decision coverage
        violation shall be reported for it.

4       When a decision is never evaluated even though the enclosing statement
        has been executed (e.g. because of exceptions preventing the computation
        of an outcome), the decision shall be reported as never evaluated.

5       The tool shall be able to handle arbitrarily complex decisions in any
        context where they might appear.
======  ======================================================================


Testing Strategy
----------------



We validate all the DC rules thanks to three main subsets of testcases:


.. qmlink:: SubsetIndexImporter

   *



Rules #1 to 3 are validated by variations exercised in every individual
testcase, where we consistently check each decision of interest in multiple
manners, always including:

* a situation where the statements exposing the decision aren't
  executed at all (*rule #1*).

* a set of vectors where the decision evaluates only True (*rule #2*),

* a set of vectors where the decision evaluates only False (*rule #2*),

* a set of vectors where the decision evaluates both True and False
  (*rule #3*),

Rule #4 and #5 are addressed by the organization of the set of testcase groups
presented in the table above.
