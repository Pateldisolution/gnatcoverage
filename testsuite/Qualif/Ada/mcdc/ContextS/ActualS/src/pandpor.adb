package body PandPor is

   function One_Of (A, B : Boolean) return Boolean is
   begin
      return A;  -- # returnValue
   end;

   function F (A, B, C : Boolean) return Boolean is
   begin
      return One_Of ((A and then B) or else C,   -- # evalStmt
                     (A and then B) or else C);  -- # evalOther
   end;

end;
