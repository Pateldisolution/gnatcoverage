SC requirements for Pragmas (ARM 2.8)
=====================================


%REQ_ID%



Different kinds of pragmas exist, some always active, some possibly ignored
depending on configuration parameters. They may be located in various
contexts, some possibly never elaborated such as as subprogram declarative
parts.

* Inactive pragmas shall be ignored;

* Active pragmas that were never elaborated as part of the program execution
  shall be reported uncovered.


.. rubric:: Testing Strategy



We check this requirement for different kinds of pragmas in various
possible source regions, with the following set of testcases:


.. qmlink:: TCIndexImporter

   *



