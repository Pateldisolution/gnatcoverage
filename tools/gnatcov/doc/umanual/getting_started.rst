***************
Getting Started
***************

General Principles
==================

|gcp| provides coverage analysis facilities through the |gcv| command-line
tool. |gcv| relies on an instrumented execution environment to produce
execution traces instead of having to instrument to program itself. For cross
configurations, |gem| provides such an environment, offering support for
coverage assessments directly on the target code in cross
configurations. Hardware probes maye also be used as trace producers, provided
trace data is converted to the format |gcv| expects. Some native
configurations are supported as well, using process wrappers to produce traces
within the host environment (for example valgrind on Linux or dynamoRIO on
Windows).

|gcp| supports both source and object level coverage criteria: statement,
decision, or mcdc coverage for the source level, and instruction or branch
coverage for the object level. Once your application is built, a typical
analysis proceeds in two steps:

1) Arrange to produce an execution trace that |gcv| can process, using either

   |gcvrun| to run your application within an instrumented environment,
   like::

     gnatcov run <yourapp> [--target=<target>] [--kernel=<kernel>]
       [--scos=@<libfiles-list> | -P<root-gpr>] (implicit -o <yourapp.trace>)

   or |gcvcnv| to convert a trace obtained through a hardware probe, like::

     gnatcov convert <probe-output> -o <yourapp.trace>


2) Use |gcvcov| to produce a coverage report from one or more such execution
   traces, like::

     gnatcov coverage --level=<criterion> --annotate=<report-format>
        [--scos=@<libfiles-list> | -P<root-gpr>] [--routines=@<symbols-list>]
        <yourapp.trace1> <yourapp.trace2> ...

Very briefly here:

- :option:`--target` selects the execution environment that will know how to
  produce execution traces, such as <target>-gnatemu for emulated
  configurations.  This can also be achieved with a ``Target`` attribute in
  the project file designated by :option:`-P` (see the :ref:`target_attr`
  section of this manual). Absence of a target specification requests
  instrumented execution within the host environment, in which case command
  line arguments can be passed to the executable program by adding a
  :option:`-eargs` sequence on the |gcv| command line. You may provide the
  executable name as part of this sequence as well. See the
  :ref:`execution-control` section of this manual for more details.

- :option:`--kernel` is necessary for cross configurations where an operating
  system kernel is needed to load and launch your applicative modules on top
  of the bare machine execution environment. This is typically required for
  VxWorks targets, supported on top of |gem| and where the provided kernel
  needs to have been augmented with a |gcp| dedicated module to help identify
  the address at which your programs are loaded (please refer to the GNATemulator
  documentation for this specific part of the process).

- :option:`--level` specifies the coverage criterion to be assessed
  (:option:`=stmt`, :option:`=stmt+decision`, or :option:`=stmt+mcdc` for
  source coverage criteria; :option:`=insn` or :option:`=branch` for object
  coverage crtieria)

- :option:`--annotate` specifies the desired output report format
  (:option:`=report` for a synthetic list of coverage violations, :option:`=xcov`
  for annotated sources in text format, :option:`=dhtml` for annotated sources
  in html format, with colors, a toplevel and per-project indexes, sortable
  columns ...)

- :option:`--scos` is specific to the source level criteria, to convey the so
  called `Source Coverage Obligations` (statements, decisions, ...) to be
  processed. The argument value in the example here, using the @ notation, is
  the name of a file which contains the set of Ada ALI files or C GLI files
  corresponding to the source units of interest. This drives the assessment
  process and at the same time specifies the set of source units for which a
  report should be produced.

- :option:`-P` might be used instead of --scos, to designate a root GNAT
  project file from which the set of coverage obligations can be inferred
  using high level project abstractions such as source units closures or
  sub-projects dependencies.

- :option:`--routines` is specific to the object level criteria, and
  optional in this case. This conveys the set of object symbol names
  on which the analysis should focus, if any.

For source coverage assessments, sources must be compiled with :option:`-g
-fpreserve-control-flow -fdump-scos`, plus :option:`-gno-strict-dwarf`
for VxWorks targets.  Optimization is supported up to :option:`-O1`, with
inlining allowed.  For backwards compatibility, :option:`-gnateS`
can be used as a synonym of :option:`-fdump-scos` for Ada.

Object coverage analysis proceeds in a similar fashion, with different
:option:`--level` option values. There is no `source` coverage obligation
involved (by definition of *object* coverage), so no :option:`--scos`
argument, and no specific constraint on the compilation options.

Beyond the simple cases sketched above, |gcp| supports advanced capabilities
available for both source and object coverage criteria. Two examples are
*coverage consolidation*, computing results for a set of execution traces, and
*exemption regions*, allowing users to define code regions for which coverage
violations are expected and legitimate. The following chapters in this manual
provide many more details on the various possible modes of operation. Prior to
this, next in this chapter, comes a complete example sequence illustrating
steps from compilation to coverage analysis of a very simple Ada program.


Example session, from sources to coverage analysis
==================================================

We start from the very basic Ada package below, with a spec and body in source
files named ``ops.ads`` and ``ops.adb``, exposing a set of very basic
named operations over ``Integer`` objects:

.. code-block:: ada

   package Ops is
     type Op_Kind is (Increment, Decrement);
     procedure Apply (Op : Op_Kind; X : in out Integer);
   end Ops;

   package body Ops is
     procedure Apply (Op : Op_Kind; X : in out Integer) is
     begin
        case Op is
           when Increment => X := X + 1;
           when Decrement => X := X - 1;
        end case;
     end Apply;
   end Ops;

We analyse the coverage achieved by the sample unit :term:`test driver` below,
in ``test_inc.adb``, which exercises the ``Increment`` operation only:

.. code-block:: ada

   with Ops;
   procedure Test_Inc is
     X : Integer := 4;
   begin
     Ops.Apply (Ops.Increment, X);
     pragma Assert (X = 5);
   end Test_Inc;

We use the GNAT Pro toolset for powerpc-elf to build, and GNATemulator for the
same target (invoked by gnatcov run) to emulate. The executable construction
is performed using :command:`gprbuild`, operating on the following ``ops.gpr``
project file::

   project Ops is
    for Languages use ("Ada");
    for Source_Dirs use (".");
    for Object_Dir use "obj";
   end Ops;

First, we build with this command line::

   gprbuild -p --target=powerpc-elf --RTS=zfp-prep -Pops.gpr test_inc.adb
    -cargs:Ada -gnata -cargs -g -fpreserve-control-flow -fdump-scos

In this particular case:

- :option:`-p` queries the creation of the "obj" object directory if it
  doesn't exist. This is where the object, ALI, and executable files will
  reside.

- :option:`--target` and :option:`--RTS` tell gprbuild which target toolchain
  and runtime library to use. Here, powerpc-elf and a zero-footprint library
  tailored for the ``prep`` GNATemulator board.

- :option:`-Pops.gpr` :option:`test_inc.adb` designate the project file and
  the main unit to build.

- :option:`-cargs:Ada` sets the Ada specific compilation option and
  :option:`-cargs` sets the more general ones in accordance with the
  guidelines stated earlier.

The build command produces a ``test_inc`` executable in the object
subdirectory. Our second step is to execute this program within the
instrumented execution environment, via GNATemulator, to obtain a
``test_inc.trace`` execution trace. We do this with |gcvrun|, as follows::

  gnatcov run --target=powerpc-elf obj/test_inc

Now, we can analyse the coverage achieved by this execution using
|gcvcov|, for example with::

  gnatcov coverage --level=stmt --annotate=xcov test_inc.trace -Pops.gpr

Here, we request

- A source *statement coverage* assessment with :option:`--level=stmt`,

- An annotated source report in text format with :option:`--annotate=xcov`,

- For the complete set of units involved in the executable, per
  :option:`-Pops.gpr` and no specification otherwise in the project file.

This produces annotated sources in the current directory,
with ``ops.adb.xcov`` quoted below:

.. code-block:: ada

  examples/starter/src/ops.adb:
  67% of 3 lines covered
  Coverage level: stmt
   1 .: package body Ops is
   2 .:    procedure Apply (Op : Op_Kind; X : in out Integer) is
   3 .:    begin
   4 +:       case Op is
   5 +:          when Increment => X := X + 1;
   6 -:          when Decrement => X := X - 1;
   7 .:       end case;
   8 .:    end Apply;
   9 .: end Ops;

The analysis results are visible as ``+`` / ``-`` annotations on source lines,
next to the line numbers. The results we have here indicate proper coverage of
all the statements except the one dealing with a ``Decrement`` operation,
indeed never exercised by our driver.

Focus on specific units, excluding the test driver from the analysis closure
for example, can be achieved by adding a ``Coverage`` package to the project
file or by using :option:`--scos=obj/ops.ali` instead of :option:`-P`.

Supported languages
===================

Object coverage analysis is essentially language agnostic. The object level
criteria definitions care about machine instructions, not source constructs,
and even reports formatted as sources annotated with object level coverage
results rely on no more than basic DWARF debugging information associated with
the analyzed object code.

Source coverage criteria, on the other hand, are defined in close association
with each particular source language and their processing relies on a correct
implementation of :option:`-fpreserve-control-flow` and :option:`-fdump-scos`
by the compiler.

As of today, |gcp| supports all the variants of Ada and C supported by the
compilation toolchain. The behavior on Ada 2012 functional constructs such as
*if* or *case* expressions is still subject to change, in particular regarding
decision or mcdc analysis as the criteria definition aren't yet well
established for such constructs in general.

Target specific considerations
==============================

Even though most of the command line options and compilation requirements
sketched earlier in this chapter are common to all the supported target
configurations, a few specificities apply to only some of them. Each
specificity is documented in the context of relevance in this manual, and the
:ref:`target_specific_notes` appendix provides a summary of all the points
grouped by target.

