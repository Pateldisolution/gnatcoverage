with A1O2, Support; use A1O2, Support;

procedure Test_A1O2_F_D is
begin
   Assert (not F (A => True, B => False, C => False, D => False));
   Assert (not F (A => False, B => True, C => False, D => True));
end;

--# a1o2.adb
-- /evals/ l! dT-:"A and then B" # c!:"C"

