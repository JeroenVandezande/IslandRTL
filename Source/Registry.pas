﻿namespace RemObjects.Elements.System;

type
  RegistryValueKind = public enum (String, ExpandString, Binary, DWord, MultiString, QWord, Unknown, None);

  Registry = public static class
  private

    method ParseKeyName(KeyName: String; out subKeyName: String): rtl.HKEY;
    begin
      if KeyName = nil then raise new Exception('KeyName cannot be null');
      var idx := KeyName.IndexOf('\');
      var l_hkey: String;
      if idx <> -1 then begin
        l_hkey := KeyName.Substring(0, idx).ToUpper;
        subKeyName := KeyName.Substring(idx+1,KeyName.Length - idx-1);
      end
      else begin
        l_hkey := KeyName.ToUpper;
        subKeyName := '';
      end;
      if l_hkey = CurrentUser then exit rtl.HKEY_CURRENT_USER
      else if l_hkey = LocalMachine then exit rtl.HKEY_LOCAL_MACHINE
      else if l_hkey = ClassesRoot then exit rtl.HKEY_CLASSES_ROOT
      else if l_hkey = Users then exit rtl.HKEY_USERS
      else if l_hkey = PerformanceData then exit rtl.HKEY_PERFORMANCE_DATA
      else if l_hkey = CurrentConfig then exit rtl.HKEY_CURRENT_CONFIG
      else if l_hkey = DynData then exit rtl.HKEY_DYN_DATA
      else raise new Exception('invalid KeyName');
    end;

  public
    const CurrentUser = 'HKEY_CURRENT_USER';
    const  LocalMachine = 'HKEY_LOCAL_MACHINE';
    const  ClassesRoot = 'HKEY_CLASSES_ROOT';
    const  Users = 'HKEY_USERS';
    const  PerformanceData = 'HKEY_PERFORMANCE_DATA';
    const  CurrentConfig = 'HKEY_CURRENT_CONFIG';
    const  DynData = 'HKEY_DYN_DATA';

    method GetValue(KeyName: String; ValueName: String;  defaultValue: Object): Object;
    begin
      var subKeyName: String;
      var lrootkey := ParseKeyName(KeyName, out subKeyName);
      var lsubKey := subKeyName.ToLPCWSTR;
      var lvaluename := ValueName.ToLPCWSTR;
      var &flags := rtl.RRF_RT_ANY;
      var dwtype : rtl.DWORD;
      var pcbData: rtl.DWORD;
      var res := rtl.RegGetValueW(lrootkey, lsubKey, lvaluename,&flags,@dwtype,nil, @pcbData);
      if res = rtl.ERROR_SUCCESS  then begin
        var buf := new array of Byte(pcbData);
        var bufref: ^Void := @buf[0];
        res:= rtl.RegGetValueW(lrootkey, lsubKey, lvaluename,&flags,@dwtype,bufref, @pcbData);
        if res = rtl.ERROR_SUCCESS  then begin
          case dwtype of
            rtl.REG_NONE,
            rtl.REG_BINARY:     exit buf;

            rtl.REG_DWORD:      exit ^Int32(bufref)^;
            rtl.REG_DWORD_BIG_ENDIAN: begin
              var temp: UInt32 := UInt32(buf[0]) shl 24 +
                                  UInt32(buf[1]) shl 16 +
                                  UInt32(buf[2]) shl 8  +
                                  UInt32(buf[3]);
              exit ^Int32(@temp)^;
            end;
            rtl.REG_SZ,
            rtl.REG_EXPAND_SZ,
            rtl.REG_LINK:      exit String.FromPChar(^Char(bufref));

            rtl.REG_MULTI_SZ:begin
              var s:= String.FromPChar(^Char(bufref),pcbData);
              if s.EndsWith(#0#0) then s:= s.Substring(0,s.Length-2);
              exit s.Split(#0);
            end;

            rtl.REG_QWORD:      exit ^Int64(bufref)^;
          end;
        end;
      end;
      if res <> rtl.ERROR_SUCCESS then
        raise new Exception('error code is '+res.ToString);
    end;

    method SetValue(KeyName: String; ValueName: String;  Value: Object);
    begin
      SetValue(KeyName,ValueName,Value,RegistryValueKind.Unknown);
    end;

    method SetValue(KeyName: String; ValueName: String; Value: Object; ValueKind: RegistryValueKind);
    begin
      var cbData: ^Void;
      var cbDataSize: rtl.DWORD;
      var cbDatatype: rtl.DWORD;

      case ValueKind of
        RegistryValueKind.String: begin
          var str:= Value.ToString;
          cbData := str.ToLPCWSTR;
          cbDataSize := str.Length*2+2;
          cbDatatype := rtl.REG_SZ;
        end;
        RegistryValueKind.ExpandString: begin
          var str:= Value.ToString;
          cbData := str.ToLPCWSTR;
          cbDataSize := str.Length*2+2;
          cbDatatype := rtl.REG_EXPAND_SZ;
        end;
        RegistryValueKind.Binary: begin
          if Value is array of Byte then begin
            var temp := Value as array of Byte ;
            cbData := @temp[0];
            cbDataSize := temp.Length;
            cbDatatype := rtl.REG_BINARY;
          end
          else begin
            raise new Exception('only `array of Byte` object is supported yet');
          end;
        end;
        RegistryValueKind.DWord: begin
          if Value is Int32 then begin
            var temp := Value as Int32;
            cbData := @temp;
            cbDataSize := 4;
            cbDatatype := rtl.REG_DWORD;
          end
          else begin
            raise new Exception('only `Int32` object is supported yet');
          end;
        end;
        RegistryValueKind.MultiString: begin
          if Value is array of String then begin
            var temp := Value as array of String;
            var cb:= new StringBuilder;
            for each m in temp do begin
              cb.Append(m);
              cb.Append(#0);
            end;
            cbData := cb.ToString.ToLPCWSTR;
            cbDataSize := cb.Length*2+2;
            cbDatatype := rtl.REG_MULTI_SZ;
          end
          else begin
            raise new Exception('only `array of String` object is supported yet');
          end;
        end;
        RegistryValueKind.QWord: begin
          if Value is Int64 then begin
            var temp := Value as Int64;
            cbData := @temp;
            cbDataSize := 8;
            cbDatatype := rtl.REG_QWORD;
          end
          else begin
            raise new Exception('only `Int64` object is supported yet');
          end;
        end;
        else begin
          // handle all other cases
          if Value is String then SetValue(KeyName,ValueName,Value,RegistryValueKind.String)
          else if Value is Int32 then SetValue(KeyName,ValueName,Value,RegistryValueKind.DWord)
          else if Value is Int64 then SetValue(KeyName,ValueName,Value,RegistryValueKind.QWord)
          else if Value is array of String then SetValue(KeyName,ValueName,Value,RegistryValueKind.MultiString)
          else if Value is array of Byte then SetValue(KeyName,ValueName,Value,RegistryValueKind.Binary)
          else raise new Exception('Unsupported Value');
          exit;
        end;
      end;

      var subKeyName: String;
      var lrootkey := ParseKeyName(KeyName, out subKeyName);
      var lsubKey := subKeyName.ToLPCWSTR;

      var res :=  rtl.RegSetKeyValueW(lrootkey, lsubKey, ValueName.ToLPCWSTR,cbDatatype,cbData, cbDataSize);
      if res <> rtl.ERROR_SUCCESS then
        raise new Exception('error code is '+res.ToString);
    end;
  end;

end.