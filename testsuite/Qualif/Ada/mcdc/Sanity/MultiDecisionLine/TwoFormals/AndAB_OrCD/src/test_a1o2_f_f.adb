with A1O2, Support; use A1O2, Support;

procedure Test_A1O2_F_F is
begin
   Assert (not F (A => True, B => False, C => False, D => False));
   Assert (not F (A => False, B => False, C => False, D => False));
   Assert (not F (A => False, B => True, C => False, D => False));
   
   Assert (not F (A => False, B => True, C => False, D => False));
end;

--# a1o2.adb
-- /evals/ l! dT-:"A and then B" # dT-:"C or else D"

