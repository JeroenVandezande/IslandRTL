namespace RemObjects.Elements.System;

uses
  rtl;

type

  atexitfunc = public procedure();

  atexitrec = record
  public
    func: atexitfunc;
    next: ^atexitrec;
  end;

  ExternalCalls = public static class
  private
    class var atexitlist: ^atexitrec;
  public
    [SymbolName('_elements_posix_exception_handler'), CallingConvention(CallingConvention.Stdcall)]
    method ExceptionHandler(); empty;
    [SymbolName('ElementsRaiseException')]
    method RaiseException(aRaiseAddress: ^Void; aRaiseFrame: ^Void; aRaiseObject: Object);
    begin
      InternalCalls.VoidAsm("BKPT", "", false, false);
    end;

    const ElementsExceptionCode: UInt64 = $E042881952454d4f;

    [SymbolName('atexit')]
    class method atexit(func: atexitfunc); empty;
    [SymbolName('ElementsBeginCatch')]
    method ElementsBeginCatch(obj: ^Void): ^Void; empty;

    [SymbolName('ElementsEndCatch')]
    method ElementsEndCatch; empty;
    [SymbolName('ElementsGetExceptionForEHData')]
    method GetExceptionForEH(val: ^Void): ^Void; empty;

    [SymbolName('ElementsRethrow')]
    method ElementsRethrow; empty;

    class var nargs: Integer;
    class var args: ^^AnsiChar;
    class var envp: ^^AnsiChar;
    class var
      [SymbolName('__init_array_start')]
      __init_array_start: Integer; external;
      [SymbolName('__init_array_end')]
      __init_array_end: Integer; external;
  end;

end.
