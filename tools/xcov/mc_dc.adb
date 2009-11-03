------------------------------------------------------------------------------
--                                                                          --
--                              Couverture                                  --
--                                                                          --
--                      Copyright (C) 2009, AdaCore                         --
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

package body MC_DC is

   -------------------
   -- Is_MC_DC_Pair --
   -------------------

   function Is_MC_DC_Pair
     (Eval_1, Eval_2 : Evaluation) return Any_Condition_Index
   is
      First_Different : Any_Condition_Index := No_Condition_Index;
   begin
      pragma Assert (Eval_1.Decision = Eval_2.Decision);
      pragma Assert (Eval_1.Outcome /= Unknown
                       and then
                     Eval_2.Outcome /= Unknown);

      --  Not an MC/DC pair if both evaluations produced the same outcome

      if Eval_1.Outcome = Eval_2.Outcome then
         return No_Condition_Index;
      end if;

      --  Look for first condition evaluated in both evaluations and with
      --  different value in both, and check whether it is the only one.

      for J in 0 .. Condition_Index'Max
        (Eval_1.Values.Last_Index, Eval_2.Values.Last_Index)
      loop
         Check_Condition : declare
            function Cond_J
              (V : Condition_Evaluation_Vectors.Vector) return Tristate;
            --  Return the value of condition J in V, or Unknown if not
            --  evaluated.

            ------------
            -- Cond_J --
            ------------

            function Cond_J
              (V : Condition_Evaluation_Vectors.Vector) return Tristate
            is
            begin
               if J in V.First_Index .. V.Last_Index then
                  return V.Element (J);
               else
                  return Unknown;
               end if;
            end Cond_J;

            Val_1 : constant Tristate := Cond_J (Eval_1.Values);
            Val_2 : constant Tristate := Cond_J (Eval_2.Values);

         --  Start of processing for Check_Condition

         begin
            if Val_1 /= Unknown and then Val_2 /= Unknown
              and then Val_1 /= Val_2
            then
               if First_Different = No_Condition_Index then
                  First_Different := J;

               else
                  --  More than one condition had different values in both
                  --  evaluations: not an MC/DC pair.

                  return No_Condition_Index;
               end if;
            end if;
         end Check_Condition;
      end loop;

      return First_Different;
   end Is_MC_DC_Pair;

end MC_DC;
