package body Orelse is
   function Or_Else (A, B : Boolean) return Boolean is
   begin
      return A or else B;  -- # evalStmt
   end;
end;

