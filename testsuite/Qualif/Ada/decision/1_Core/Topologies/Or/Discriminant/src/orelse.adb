package body Orelse is

   type Expr (Value : Boolean) is null record;

   function Or_Else (A, B : Boolean) return Boolean is
      E : Expr (Value => A or else B); -- # orelse :o/0:
   begin
      return E.Value;  -- # retVal
   end;
end;


