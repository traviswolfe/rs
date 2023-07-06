program monkey;

Type STATES = (Rope, TropicalTree, SteppingStone, TropicalTree2, Monkeybars, SkullSlope, Logout, RunEnergyCheck);
Type TFuncNoArgsBool = function():Boolean;
Type state = record
    action : TFuncNoArgsBool;        //Function that defines the action/behavior
    verification : TFuncNoArgsBool;  //Function that verifies we're in the correct state
    nextState : STATES;              //State we should transition to upon success
    failedState : STATES;            //State we transition to upon failure
    gracePeriod : Integer;           //How long to wait for success to happen
    deadTime : Integer;              //How long to wait after success before performing action
    deadTimeVariance : Integer;      //Variance for dead time
  end;
Type statesArrayType = Array[0..Ord(High(STATES))] of state;
Var statesArray: statesArrayType;
function fcn(AFunction: TFuncNoArgsBool): Boolean;
begin
  result := AFunction()
end;

var
mouseTarX,mouseTarY,mouseTarTime,mouseStartTime,mouseXDelta,mouseYDelta,
mouseClicksLeft,mouseClickStart,mouseClickUntil,mouseClickDelay:Integer = 0;
mouseIsDown:Boolean = false;

hotkeysPause:Integer = 19; //pause script
hotkeysEscape:Integer = 27;//escape, close window or go to logout tab
hotkeysEnd:Integer = 35;   //stop script
hotkeysHome:Integer = 36;  //Logout
hotkeysPauseLatch,hotkeysHomeLatch,hotkeysPauseRequested:Boolean = false;


currentTime,verifiedTime,nextActionTime:Integer = 0;
verificationLimit:Integer = 10000;
done,verified,wasPaused,stateFound:Boolean = false;
currentState,st:STATES;



procedure Log(msg:String);
begin
  Write(FormatDateTime('hh:mm:ss',Now()) + ' : ');
  Write(currentState);
  WriteLn(': ' + msg);
end;

function variance(num:Integer;varianceAmount:Integer):Integer;
begin
  result := num - varianceAmount + RandomRange(0,varianceAmount) + RandomRange(0,varianceAmount);
end;

procedure MoveAndClick(X:Integer; Y:Integer; NumClicks:Integer);
var mouseCurrentX,mouseCurrentY:Integer;
begin
  //Get the current mouse position, calculate the delta the mouse needs to move
  //by. Then set the amount of time it should take to reach the destination,
  //as well as how long after it reaches the destination before clicking.
  GetMousePos(mouseCurrentX,mouseCurrentY);
  mouseTarX := X;
  mouseTarY := Y;
  mouseXDelta := mouseTarX - mouseCurrentX;
  mouseYDelta := mouseTarY - mouseCurrentY;
  mouseClicksLeft := NumClicks;
  mouseStartTime := GetTimeRunning();
  mouseTarTime := mouseStartTime + variance(220,80);
  mouseClickDelay := mouseTarTime + variance(150,30);
end;

procedure HandleMouse;
var percent: Double;
begin
  //if we haven't reached the target time, then mouse should be in middle
  //of a movement
  if(currentTime < mouseTarTime) then
  begin
    percent := 1 - ((currentTime - mouseStartTime) / (mouseTarTime - mouseStartTime));
    MoveMouse(Round(mouseTarX - (percent * mouseXDelta)),Round(mouseTarY - (percent * mouseYDelta)));
  end else
  //otherwise, we're not in the middle of a movement, and handle any clicks
  begin
    MoveMouse(mouseTarX,mouseTarY);
    //if there are clicks left to perform, and we haven't passed the delay
    //then wait until the delay has passed, and then perform a click
    if((mouseClicksLeft > 0) and (mouseClickDelay < currentTime)) then
    begin
      HoldMouse(mouseTarX,mouseTarY,mouse_Left);
      mouseClickUntil := currentTime + variance (100,30);
      mouseClickDelay := mouseClickUntil + variance (100,30);
      mouseClicksLeft := mouseClicksLeft - 1;
      mouseIsDown := true;
    end else if((mouseIsDown = true) and (mouseClickUntil < currentTime)) then
    //wait until we've held down the mouse for long enough, then release
    begin
      ReleaseMouse(mouseTarX,mouseTarY,mouse_Left);
      mouseIsDown := false;
    end;
  end;
end;

procedure CheckHotkeys;
begin
  //Check if script end is requested by pressing "end" key
  if(IsKeyDown(hotkeysEnd)) then
  begin
    Log('END key pressed. Exiting script.');
    Halt();
  end;

  //Check if script should be paused
  if(IsKeyDown(hotkeysPause) and (hotkeysPauseLatch = false)) then
  begin
    hotkeysPauseLatch := true;
    if(hotkeysPauseRequested) then
    begin
      Log('PAUSE key pressed. Resuming script.');
      hotkeysPauseRequested := false;
    end else
    begin
      Log('PAUSE key pressed. Pausing until PAUSE is pressed again.');
      hotkeysPauseRequested := true;
    end;
  end;
  //Unlatch Pause (prevents multiple pause/unpause situations when holding key for a long time)
  if(hotkeysPauseLatch and (IsKeyDown(hotkeysPause) = false)) then
  begin
    hotkeysPauseLatch := false;
  end;

  //Check if logout button pressed
  if(IsKeyDown(hotkeysHome) and (hotkeysHomeLatch = false)) then
  begin
    hotkeysHomeLatch := true;
    Log('HOME key pressed. Attempting logout and pausing.');
    //Logout();
    hotkeysPauseRequested := true;
  end;
  //Unlatch logout
  if(hotkeysHomeLatch and (IsKeyDown(hotkeysHome) = false)) then
  begin
    hotkeysHomeLatch := false;
  end;
end;

function isLoggedIn():Boolean;
begin
  result := GetColor(446,488) = 1908328;
end;
function isRunning():Boolean;
begin
  result := GetColor(568,128) = 6806252;
end;
function isRunEnergyMaxed():Boolean;
begin
  result := GetColor(534,131) = 65280;
end;

function RopeAction():Boolean;
begin
  MoveAndClick(variance(442,10),variance(333,2), 1);
  result:=true;
end;
function RopeVerification:Boolean;
var tempX,tempY:Integer;
begin
  result:=FindColor(tempX,tempY,65280,425,329,434,339);
end;

function TropicalTreeAction():Boolean;
begin
  MoveAndClick(variance(275,5),variance(132,5), 1);
  result:=true;
end;
function TropicalTreeVerification:Boolean;
var tempX,tempY:Integer;
begin
  result:=FindColor(tempX,tempY,65280,270,143,276,149);
end;

function RunEnergyCheckAction():Boolean;
begin
  if((isRunning() = false) and (isRunEnergyMaxed() = true)) then
  begin
    MoveAndClick(variance(566,5),variance(123,5), 1);
  end;
  result:=true;
end;
function RunEnergyCheckVerification:Boolean;
var tempX,tempY:Integer;
begin
  result:= true;
end;

function SteppingStoneAction():Boolean;
begin
  MoveAndClick(variance(25,1),variance(238,1), 1);
  result:=true;
end;
function SteppingStoneVerification:Boolean;
var tempX,tempY:Integer;
begin
  result:=FindColor(tempX,tempY,65280,21,233,27,239);
end;

function TropicalTree2Action():Boolean;
begin
  MoveAndClick(variance(257,5),variance(170,15), 1);
  result:=true;
end;
function TropicalTree2Verification:Boolean;
var tempX,tempY:Integer;
begin
  result:=FindColor(tempX,tempY,65280,260,147,263,153);// or FindColor(tempX,tempY,45568,237,175,243,181));
end;

function MonkeybarsAction():Boolean;
begin
  MoveAndClick(variance(244,6),variance(178,6), 1);
  result:=true;
end;
function MonkeybarsVerification:Boolean;
var tempX,tempY:Integer;
begin
  result:=FindColor(tempX,tempY,65280,233,166,242,172);
end;

function SkullSlopeAction():Boolean;
begin
  MoveAndClick(variance(245,6),variance(172,6), 1);
  result:=true;
end;
function SkullSlopeVerification:Boolean;
var tempX,tempY:Integer;
begin
  result:=(FindColor(tempX,tempY,65280,237,175,243,181) or FindColor(tempX,tempY,45568,237,175,243,181));
end;

function LogoutAction():Boolean;
begin
  PressKey(27);//ESC
  Wait(variance(400,175));
  PressKey(27);//Press for a second time, in case other menu is open
  MoveAndClick(variance(641,70),variance(431,17), 1);
  result := true;
end;
function LogoutVerification():Boolean;
begin
  result := isLoggedIn();
end;


begin
  //define states
  statesArray[Ord(Rope)].action := @RopeAction;
  statesArray[Ord(Rope)].verification := @RopeVerification;
  statesArray[Ord(Rope)].nextState := TropicalTree;
  statesArray[Ord(Rope)].failedState := Logout;
  statesArray[Ord(Rope)].gracePeriod := 3500;
  statesArray[Ord(Rope)].deadTime := 600;
  statesArray[Ord(Rope)].deadTimeVariance := 250;

  statesArray[Ord(TropicalTree)].action := @TropicalTreeAction;
  statesArray[Ord(TropicalTree)].verification := @TropicalTreeVerification;
  statesArray[Ord(TropicalTree)].nextState := RunEnergyCheck;
  statesArray[Ord(TropicalTree)].failedState := Logout;
  statesArray[Ord(TropicalTree)].gracePeriod := 7000;
  statesArray[Ord(TropicalTree)].deadTime := 1200;
  statesArray[Ord(TropicalTree)].deadTimeVariance := 350;

  statesArray[Ord(RunEnergyCheck)].action := @RunEnergyCheckAction;
  statesArray[Ord(RunEnergyCheck)].verification := @RunEnergyCheckVerification;
  statesArray[Ord(RunEnergyCheck)].nextState := SteppingStone;
  statesArray[Ord(RunEnergyCheck)].failedState := Logout;
  statesArray[Ord(RunEnergyCheck)].gracePeriod := 300;
  statesArray[Ord(RunEnergyCheck)].deadTime := 700;
  statesArray[Ord(RunEnergyCheck)].deadTimeVariance := 350;

  statesArray[Ord(SteppingStone)].action := @SteppingStoneAction;
  statesArray[Ord(SteppingStone)].verification := @SteppingStoneVerification;
  statesArray[Ord(SteppingStone)].nextState := TropicalTree2;
  statesArray[Ord(SteppingStone)].failedState := Logout;
  statesArray[Ord(SteppingStone)].gracePeriod := 5000;
  statesArray[Ord(SteppingStone)].deadTime := 600;
  statesArray[Ord(SteppingStone)].deadTimeVariance := 250;

  statesArray[Ord(TropicalTree2)].action := @TropicalTree2Action;
  statesArray[Ord(TropicalTree2)].verification := @TropicalTree2Verification;
  statesArray[Ord(TropicalTree2)].nextState := Monkeybars;
  statesArray[Ord(TropicalTree2)].failedState := Logout;
  statesArray[Ord(TropicalTree2)].gracePeriod := 9000;
  statesArray[Ord(TropicalTree2)].deadTime := 900;
  statesArray[Ord(TropicalTree2)].deadTimeVariance := 300;

  statesArray[Ord(Monkeybars)].action := @MonkeybarsAction;
  statesArray[Ord(Monkeybars)].verification := @MonkeybarsVerification;
  statesArray[Ord(Monkeybars)].nextState := SkullSlope;
  statesArray[Ord(Monkeybars)].failedState := Logout;
  statesArray[Ord(Monkeybars)].gracePeriod := 2000;
  statesArray[Ord(Monkeybars)].deadTime := 600;
  statesArray[Ord(Monkeybars)].deadTimeVariance := 250;

  statesArray[Ord(SkullSlope)].action := @SkullSlopeAction;
  statesArray[Ord(SkullSlope)].verification := @SkullSlopeVerification;
  statesArray[Ord(SkullSlope)].nextState := Rope;
  statesArray[Ord(SkullSlope)].failedState := Logout;
  statesArray[Ord(SkullSlope)].gracePeriod := 4000;
  statesArray[Ord(SkullSlope)].deadTime := 600;
  statesArray[Ord(SkullSlope)].deadTimeVariance := 250;

  statesArray[Ord(Logout)].action := @LogoutAction;
  statesArray[Ord(Logout)].verification := @LogoutVerification;
  statesArray[Ord(Logout)].nextState := Logout;
  statesArray[Ord(Logout)].failedState := Logout;
  statesArray[Ord(Logout)].gracePeriod := 5000;
  statesArray[Ord(Logout)].deadTime := 650;
  statesArray[Ord(Logout)].deadTimeVariance := 250;

  //initial state
  currentState := Rope;
  GetMousePos(mouseTarX,mouseTarY);
  wasPaused := true;
  hotkeysPauseRequested := true;
  Log('Script starting paused - press PAUSE key to start');

  repeat
    currentTime := GetTimeRunning();
    CheckHotKeys();
    if(hotkeysPauseRequested = false) then
    begin
      HandleMouse();

      //if just unpaused, figure out what state we're in
      //
      //should probably rewrite this to proceed through the steps following the
      //logical order, rather than looping through all possible states in case
      //we use some for branching
      if(wasPaused) then
      begin
        Log('Unpaused - verifying state before proceeding');
        stateFound := false;
        wasPaused := false;
        for st := Low(STATES) to High(States) do
        begin
          if(stateFound = false) then
          begin
            if(statesArray[Ord(st)].verification) then
            begin
              stateFound := true;
              currentState := st;
              Log('State verification succeeded, assuming this is the current state');
            end else
            begin
              Log('State ' + IntToStr(Ord(st)) + ' verification failed, trying next state');
            end;
          end;
        end;
      end;

      //main loop here
      if(verified = false) then
      begin
        if(currentTime > (nextActionTime + statesArray[Ord(currentState)].gracePeriod)) then
        begin
          if(statesArray[Ord(currentState)].verification) then
          begin
            verified := true;
            nextActionTime := currentTime + variance(statesArray[Ord(currentState)].deadTime, statesArray[Ord(currentState)].deadTimeVariance);
            Log('State was verified. Performing action at ' + IntToStr(nextActionTime));
          end;
          if(currentTime > (nextActionTime + statesArray[Ord(currentState)].gracePeriod + verificationLimit)) then
          begin
            Log('Exceeded time limit. Setting state to failed state');
            currentState := statesArray[Ord(currentState)].failedState;
            nextActionTime := currentTime + variance(statesArray[Ord(currentState)].deadTime, statesArray[Ord(currentState)].deadTimeVariance);
            verified := false;
          end;
        end;
        //end;
      end else
      begin
        if(currentTime > nextActionTime) then
        begin
          if(statesArray[Ord(currentState)].action) then
          begin
            //action was successful
            Log('Action successful. Proceeding to next state.');
            currentState := statesArray[Ord(currentState)].nextState;
            verified := false;
          end else
          begin
            //action was not successful
            Log('Action FAILED. Setting state to failed state');
            currentState := statesArray[Ord(currentState)].failedState;
            verified := false;
          end;
        end;
      end;

    end else
    begin
      //we are currently paused
      wasPaused := true;
    end;
  until(isLoggedIn() = false);
  Log('Logout detecting.');
end.
