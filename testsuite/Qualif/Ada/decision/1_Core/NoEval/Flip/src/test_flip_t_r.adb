with Silent_Last_Chance, Support, Flip_Helper; use Support, Flip_Helper;

procedure Test_Flip_T_R is
begin
   Flip_Helper.Eval_T;
   Flip_Helper.Eval_R;
end;

--# flip.adb
--  /eval/  l! dT-
--  /false/  l+ 0
--  /true/ l- s-
