unit IdGlobalProtocols;

interface


type
  TIdFileName = String;
  
function FileSizeByName(const AFilename: TIdFileName): Int64;

implementation

uses Classes, SysUtils;
type
  TIdReadFileExclusiveStream = class(TFileStream)
  public
    constructor Create(const AFile : String);
  end;

constructor TIdReadFileExclusiveStream.Create(const AFile : String);
begin
  inherited Create(AFile, fmOpenRead or fmShareDenyWrite);
end;

// OS-independant version
function FileSizeByName(const AFilename: TIdFileName): Int64;
//Leave in for HTTP Server
{$IFDEF DOTNET}
var
  LFile : System.IO.FileInfo;
{$ELSE}
  {$IFDEF USE_INLINE} inline; {$ENDIF}
  {$IFDEF WINDOWS}
var
  LHandle : THandle;
  LRec : TWin32FindData;
    {$IFDEF WIN32_OR_WIN64}
  LOldErrorMode : Integer;
    {$ENDIF}
  {$ENDIF}
  {$IFDEF UNIX}
var
    {$IFDEF USE_VCL_POSIX}
  LRec : _Stat;
      {$IFDEF USE_MARSHALLED_PTRS}
  M: TMarshaller;
      {$ENDIF}
    {$ELSE}
      {$IFDEF KYLIXCOMPAT}
  LRec : TStatBuf;
      {$ELSE}
  LRec : TStat;
  LU : time_t;
      {$ENDIF}
    {$ENDIF}
  {$ENDIF}
  {$IFNDEF NATIVEFILEAPI}
var
  LStream: TIdReadFileExclusiveStream;
  {$ENDIF}
{$ENDIF}
begin
  {$IFDEF DOTNET}
  Result := -1;
  LFile := System.IO.FileInfo.Create(AFileName);
  if LFile.Exists then begin
    Result := LFile.Length;
  end;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Result := -1;
  //check to see if something like "a:\" is specified and fail in that case.
  //FindFirstFile would probably succede even though a drive is not a proper
  //file.
  if not IsVolume(AFileName) then begin
    {
    IMPORTANT!!!

    For servers in Windows, you probably want the API call to fail rather than
    get a "Cancel   Try Again   Continue " dialog-box box if a drive is not
    ready or there's some other critical I/O error.
    }
    {$IFDEF WIN32_OR_WIN64}
    LOldErrorMode := SetErrorMode(SEM_FAILCRITICALERRORS);
    try
    {$ENDIF}
      LHandle := Windows.FindFirstFile(PIdFileNameChar(AFileName), LRec);
      if LHandle <> INVALID_HANDLE_VALUE then begin
        Windows.FindClose(LHandle);
        if (LRec.dwFileAttributes and Windows.FILE_ATTRIBUTE_DIRECTORY) = 0 then begin
          Result := (Int64(LRec.nFileSizeHigh) shl 32) + LRec.nFileSizeLow;
        end;
      end;
    {$IFDEF WIN32_OR_WIN64}
    finally
      SetErrorMode(LOldErrorMode);
    end;
    {$ENDIF}
  end;
  {$ENDIF}
  {$IFDEF UNIX}
  Result := -1;
    {$IFDEF USE_VCL_POSIX}
  //This is messy with IFDEF's but I want to be able to handle 63 bit file sizes.
  if stat(
      {$IFDEF USE_MARSHALLED_PTRS}
    M.AsAnsi(AFileName).ToPointer
      {$ELSE}
    PAnsiChar(
        {$IFDEF STRING_IS_ANSI}
      AFileName
        {$ELSE}
      AnsiString(AFileName) // explicit convert to Ansi
        {$ENDIF}
    )
      {$ENDIF}
    , LRec) = 0 then
  begin
    Result := LRec.st_size;
  end;
    {$ELSE}
  //Note that we can use stat here because we are only looking at the date.
  if {$IFDEF KYLIXCOMPAT}stat{$ELSE}fpstat{$ENDIF}(
    PAnsiChar(
      {$IFDEF STRING_IS_ANSI}
      AFileName
      {$ELSE}
      AnsiString(AFileName) // explicit convert to Ansi
      {$ENDIF}
    ), LRec) = 0 then
  begin
    Result := LRec.st_Size;
  end;
    {$ENDIF}
  {$ENDIF}
  {$IFNDEF NATIVEFILEAPI}
  Result := -1;
  if FileExists(AFilename) then begin
    LStream := TIdReadFileExclusiveStream.Create(AFilename);
    try
      Result := LStream.Size;
    finally
      LStream.Free;
    end;
  end;
  {$ENDIF}
end;

end.
