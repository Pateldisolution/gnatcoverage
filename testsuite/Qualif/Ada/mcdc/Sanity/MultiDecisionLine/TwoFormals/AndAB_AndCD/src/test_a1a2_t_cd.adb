with A1A2, Support; use A1A2, Support;

procedure Test_A1A2_T_CD is
begin
   Assert (F (A => True, B => True, C => True, D => True));
   Assert (F (A => True, B => True, C => True, D => False));
   Assert (F (A => True, B => True, C => False, D => True));
end;

--# a1a2.adb
-- /evals/ l! dF-:"A and then B"

