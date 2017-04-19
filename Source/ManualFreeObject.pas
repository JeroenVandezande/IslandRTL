namespace RemObjects.Elements.System;

type

  UnmanagedObject = public class(Object, IDisposable)
  public
    method Dispose;
    begin
      rtl.free(@self);
    end;

    method Free;
    begin
      rtl.free(@self);
    end;
  end;

end.
