with A1A2, Support; use A1A2, Support;

procedure Test_A1A2_A_D is
begin
   Assert (F (A => True, B => True, C => True, D => True));
   Assert (not F (A => False, B => True, C => True, D => False));
end;

--# a1a2.adb
-- /evals/ l! c!:"B" # c!:"C"

