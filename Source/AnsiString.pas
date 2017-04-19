namespace RemObjects.Elements.System;

type

  AnsiString = public record(IDisposable, IEnumerable<AnsiChar>, IEnumerable)
  private

    method GetChar(aIndex: UInt32): AnsiChar;
    begin
      if aIndex >= Length then exit #0;
      var p := chars + aIndex;
      exit p^;
    end;

    method SetChar(aIndex: UInt32; aChar: AnsiChar);
    begin
      if aIndex >= Length then exit;
      var p := chars + aIndex;
      p^ := aChar;
    end;

    chars: ^AnsiChar;
  protected
  public

    method GetEnumerator: IEnumerator<AnsiChar>;iterator;
    begin
      var p := chars;
      var cntr: UInt32 := 0;
      repeat
        yield p^;
        inc(p);
        inc(cntr);
      until (p^ = #0) or (cntr >= Length);
    end;

    method GetNonGenericEnumerator: IEnumerator; implements IEnumerable.GetEnumerator;
    begin
      exit self.GetEnumerator;
    end;

    method Dispose;
    begin
      rtl.free(chars);
      rtl.free(@self);
    end;

    constructor(aInitialSize: Integer);
    begin
      chars := ^AnsiChar(rtl.malloc(aInitialSize + 1)); //+1 = null termination char at end of string
    end;

    constructor(aValue: ^AnsiChar);
    begin
      Length := rtl.strlen(aValue);
      chars := ^AnsiChar(rtl.malloc(Length + 1)); 
      rtl.stpncpy(aValue, chars, Length + 1);
    end;

    constructor(aValue: ^Char);
    begin
      Length := rtl.wcslen(aValue);
      chars := ^AnsiChar(rtl.malloc(Length + 1)); 
      var p := chars;
      for i: UInt32 := 0 to Length do //not length -1 because we want to copy the null termination char
      begin
        p^ := AnsiChar(aValue^);
        inc(p);
        inc(aValue);
      end;
    end;

    constructor(aValue: String);
    begin
      Length := aValue.Length;
      chars := ^AnsiChar(rtl.malloc(Length + 1)); 
      var p := chars;
      for i: UInt32 := 0 to Length - 1 do 
      begin
        p^ := AnsiChar(aValue[i]);
        inc(p);
      end;
      p^ := #0; //null termination
    end;

    class operator Implicit(aValue: ^AnsiChar): AnsiString;
    begin
      exit new AnsiString(aValue);
    end;

    class operator Implicit(aValue: ^Char): AnsiString;
    begin
      exit new AnsiString(aValue);
    end;

    class operator Implicit(aValue: String): AnsiString;
    begin
      exit new AnsiString(aValue);
    end;

    class operator Add(aLeft, aRight: AnsiString): AnsiString;
    begin
      if (Object(aLeft) = nil) or (aLeft.Length = 0) then exit aRight;
      if (Object(aRight) = nil) or (aRight.Length = 0) then exit aLeft;
      result := ^AnsiChar(rtl.malloc(aLeft.Length + aRight.Length));
    end;

    property Char[aIndex: UInt32]: AnsiChar read GetChar write SetChar; default;

    //public Fields
    Length: UInt32;

    method Testje;
    begin
      var s: AnsiString := 'Test';
      var s2 := s + 'Bar';
    end;

  end;

end.
