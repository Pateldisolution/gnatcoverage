package body Andthen is
   function And_Then (A, B : Boolean) return Boolean is
   begin
      return Value : boolean := A and then B do   -- # evalStmt
        null; -- # returnValue
      end return;
   end;
end;

