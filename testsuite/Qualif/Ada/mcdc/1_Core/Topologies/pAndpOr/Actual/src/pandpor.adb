with Support; use Support;

package body PandPor is

   function F (A, B, C : Boolean) return Boolean is
   begin
      return Value ((A and then B) or else C);   -- # evalStmt :o/e:
   end;
end;
