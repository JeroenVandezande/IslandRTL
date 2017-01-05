﻿namespace RemObjects.Elements.System;

type
  TimeModifier = (Created, Updated, Accessed);


  FileUtils = assembly static class
  private
  protected
  public
    class method isFolder(Attr: {$IFDEF WINDOWS}rtl.DWORD{$ELSEIF POSIX OR BAREMETAL}rtl.__mode_t{$ELSE}{$ERROR}{$ENDIF}): Boolean; inline;
    begin
      {$IFDEF WINDOWS}
      if Attr = rtl.INVALID_FILE_ATTRIBUTES then exit false;
      exit (Attr and rtl.FILE_ATTRIBUTE_DIRECTORY) = rtl.FILE_ATTRIBUTE_DIRECTORY;
      {$ELSEIF BAREMETAL}
      //TODO
      {$ELSEIF POSIX}
      exit (Attr and rtl.S_IFMT) = rtl.S_IFDIR;	
      {$ELSE}{$ERROR}{$ENDIF}
    end;
    class method isFile(Attr: {$IFDEF WINDOWS}rtl.DWORD{$ELSEIF POSIX OR BAREMETAL}rtl.__mode_t{$ELSE}{$ERROR}{$ENDIF}): Boolean; inline;
    begin
      {$IFDEF WINDOWS}
      if Attr = rtl.INVALID_FILE_ATTRIBUTES then exit false;
      exit (Attr and rtl.FILE_ATTRIBUTE_DIRECTORY) <> rtl.FILE_ATTRIBUTE_DIRECTORY;
      {$ELSEIF BAREMETAL}
      //TODO
      {$ELSEIF POSIX}
      exit (Attr and rtl.S_IFMT) = rtl.S_IFREG;
      {$ELSE}{$ERROR}{$ENDIF}
    end;

    class method isFolderExists(aFullName: not nullable String): Boolean;
    begin
      {$IFDEF WINDOWS}
      exit isFolder(rtl.GetFileAttributesW(aFullName.ToFileName()));
      {$ELSEIF BAREMETAL}
      //TODO
      {$ELSEIF POSIX}
      exit isFolder(Get__struct_stat(aFullName)^.st_mode);
      {$ELSE}{$ERROR}{$ENDIF}
    end;

    class method isFileExists(aFullName: not nullable String): Boolean;
    begin
      {$IFDEF WINDOWS}
      exit FileUtils.isFile(rtl.GetFileAttributesW(aFullName.ToFileName()));
      {$ELSEIF BAREMETAL}
      //TODO
      {$ELSEIF POSIX}
      exit FileUtils.isFile(FileUtils.Get__struct_stat(aFullName)^.st_mode);
      {$ELSE}{$ERROR}
      {$ENDIF}
    end;

    {$IFDEF POSIX}
    class method Get__struct_stat(aFullName: String): ^rtl.__struct_stat;inline;
    begin
      var sb: rtl.__struct_stat;
      CheckForIOError(rtl.stat(aFullName.ToFileName(),@sb));
      exit @sb;
    end;
    {$ENDIF}

    {$IFDEF POSIX AND NOT ANDROID}
    [SymbolName('stat')]
    method stat(file: ^AnsiChar; buf: ^rtl.__struct_stat): Int32;
    begin
      exit rtl.__xstat(rtl._STAT_VER, file, buf);
    end;

    [SymbolName('fstat')]
    method fstat(fd: Int32; buf: ^rtl.__struct_stat): Int32;
    begin
      exit rtl.__fxstat(rtl._STAT_VER, fd, buf);
    end;

    {$ENDIF}

  end;

{$IFDEF WINDOWS}
extension method String.ToLPCWSTR: rtl.LPCWSTR;
begin
  if String.IsNullOrEmpty(self) then exit nil;
  var arr := ToCharArray(true);
  exit rtl.LPCWSTR(@arr[0]);
end;

extension method String.ToFileName: rtl.LPCWSTR; assembly;
begin
  if String.IsNullOrEmpty(self) then exit nil;
  exit ((if not self.StartsWith('\\?\') then '\\?\' else '')+self).ToLPCWSTR();
end;
{$ENDIF}

{$IFDEF POSIX}
extension method String.ToFileName: ^AnsiChar;assembly;
begin
  exit @self.ToAnsiChars(True)[0];
end;
{$ENDIF}

end.
