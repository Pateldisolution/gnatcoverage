with Silent_Last_Chance, Support, FUAND_Helper; use Support;

procedure Test_FUAND_F_RX is
begin
   FUAND_Helper.Eval_FX_F;
   FUAND_Helper.Eval_RX;
end;

--# fuand.adb
--  /eval/  l+ 0
--  /true/  l- s-
--  /false/ l+ 0