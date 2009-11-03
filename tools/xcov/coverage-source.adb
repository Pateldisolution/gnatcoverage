------------------------------------------------------------------------------
--                                                                          --
--                              Couverture                                  --
--                                                                          --
--                       Copyright (C) 2009, AdaCore                        --
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

with Ada.Containers.Vectors;

with Interfaces;

with Decision_Map;      use Decision_Map;
with Diagnostics;       use Diagnostics;
with Elf_Disassemblers; use Elf_Disassemblers;
with MC_DC;             use MC_DC;
with SC_Obligations;    use SC_Obligations;
with Traces;            use Traces;
with Traces_Lines;      use Traces_Lines;

package body Coverage.Source is

   use Ada.Containers;

   --  For each source coverage obligation, we maintain a corresponding
   --  source coverage information record, which denotes the coverage state of
   --  the SCO. The default initialization must denote a completely uncovered
   --  state.

   package Evaluation_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Natural,
      Element_Type => MC_DC.Evaluation);

   type Outcome_Taken_Type is array (Boolean) of Boolean;

   type Source_Coverage_Info
     (Level : Source_Coverage_Level := Get_Coverage_Level;
      Kind  : SCO_Kind := Statement)
   is record
         case Kind is
            when Statement =>
               Executed : Boolean := False;
               --  Set True when the statement has been executed

            when Condition =>
               null;

            when Decision =>
               case Level is
                  when Stmt =>
                     null;

                  when Decision =>
                     Outcome_Taken : Outcome_Taken_Type := (others => False);
                     --  Each of these components is set True when the
                     --  corresponding outcome has been exercised.

                  when MCDC =>
                     Evaluations : Evaluation_Vectors.Vector;
                     --  History of all evaluations of this decision
               end case;
         end case;
   end record;

   procedure Set_Executed (SCI : in out Source_Coverage_Info);
   --  Set Executed to True

   package SCI_Vectors is new Ada.Containers.Vectors
       (Index_Type   => Valid_SCO_Id,
        Element_Type => Source_Coverage_Info);
   SCI_Vector : SCI_Vectors.Vector;

   --  MC/DC evaluation stack

   Evaluation_Stack : Evaluation_Vectors.Vector;

   procedure Condition_Evaluated (C_SCO : SCO_Id; C_Value : Boolean);
   --  Record evaluation of condition C_SCO with the given C_Value in the
   --  current decision evaluation.

   ------------------------
   -- Compute_Line_State --
   ------------------------

   procedure Compute_Line_State (Line : Line_Info_Access) is
      Multiple_Statements_Reported : Boolean := False;
      --  Set True when a diagnosis has been emitted for multiple statements

      procedure Update_Line_State (SCO_State : Line_State);
      --  Merge SCO_State into Line_State

      -----------------------
      -- Update_Line_State --
      -----------------------

      procedure Update_Line_State (SCO_State : Line_State) is
         pragma Assert (SCO_State /= No_Code);
      begin
         case Line.State is
            when No_Code =>
               Line.State := SCO_State;

            when Not_Covered =>
               Line.State := Line_State'Min (SCO_State, Partially_Covered);

            when Partially_Covered =>
               null;

            when Covered =>
               Line.State := Line_State'Max (SCO_State, Partially_Covered);
         end case;
      end Update_Line_State;

   --  Start of processing for Compute_Line_State

   begin
      Line.State := No_Code;

      if Line.SCOs.Length = 0 then
         --  No SCOs associated with this source line.

         --  ??? Have a debug mode to warn if there is object code with
         --  this line ?

         return;
      end if;

      if Line.Obj_First = null then
         --  No object code associated with this source line

         return;
      end if;

      --  Examine each SCO associated with line

      for J in Line.SCOs.First_Index .. Line.SCOs.Last_Index loop
         declare
            SCO         : constant SCO_Id := Line.SCOs.Element (J);
            SCI         : Source_Coverage_Info;
            Default_SCI : Source_Coverage_Info
                            (Level => Get_Coverage_Level, Kind => Kind (SCO));
            pragma Warnings (Off, Default_SCI);
            --  Used for default initialization value

            SCO_State   : Line_State := No_Code;

         begin
            if SCO in SCI_Vector.First_Index .. SCI_Vector.Last_Index then
               SCI := SCI_Vector.Element (SCO);
            else
               SCI := Default_SCI;
            end if;

            case Get_Coverage_Level is
               when Stmt =>
                  --  Statement coverage: line is covered if any associated
                  --  statement is executed.

                  if Kind (SCO) = Statement then
                     if SCI.Executed then
                        if Line.State = No_Code then
                           --  This is the first statement SCO for this line

                           SCO_State := Covered;
                        else
                           --  A previous statement SCO has been seen for this
                           --  line. Statements do not have full column numbers
                           --  in debug information, which prevents
                           --  discriminating between multiple statement SCOs
                           --  on the same line. We therefore conservatively
                           --  mark this SCO (and hence the complete line) as
                           --  partially, rather than fully, covered.

                           if not Multiple_Statements_Reported then
                              Multiple_Statements_Reported := True;
                              Report
                                (First_Sloc (SCO),
                                 "multiple statement SCOs on line, unable to "
                                 & "establish full statement coverage",
                                 Kind => Warning);
                           end if;
                           SCO_State := Partially_Covered;
                        end if;

                     else
                        SCO_State := Not_Covered;
                     end if;
                  end if;

               when Decision =>
                  --  Decision coverage: line is covered if all decisions are
                  --  covered, partially covered if any decision is partially
                  --  covered, marked no code if no decision.

                  if Kind (SCO) = Decision then
                     --  Compute coverage state for this decision

                     if SCI.Outcome_Taken (False)
                       and then SCI.Outcome_Taken (True)
                     then
                        SCO_State := Covered;

                     elsif SCI.Outcome_Taken (False)
                       or else SCI.Outcome_Taken (True)
                     then
                        SCO_State := Partially_Covered;

                     else
                        SCO_State := Not_Covered;
                     end if;
                  end if;

               when Object_Coverage_Level =>
                  --  Should never happen

                  raise Program_Error;

               when others =>
                  --  MC/DC not implemented

                  null;
            end case;

            if SCO_State /= No_Code then
               Update_Line_State (SCO_State);
            end if;
         end;
      end loop;
   end Compute_Line_State;

   -----------------------------
   -- Compute_Source_Coverage --
   -----------------------------

   procedure Compute_Source_Coverage
     (Subp_Name : String_Access;
      Subp_Info : in out Subprogram_Info)
   is
      use type Interfaces.Unsigned_32;

      Exe        : Exe_File_Acc renames Subp_Info.Exec;
      PC         : Pc_Type;
      It         : Entry_Iterator;
      T          : Trace_Entry;
      Insn_Len   : Natural;
      SCO, S_SCO : SCO_Id;

   begin
      --  Analyze routine control flow

      Analyze_Routine (Subp_Name, Subp_Info);

      --  Determine trace states

      Set_Insn_State (Subp_Info.Traces.all, Subp_Info.Insns.all);

      --  Iterate over traces for this routine

      Init (Subp_Info.Traces.all, It, 0);
      loop
         Get_Next_Trace (T, It);
         exit when T = Bad_Trace;

         PC := T.First;
         Trace_Insns :
         while PC <= T.Last loop
            Insn_Len :=
              Disa_For_Machine (Machine).
                Get_Insn_Length (Subp_Info.Insns (PC .. Subp_Info.Insns'Last));

            --  Find SCO for this instruction

            SCO := Sloc_To_SCO (Get_Sloc (Subp_Info.Exec.all, PC));
            if SCO = No_SCO_Id then
               goto Continue_Trace_Insns;
            end if;

            --  Ensure there is a coverage information entry for this SCO

            while SCI_Vector.Last_Index < SCO loop
               declare
                  New_Index : constant SCO_Id := SCI_Vector.Last_Index + 1;
                  New_SCI   : Source_Coverage_Info
                                (Kind  => Kind (New_Index),
                                 Level => Get_Coverage_Level);
                  pragma Warnings (Off, New_SCI);
                  --  Used for default initialization value only
               begin
                  SCI_Vector.Append (New_SCI);
               end;
            end loop;

            --  Find enclosing statement SCO and mark it as executed

            S_SCO := SCO;
            while Kind (S_SCO) /= Statement loop
               S_SCO := Parent (S_SCO);
               pragma Assert (S_SCO /= No_SCO_Id);
            end loop;

            loop
               --  Mark S_SCO as executed

               SCI_Vector.Update_Element (S_SCO, Set_Executed'Access);

               --  Propagate back to beginning of basic block

               S_SCO := Previous (S_SCO);
               exit when S_SCO = No_SCO_Id
                           or else SCI_Vector.Element (S_SCO).Executed;
               SCI_Vector.Update_Element (S_SCO, Set_Executed'Access);
            end loop;

            if Get_Coverage_Level = Stmt
              or else Kind (SCO) /= Condition
              or else not Cond_Branch_Map.Contains (PC)
            then
               goto Continue_Trace_Insns;
            end if;

            --  Here we have a condition SCO, and the PC for a conditional
            --  branch instruction.

            Process_Conditional_Branch : declare
               CBI : constant Cond_Branch_Info := Cond_Branch_Map.Element (PC);
               pragma Assert (CBI.Condition = SCO);

               procedure Edge_Taken (E : Edge_Kind);
               --  Record that edge E for the conditional branch at PC has been
               --  taken.

               ----------------
               -- Edge_Taken --
               ----------------

               procedure Edge_Taken (E : Edge_Kind) is
                  CBE : constant Cond_Edge_Info := CBI.Edges (E);

                  procedure Set_Outcome_Taken
                    (SCI : in out Source_Coverage_Info);
                  --  Mark as taken the decision outcome corresponding to CBE

                  -----------------------
                  -- Set_Outcome_Taken --
                  -----------------------

                  procedure Set_Outcome_Taken
                    (SCI : in out Source_Coverage_Info)
                  is
                     ES_Top : Evaluation;
                  begin
                     --  Mark outcome taken

                     SCI.Outcome_Taken (To_Boolean (CBE.Outcome)) := True;
                     return;

                     --  The following is for MC/DC, not yet implemented???

                     pragma Warnings (Off);
                     ES_Top := Evaluation_Stack.Last_Element;
                     pragma Warnings (On);
                     Evaluation_Stack.Delete_Last;

                     --  Note: if for some reason we failed to identify which
                     --  value of the outcome this edge represents, then we
                     --  silently ignore it, and do not mark any outcome of
                     --  the decision as known to have been taken.

                     if CBE.Outcome = Unknown then
                        return;
                     end if;

                     --  Record evaluation vector

                     if Get_Coverage_Level = MCDC then
                        ES_Top.Outcome := CBE.Outcome;
                        SCI.Evaluations.Append (ES_Top);
                     end if;
                  end Set_Outcome_Taken;

               --  Start of processing for Edge_Taken

               begin
                  if CBE.Dest_Kind = Unknown then
                     Report
                       (Exe, PC,
                        "unlabeled edge " & E'Img & " taken",
                        Kind => Error);

                  else
                     --  Record value of condition for this evaluation

                     if CBE.Origin = Unknown then
                        Report
                          (Exe, PC,
                           "edge " & E'Img & " with unlabeled origin taken",
                           Kind => Error);
                     else
                        Condition_Evaluated (SCO, To_Boolean (CBE.Origin));
                     end if;

                     --  If the destination is an outcome, process completed
                     --  evaluation.

                     if CBE.Dest_Kind = Outcome then
                        SCI_Vector.Update_Element
                          (Parent (SCO), Set_Outcome_Taken'Access);
                     end if;
                  end if;
               end Edge_Taken;

            --  Start of processing for Process_Conditional_Branch

            begin
               Report
                 (Exe, PC,
                  "processing cond branch trace " & T.State'Img,
                  Kind => Notice);
               case T.State is
                  when Branch_Taken =>
                     Edge_Taken (Branch);

                  when Fallthrough_Taken =>
                     Edge_Taken (Fallthrough);

                  when Both_Taken =>
                     if Get_Coverage_Level = MCDC then
                        --  For MC/DC we need full historical traces, not just
                        --  accumulated traces.

                        Report
                          (Exe, PC,
                           "missing full traces of conditional branch "
                           & "for MC/DC");
                     else
                        Edge_Taken (Branch);
                        Edge_Taken (Fallthrough);
                     end if;

                  when others =>
                     Report
                       (Exe, PC,
                        "unexpected cond branch trace state " & T.State'Img,
                        Kind => Warning);

               end case;
            end Process_Conditional_Branch;

            <<Continue_Trace_Insns>>
            PC := PC + Pc_Type (Insn_Len);

            --  Handle case where PC wraps

            exit Trace_Insns when PC = 0;
         end loop Trace_Insns;
      end loop;

   end Compute_Source_Coverage;

   -------------------------
   -- Condition_Evaluated --
   -------------------------

   procedure Condition_Evaluated (C_SCO : SCO_Id; C_Value : Boolean) is
   begin
      null;
   end Condition_Evaluated;

   ------------------
   -- Set_Executed --
   ------------------

   procedure Set_Executed (SCI : in out Source_Coverage_Info) is
   begin
      SCI.Executed := True;
   end Set_Executed;

end Coverage.Source;
