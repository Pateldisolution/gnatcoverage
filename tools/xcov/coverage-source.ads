------------------------------------------------------------------------------
--                                                                          --
--                              Couverture                                  --
--                                                                          --
--                    Copyright (C) 2009-2010, AdaCore                      --
--                                                                          --
-- Couverture is free software; you can redistribute it  and/or modify it   --
-- under terms of the GNU General Public License as published by the Free   --
-- Software Foundation; either version 2, or (at your option) any later     --
-- version.  Couverture is distributed in the hope that it will be useful,  --
-- but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHAN-  --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License  for more details. You  should  have  received a copy of the GNU --
-- General Public License  distributed with GNAT; see file COPYING. If not, --
-- write  to  the Free  Software  Foundation,  59 Temple Place - Suite 330, --
-- Boston, MA 02111-1307, USA.                                              --
--                                                                          --
------------------------------------------------------------------------------

with GNAT.Strings; use GNAT.Strings;

with Files_Table;    use Files_Table;
with Traces;         use Traces;
with Traces_Names;   use Traces_Names;
with Traces_Lines;   use Traces_Lines;
with SC_Obligations; use SC_Obligations;

package Coverage.Source is

   procedure Compute_Source_Coverage
     (Subp_Name : String_Access;
      Subp_Info : Subprogram_Info;
      T         : Trace_Entry);
   --  Analyze traces for the given subprogram to determine the coverage state
   --  of each SCO.

   procedure Compute_Line_State
     (Line_Num  : Positive;
      Line_Info : Line_Info_Access);
   --  Set Line.State based on coverage information accumulated on all SCOs
   --  that cover the given line.

   function Has_Been_Executed (SCO : SCO_Id) return Boolean;
   --  Assuming that SCO's kind is Statement, return True if it has been
   --  executed, False otherwise.

   function Get_Line_State
     (SCO   : SCO_Id;
      Level : Coverage_Level) return Line_State;

end Coverage.Source;
