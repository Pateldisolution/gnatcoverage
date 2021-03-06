Core SC requirements
====================

All the other SC-related sections rely on this group.

To ensure coverage of all the relevant language constructs, we decompose the
material further based on the organization of the Ada Language Reference
Manual (Ada LRM), commonly designated as the Ada Reference Manual, or *ARM*:


.. qmlink:: SubsetIndexTable

   *


Several chapters aren't included for reasons listed in the following table:
   
.. tabularcolumns:: |p{0.3\textwidth}|p{0.65\textwidth}|

.. csv-table::
   :header: "Chapter", "Not included because ..."
   :widths: 28, 65
   :delim:  |

   ARM chap. 1 : General                | No language construct described
   ARM chap. 4 : Names and Expressions | "The described constructs are not
   considered on their own for coverage analysis purposes. The coverage
   information is computed for enclosing statement or declaration constructs."
   ARM chap. 9 : Tasks and Synchronization | "GNATcoverage is not qualified for the analysis of such constructs."


.. qmlink:: SubsetIndexTocTree

   *

