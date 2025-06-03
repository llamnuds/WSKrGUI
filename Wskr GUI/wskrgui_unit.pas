// EFS running as a service    service "where name='efs'" get Started

unit WskrGUI_unit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  Menus, ActnList, ExtCtrls, ComCtrls, uPSComponent, Process;

type


  { TMain }

  TMain = class(TForm)
    GoBTN: TButton; // Button for executing the main action
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    Range_To: TEdit;
    Range_From: TEdit;
    FindFree_BTN: TRadioButton;
    GroupBox2: TGroupBox;
    SearchItem_GroupBox: TGroupBox;
    Range_GroupBox: TGroupBox;
    From_GroupBox: TGroupBox;
    Collection_GroupBox: TGroupBox;
    Collection: TMemo;
    To_GroupBox: TGroupBox;
    Item: TEdit;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    Results: TMemo;
    ShowTimings: TCheckBox;
    ShowSummary: TCheckBox; // First checkbox option
    CheckBox2: TCheckBox; // Second checkbox option
    Delay: TEdit;
    FindUserFile_BTN: TRadioButton;
    FindBitLocker_BTN: TRadioButton;
    GroupBox1: TGroupBox;
    FindPing_BTN: TRadioButton;
    StatusBar1: TStatusBar;
    WMIC_BTN: TRadioButton;
    ShowFailures: TCheckBox;
    ShowOptions: TCheckGroup; // Group of checkboxes for showing options
    FindFile_BTN: TRadioButton; // Radio button for finding a file
    FindRegistryValue_BTN: TRadioButton; // Radio button for finding a registry value
    OpenRangeFile: TOpenDialog; // Open dialog to select the Collection file
    SearchForA: TRadioGroup; // Radio group for search options
    ShowSuccesses: TCheckBox;
    procedure GoBTNClick(Sender: TObject); // Event handler for GoBTN click
    procedure DelayChange(Sender: TObject);
    procedure MenuItem10Click(Sender: TObject);
    procedure MenuItem11Click(Sender: TObject);
    procedure MenuItem12Click(Sender: TObject);
    procedure MenuItem13Click(Sender: TObject);
    procedure MenuItem14Click(Sender: TObject);
    procedure MenuItem15Click(Sender: TObject);
    procedure MenuItem16Click(Sender: TObject);
    procedure MenuItem17Click(Sender: TObject);
    procedure MenuItem4Click(Sender: TObject);
    procedure MenuItem5Click(Sender: TObject);
    procedure MenuItem6Click(Sender: TObject);
    procedure MenuItem7Click(Sender: TObject);
    procedure MenuItem8Click(Sender: TObject);
    procedure MenuItem9Click(Sender: TObject);
    procedure Range_ToChange(Sender: TObject);
    procedure FindBitLocker_BTNChange(Sender: TObject);
    procedure FindDir_BTNChange(Sender: TObject);
    procedure FindFile_BTNChange(Sender: TObject);
    procedure FindFree_BTNChange(Sender: TObject);
    procedure FindPing_BTNChange(Sender: TObject);
    procedure FindProcess_BTNChange(Sender: TObject);
    procedure FindRegistryValue_BTNChange(Sender: TObject);
    procedure FindService_BTNChange(Sender: TObject);
    procedure FindUserFile_BTNChange(Sender: TObject);
    procedure Range_FromChange(Sender: TObject);
    procedure MenuItem2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject); // Event handler for form creation
    procedure CollectionChange(Sender: TObject);
    procedure WMIC_BTNChange(Sender: TObject);
  private

  public
       CollectionIsAvailable: Boolean;
       RangeIsAvailable: Boolean;
       WSKrEXE: string;
       TMP_FileName: string;
   end;

var
  Main: TMain;

implementation

{$R *.lfm}

{ TMain }

// Function to count the number of checked items in a TCheckGroup
function CountCheckedInGroup(CheckGroup: TCheckGroup): Integer;
var
  i,CheckedCount: Integer;
  CheckBox: TCheckBox;
begin
CheckedCount :=0;
for i := 0 to CheckGroup.ControlCount - 1 do
 begin
   if CheckGroup.Controls[i] is TCheckBox then
   begin
     CheckBox := TCheckBox(CheckGroup.Controls[i]);
     if CheckBox.Checked then
     begin
          inc(CheckedCount);
     end;
   end;
 end;
  Result := CheckedCount;
end;


function LaunchExe(const Executable: string; const Params: array of string;
                   out ExitCode: Integer; ResultsMemo: TMemo): string;
var
  AProcess: TProcess;
  OutputBuffer: array[0..2047] of Byte;
  BytesRead: LongInt;
  OutputString: AnsiString;
  FullOutput: TStringList;
  i: Integer;
  LineBuffer: string;
  j: Integer;
begin
  Result := '';
  FullOutput := TStringList.Create;
  LineBuffer := '';

  try
    AProcess := TProcess.Create(nil);
    try
      // Set the executable path
      AProcess.Executable := Executable;

      // Add parameters
      AProcess.Parameters.Clear;
      for i := Low(Params) to High(Params) do
        AProcess.Parameters.Add(Params[i]);

      // Redirect input and output
      AProcess.Options := AProcess.Options + [poUsePipes, poStdErrToOutput];

      // Start the process
      AProcess.Execute;

      // Read the output
      while AProcess.Running or (AProcess.Output.NumBytesAvailable > 0) do
      begin
        if AProcess.Output.NumBytesAvailable > 0 then
        begin
          BytesRead := AProcess.Output.Read(OutputBuffer, SizeOf(OutputBuffer) - 1);
          if BytesRead > 0 then
          begin
            // Ensure null-termination
            OutputBuffer[BytesRead] := 0;

            // Decode using UTF-8
            OutputString := AnsiString(TEncoding.UTF8.GetString(OutputBuffer, 0, BytesRead));
            OutputString := StringReplace(OutputString, #10, LineEnding, [rfReplaceAll]);
            // Append to line buffer
            LineBuffer := LineBuffer + string(OutputString);

            // Process complete lines
            while Pos(LineEnding, LineBuffer) > 0 do
            begin
              i := Pos(LineEnding, LineBuffer);
              // Extract a complete line
              OutputString := AnsiString(Copy(LineBuffer, 1, i - 1));
              // Remove the processed line from buffer
              Delete(LineBuffer, 1, i + Length(LineEnding) - 1);

              // Add to our full output collection
              FullOutput.Add(string(OutputString));

              // Update the memo directly
              ResultsMemo.Lines.Add(string(OutputString));
            end;

            // Force immediate display update
            ResultsMemo.SelStart := Length(ResultsMemo.Text);
            ResultsMemo.Refresh;

            // Process messages to keep UI responsive
            Application.ProcessMessages;
          end;
        end
        else
        begin
          // Process Windows messages to keep UI responsive
          Application.ProcessMessages;
          Sleep(10); // Prevent CPU hogging
        end;
      end;

      // Process any remaining text in the buffer (last line might not end with a line ending)
      if LineBuffer <> '' then
      begin
        FullOutput.Add(LineBuffer);
        ResultsMemo.Lines.Add(LineBuffer);
      end;

      // Wait for the process to finish
      AProcess.WaitOnExit;
      ExitCode := AProcess.ExitCode;

      // Return the complete output
      Result := FullOutput.Text;
    finally
      AProcess.Free;
    end;
  except
    on E: Exception do
    begin
      ResultsMemo.Lines.Add('Error executing ' + Executable + ': ' + E.Message);
      Result := 'Error: ' + E.Message;
    end;
  end;

  FullOutput.Free;
end;



function GetAlphaPrefix(const InputStr: string): string;
  var
    i: Integer;
  begin
    Result := '';
    i := 1;

    // Collect alphabetic characters from the start of the string
    while (i <= Length(InputStr)) and (InputStr[i] in ['A'..'Z', 'a'..'z']) do
    begin
      Result := Result + InputStr[i];
      Inc(i);
    end;
  end;

function GetNumericPart(const InputStr: string): Integer;
var
  i, Start: Integer;
  NumStr: string;
begin
  NumStr := '';
  Start := 1;

  // Find the start of the numeric part
  while (Start <= Length(InputStr)) and (InputStr[Start] in ['A'..'Z', 'a'..'z']) do
    Inc(Start);

  // Collect numeric characters
  for i := Start to Length(InputStr) do
  begin
    if InputStr[i] in ['0'..'9'] then
      NumStr := NumStr + InputStr[i]
    else
      Break;
  end;

  // Convert the numeric part to an integer
  if NumStr <> '' then
    Result := StrToInt(NumStr)
  else
    Result := -1; // Return -1 if there's no valid numeric part
end;


function IsValidName(const aName: string): Boolean;
var
  i, Len: Integer;
  HasLetter, HasDigit: Boolean;
begin
  Len := Length(aName);
  HasLetter := False;
  HasDigit := False;

  // Check if the string starts with letters
  i := 1;
  while (i <= Len) and (aName[i] in ['A'..'Z', 'a'..'z']) do
  begin
    HasLetter := True;
    Inc(i);
  end;

  // Check if the string follows with digits
  while (i <= Len) and (aName[i] in ['0'..'9']) do
  begin
    HasDigit := True;
    Inc(i);
  end;

  // If there's anything left after the digits, it's invalid
  if (i <= Len) then
    Result := False
  else
    Result := HasLetter and HasDigit;
end;


function SaveMemoToTempFile(const TMP_FileName: string;Memo: TMemo):string;
var
  TempFolder: string;
  FilePath: string;
begin
  // Get the %TEMP% folder path
  TempFolder := GetEnvironmentVariable('TEMP');
  if TempFolder = '' then
  begin
    ShowMessage('Unable to locate the temporary folder.');
    Result := '';
    Exit;
  end;

  // Combine folder and file name to create the full path
  FilePath := IncludeTrailingPathDelimiter(TempFolder) + TMP_FileName;

  // Save TMemo contents to the file
  try
    Memo.Lines.SaveToFile(FilePath);
  except
    on E: Exception do
      begin
        ShowMessage('Error saving file: ' + E.Message);
        Result := '';
        Exit;
      end;
  end;
  Result := FilePath;
end;


procedure TMain.FormCreate(Sender: TObject);
begin
  CollectionIsAvailable := false;
  RangeIsAvailable := false;
  TMP_FileName := 'TMP_WSKGUI.txt';
  WSKrEXE := ExtractFilePath(ParamStr(0)) + 'wskr.exe';
  if not FileExists(WSKrEXE) then
  begin
    ShowMessage('WSKR.EXE not found at: '+ExtractFilePath(ParamStr(0)));
    WSKrEXE := '';
  end;
end;

procedure TMain.CollectionChange(Sender: TObject);
begin
  If Collection.Lines.Count > 0 then
    begin
      CollectionIsAvailable := true;
      Collection_GroupBox.Font.Color:= clGreen;

      RangeIsAvailable := false;
      Range_GroupBox.Font.Color:= clRed;
    end
  else
    begin
      CollectionIsAvailable := false;
      Collection_GroupBox.Font.Color:= clRed;
    end;
end;

procedure TMain.WMIC_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.GoBTNClick(Sender: TObject);
var
  optionCount: Integer;
  ok: boolean;
  TempFilePath: string;
  WSKrParams: TStringList;
  WSKrParams_Array: array of string;
  i: Integer;
  WSKrParams_String: string;
  ShowThese: string;
  ExitCode: Integer; // Added for LaunchExe
begin
  ok := true;
  Results.Lines.Clear;
  Results.Refresh;
  WSKrParams := TStringList.Create;

  If ((Item.Text='') and (Item.Enabled)) then
  begin
    ok := false;
    ShowMessage('You need to type a search item into the search box.');
  end;

  optionCount := CountCheckedInGroup(ShowOptions);
  if optionCount = 0 then
  begin
    ok := false;
    ShowMessage('Please select at least one ShowOption.');
  end;

  If not (CollectionIsAvailable or RangeIsAvailable) then
  begin
    ok :=false;
    ShowMessage('Please identify Range or Collection first.');
  end;

  try
    if ok then
      begin
        if FindRegistryValue_BTN.Checked then
          begin
            WSKrParams.Add('--registry');
            WSKrParams.Add(Item.Text);
          end;

        if FindFile_BTN.Checked then
          begin
            WSKrParams.Add('--file');
            WSKrParams.Add(Item.Text);
          end;

        if FindUserFile_BTN.Checked then
          begin
            WSKrParams.Add('--userfile');
            WSKrParams.Add(Item.Text);
          end;

        if WMIC_BTN.Checked then
          begin
            WSKrParams.Add('--wmic');
            WSKrParams.Add(Item.Text);
          end;

        if FindBitLocker_BTN.Checked then
          begin
            WSKrParams.Add('--bitlocker');
          end;

        if FindPing_BTN.Checked then
          begin
            WSKrParams.Add('--ping');
          end;

        if FindFree_BTN.Checked then
          begin
            WSKrParams.Add('--free');
          end;

        ShowThese := '';

        if ShowSuccesses.Checked then
          begin
            ShowThese := ShowThese + '1';
          end;

        if ShowFailures.Checked then
          begin
            ShowThese := ShowThese + '0';
          end;

        if (ShowSuccesses.Checked or ShowFailures.Checked)then
          begin
            WSKrParams.Add('--show='+ShowThese);
          end;

        if ShowSummary.Checked then
          begin
            WSKrParams.Add('--summary');
          end;

        if ShowTimings.Checked then
        begin
          WSKrParams.Add('--timings');
        end;

        if Delay.Text <> '0' then
          begin
            WSKrParams.Add('--delay='+delay.Text);
          end;

        WSKrParams.Add('--confirm');

        if CollectionIsAvailable then
        begin
          Results.Lines.Add('Using the following Collection...');
          Results.Lines.Add(Collection.Lines.Text);
        end;

        if RangeIsAvailable then
        begin
          Results.Lines.Add('Using Range...');
          Results.Lines.Add('From = '+Range_From.Text);
          Results.Lines.Add('To = '+Range_To.Text);
        end;

        // * * * Before launching WSKr * * *
        // If using a COLLECTION then save the collection to a temp file
        // and add a --range param to use it.
        // Delete any previous temp files before creating this one.
        If CollectionIsAvailable then
        Begin
          TempFilePath := SaveMemoToTempFile(TMP_FileName,Collection);
          WSKrParams.Add('--range='+TempFilePath);
        end;

        // If using a RANGE then add a matching --range param to use it.
        If RangeIsAvailable then
        begin
          WSKrParams.Add('--range='+Range_From.Text+'..'+Range_To.Text);
        end;

        if WSKrEXE = '' then
        begin
          Results.Lines.Add('WSKr EXE not found.');
        end
        else
        begin
          // Set the size of the dynamic array to match the TStringList
          SetLength(WSKrParams_Array, WSKrParams.Count);

          // Populate the array with values from the TStringList
          WSKrParams_String := '';
          for i := 0 to WSKrParams.Count - 1 do
          begin
            WSKrParams_Array[i] := WSKrParams[i];
            WSKrParams_String := WSKrParams_String + ' ' + WSKrParams[i];
          end;

          Results.Lines.Add('Running command: ' + WSKrEXE + WSKrParams_String);

          // Call the LaunchExe function and pass the Results memo directly
          LaunchExe(WSKrEXE, WSKrParams_Array, ExitCode, Results);

          // Display exit code (optional)
          Results.Lines.Add('Process completed with exit code: ' + IntToStr(ExitCode));
        end;
    end;
  finally
    WSKrParams.Free;
  end;
end;




procedure TMain.DelayChange(Sender: TObject);
begin
  try

    if (StrToInt(Delay.Text) < 0) then
    begin
      Delay.text := '0';
    end;

    if (StrToInt(Delay.Text) > 10) then
    begin
      Delay.Text := '10';
    end;

  except
    on E: EConvertError do
      Delay.text :='0';
  end;
end;

procedure TMain.MenuItem10Click(Sender: TObject);
begin
  Item.Text := 'os get version';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem11Click(Sender: TObject);
begin
  Item.Text := 'product get name,vendor,version';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem12Click(Sender: TObject);
begin
  Item.Text := 'bios get serialnumber';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem13Click(Sender: TObject);
begin
  Item.Text := 'printerconfig list';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem14Click(Sender: TObject);
begin
  Item.Text := 'nicconfig get IPAddress,dhcpserver,defaultipgateway';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem15Click(Sender: TObject);
begin
  Item.Text := 'systemenclosure get SMBIOSAssetTag';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem16Click(Sender: TObject);
begin
  Item.Text := 'computersystem get /format:hform';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem17Click(Sender: TObject);
begin
  Item.Text := 'service "where name=''efs''" get Started';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem9Click(Sender: TObject);
begin
  Item.Text := 'computersystem get username';
  Item.Enabled := true;
  WMIC_BTN.Checked:=true;
end;

procedure TMain.MenuItem4Click(Sender: TObject);
begin
     ShowMessage('RESTRICTIONS' + LineEnding + LineEnding +
      'The following are not allowed in conjunction with WMIC :-' + LineEnding +
      '   CALL' + LineEnding +
      '   CREATE' + LineEnding +
      '   UNINSTALL' + LineEnding +
      '   DELETE' + LineEnding +
      '   JSCRIPT.DLL' + LineEnding +
      '   VBSCRIPT.DLL' + LineEnding +
      '   SHADOWCOPY');
end;

procedure TMain.MenuItem5Click(Sender: TObject);
begin
     ShowMessage('REQUIREMENTS' + LineEnding + LineEnding +
      '    The machine you are running this on must be' + LineEnding +
      '    running Windows.' + LineEnding +LineEnding +
      '    PING is reliant on Windows PING.EXE' + LineEnding + LineEnding +
      '    WMIC is reliant on Windows WMIC.EXE' + LineEnding + LineEnding +
      '    REGISTRY is reliant on Windows REG.EXE');

end;

procedure TMain.MenuItem6Click(Sender: TObject);
begin
  ShowMessage('                         WSKr GUI' + LineEnding + LineEnding +
              '                         Author: Shaun DUNMALL' + LineEnding + LineEnding +
              '                         (C) 2024');
end;

procedure TMain.MenuItem7Click(Sender: TObject);
begin
     ShowMessage('ASSUMPTIONS' +LineEnding + LineEnding +
      '  Your machine names have at least one character at the start,' + LineEnding +
      '  followed by at least one digit.' + LineEnding + LineEnding +
      '  The machines you are scanning are running Windows.' + LineEnding + LineEnding +
      '  You have sufficient rights on the remote machines.' + LineEnding + LineEnding +
      '  Ensure that WMI service is enabled and running on the' + LineEnding +
      '  remote machines.' + LineEnding +LineEnding +
      '  Ensure any required firewall ports are open between your' + LineEnding +
      '  machine and the remote machines.');

end;

procedure TMain.MenuItem8Click(Sender: TObject);
begin

end;

procedure TMain.Range_ToChange(Sender: TObject);
begin

    Range_To.Text := Trim(Range_To.Text);

    If (Range_From.Text='') or (Range_To.Text='') then
    Begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end
  else
    begin
      RangeIsAvailable := true;
      Range_GroupBox.Font.Color:= clGreen;

      CollectionIsAvailable := false;
      Collection_GroupBox.Font.Color:= clRed;
    end;

    If Range_From.Text=Range_To.Text then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    If not IsValidName(Range_From.Text) or not IsValidName(Range_To.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    if  GetAlphaPrefix(Range_From.Text) <> GetAlphaPrefix(Range_To.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    If GetNumericPart(Range_To.Text) <= GetNumericPart(Range_From.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    if Length(Range_To.Text) < Length(Range_From.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

end;

procedure TMain.FindBitLocker_BTNChange(Sender: TObject);
begin
  Item.Enabled:=false;
end;

procedure TMain.FindDir_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.FindFile_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.FindFree_BTNChange(Sender: TObject);
begin
  Item.Enabled:=false;
end;

procedure TMain.FindPing_BTNChange(Sender: TObject);
begin
  Item.Enabled:=false;
end;

procedure TMain.FindProcess_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.FindRegistryValue_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.FindService_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.FindUserFile_BTNChange(Sender: TObject);
begin
  Item.Enabled:=true;
end;

procedure TMain.Range_FromChange(Sender: TObject);
begin

    Range_From.Text := Trim(Range_From.Text);

    If (Range_From.Text='') or (Range_To.Text='') then
    Begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end
    else
    begin
      RangeIsAvailable := true;
      Range_GroupBox.Font.Color:= clGreen;

      CollectionIsAvailable := false;
      Collection_GroupBox.Font.Color:= clRed;
    end;

    If Range_From.Text=Range_To.Text then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    If not IsValidName(Range_From.Text) or not IsValidName(Range_To.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    if  GetAlphaPrefix(Range_From.Text) <> GetAlphaPrefix(Range_To.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    If GetNumericPart(Range_To.Text) <= GetNumericPart(Range_From.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    If GetNumericPart(Range_To.Text) = -1 then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    If GetNumericPart(Range_From.Text) = -1 then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

    if Length(Range_To.Text) < Length(Range_From.Text) then
    begin
      RangeIsAvailable := false;
      Range_GroupBox.Font.Color := clRed;
    end;

end;


procedure TMain.MenuItem2Click(Sender: TObject);
begin
    if OpenRangeFile.Execute() then
  begin
    try
      // Load the content of the selected file into the TMemo
      Collection.Lines.LoadFromFile(OpenRangeFile.FileName);
    except
      on E: Exception do
        // Show a message indicating an error occurred while loading the file
        ShowMessage('Error loading file: ' + E.Message);
    end;
    CollectionIsAvailable := true;
  end;
end;

end.

