with Support, A1o1; use Support, A1O1;

-- Exercise single vector #2: A True, B False.
-- Expect and-then False only, or-else True only

procedure Test_A1O1_V2 is
begin
   Assert (not F (A => True, B => False));
end;

--# a1o1.adb
-- /evals/  l! dT-:"A and then B" # dF-:"A or else B"
