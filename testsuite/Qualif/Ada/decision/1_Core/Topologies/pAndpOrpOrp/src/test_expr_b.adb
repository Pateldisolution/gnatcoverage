with Support, Expr; use Support, Expr;

procedure Test_Expr_B is
begin
   Assert (F (True, True, False, False) = True);
   Assert (F (True, False, False, False) = False);
end;

--# expr.adb
--  /eval/  l+ ## 0
--  /retTrue/  l+ ## 0
--  /retFalse/ l+ ## 0
--  /retVal/   l+ ## 0
