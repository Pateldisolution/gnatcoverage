with Support, A1A1; use Support, A1A1;

-- Exercise single vector #3: A True, B True.
-- Expect and-then True only

procedure Test_A1A1_V3 is
begin
   Assert (F (A => True, B => True));
end;

--# a1a1.adb
-- /evals/  l! dF-:"A and then B," # dF-:"A and then B\)"
