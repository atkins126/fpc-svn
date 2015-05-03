unit googleappstate;
{
  This is the file COPYING.FPC, it applies to the Free Pascal Run-Time Library 
  (RTL) and packages (packages) distributed by members of the Free Pascal 
  Development Team.
  
  The source code of the Free Pascal Runtime Libraries and packages are 
  distributed under the Library GNU General Public License 
  (see the file COPYING) with the following modification:
  
  As a special exception, the copyright holders of this library give you
  permission to link this library with independent modules to produce an
  executable, regardless of the license terms of these independent modules,
  and to copy and distribute the resulting executable under terms of your choice,
  provided that you also meet, for each linked independent module, the terms
  and conditions of the license of that module. An independent module is a module
  which is not derived from or based on this library. If you modify this
  library, you may extend this exception to your version of the library, but you are
  not obligated to do so. If you do not wish to do so, delete this exception
  statement from your version.
  
  If you didn't receive a copy of the file COPYING, contact:
        Free Software Foundation
        675 Mass Ave
        Cambridge, MA  02139
        USA
  
}
{$MODE objfpc}
{$H+}

interface

uses sysutils, classes, googleservice, restbase, googlebase;

type
  //
  TGetResponse = class;
  TGetResponseArray = Array of TGetResponse;
  TListResponse = class;
  TListResponseArray = Array of TListResponse;
  TListResponseitems = class;
  TListResponseitemsArray = Array of TListResponseitems;
  TUpdateRequest = class;
  TUpdateRequestArray = Array of TUpdateRequest;
  TWriteResult = class;
  TWriteResultArray = Array of TWriteResult;
  
  { --------------------------------------------------------------------
    TGetResponse
    --------------------------------------------------------------------}
  
  TGetResponse = Class(TGoogleBaseObject)
  Private
    FcurrentStateVersion : string;
    Fdata : string;
    Fkind : string;
    FstateKey : integer;
  Protected
    //Property setters
    Procedure SetcurrentStateVersion(AIndex : Integer; AValue : string); virtual;
    Procedure Setdata(AIndex : Integer; AValue : string); virtual;
    Procedure Setkind(AIndex : Integer; AValue : string); virtual;
    Procedure SetstateKey(AIndex : Integer; AValue : integer); virtual;
  Public
  Published
    Property currentStateVersion : string Index 0 Read FcurrentStateVersion Write SetcurrentStateVersion;
    Property data : string Index 8 Read Fdata Write Setdata;
    Property kind : string Index 16 Read Fkind Write Setkind;
    Property stateKey : integer Index 24 Read FstateKey Write SetstateKey;
  end;
  TGetResponseClass = Class of TGetResponse;
  
  { --------------------------------------------------------------------
    TListResponse
    --------------------------------------------------------------------}
  
  TListResponse = Class(TGoogleBaseObject)
  Private
    Fitems : TListResponseitems;
    Fkind : string;
    FmaximumKeyCount : integer;
  Protected
    //Property setters
    Procedure Setitems(AIndex : Integer; AValue : TListResponseitems); virtual;
    Procedure Setkind(AIndex : Integer; AValue : string); virtual;
    Procedure SetmaximumKeyCount(AIndex : Integer; AValue : integer); virtual;
  Public
  Published
    Property items : TListResponseitems Index 0 Read Fitems Write Setitems;
    Property kind : string Index 8 Read Fkind Write Setkind;
    Property maximumKeyCount : integer Index 16 Read FmaximumKeyCount Write SetmaximumKeyCount;
  end;
  TListResponseClass = Class of TListResponse;
  
  { --------------------------------------------------------------------
    TListResponseitems
    --------------------------------------------------------------------}
  
  TListResponseitems = Class(TGoogleBaseObject)
  Private
  Protected
    //Property setters
  Public
  Published
  end;
  TListResponseitemsClass = Class of TListResponseitems;
  
  { --------------------------------------------------------------------
    TUpdateRequest
    --------------------------------------------------------------------}
  
  TUpdateRequest = Class(TGoogleBaseObject)
  Private
    Fdata : string;
    Fkind : string;
  Protected
    //Property setters
    Procedure Setdata(AIndex : Integer; AValue : string); virtual;
    Procedure Setkind(AIndex : Integer; AValue : string); virtual;
  Public
  Published
    Property data : string Index 0 Read Fdata Write Setdata;
    Property kind : string Index 8 Read Fkind Write Setkind;
  end;
  TUpdateRequestClass = Class of TUpdateRequest;
  
  { --------------------------------------------------------------------
    TWriteResult
    --------------------------------------------------------------------}
  
  TWriteResult = Class(TGoogleBaseObject)
  Private
    FcurrentStateVersion : string;
    Fkind : string;
    FstateKey : integer;
  Protected
    //Property setters
    Procedure SetcurrentStateVersion(AIndex : Integer; AValue : string); virtual;
    Procedure Setkind(AIndex : Integer; AValue : string); virtual;
    Procedure SetstateKey(AIndex : Integer; AValue : integer); virtual;
  Public
  Published
    Property currentStateVersion : string Index 0 Read FcurrentStateVersion Write SetcurrentStateVersion;
    Property kind : string Index 8 Read Fkind Write Setkind;
    Property stateKey : integer Index 16 Read FstateKey Write SetstateKey;
  end;
  TWriteResultClass = Class of TWriteResult;
  
  { --------------------------------------------------------------------
    TStatesResource
    --------------------------------------------------------------------}
  
  
  //Optional query Options for TStatesResource, method Clear
  
  TStatesClearOptions = Record
    currentDataVersion : string;
  end;
  
  
  //Optional query Options for TStatesResource, method List
  
  TStatesListOptions = Record
    includeData : boolean;
  end;
  
  
  //Optional query Options for TStatesResource, method Update
  
  TStatesUpdateOptions = Record
    currentStateVersion : string;
  end;
  
  TStatesResource = Class(TGoogleResource)
  Public
    Class Function ResourceName : String; override;
    Class Function DefaultAPI : TGoogleAPIClass; override;
    Function Clear(stateKey: integer; AQuery : string  = '') : TWriteResult;
    Function Clear(stateKey: integer; AQuery : TStatesclearOptions) : TWriteResult;
    Procedure Delete(stateKey: integer);
    Function Get(stateKey: integer) : TGetResponse;
    Function List(AQuery : string  = '') : TListResponse;
    Function List(AQuery : TStateslistOptions) : TListResponse;
    Function Update(stateKey: integer; aUpdateRequest : TUpdateRequest; AQuery : string  = '') : TWriteResult;
    Function Update(stateKey: integer; aUpdateRequest : TUpdateRequest; AQuery : TStatesupdateOptions) : TWriteResult;
  end;
  
  
  { --------------------------------------------------------------------
    TAppstateAPI
    --------------------------------------------------------------------}
  
  TAppstateAPI = Class(TGoogleAPI)
  Private
    FStatesInstance : TStatesResource;
    Function GetStatesInstance : TStatesResource;virtual;
  Public
    //Override class functions with API info
    Class Function APIName : String; override;
    Class Function APIVersion : String; override;
    Class Function APIRevision : String; override;
    Class Function APIID : String; override;
    Class Function APITitle : String; override;
    Class Function APIDescription : String; override;
    Class Function APIOwnerDomain : String; override;
    Class Function APIOwnerName : String; override;
    Class Function APIIcon16 : String; override;
    Class Function APIIcon32 : String; override;
    Class Function APIdocumentationLink : String; override;
    Class Function APIrootUrl : string; override;
    Class Function APIbasePath : string;override;
    Class Function APIbaseURL : String;override;
    Class Function APIProtocol : string;override;
    Class Function APIservicePath : string;override;
    Class Function APIbatchPath : String;override;
    Class Function APIAuthScopes : TScopeInfoArray;override;
    Class Function APINeedsAuth : Boolean;override;
    Class Procedure RegisterAPIResources; override;
    //Add create function for resources
    Function CreateStatesResource(AOwner : TComponent) : TStatesResource;virtual;overload;
    Function CreateStatesResource : TStatesResource;virtual;overload;
    //Add default on-demand instances for resources
    Property StatesResource : TStatesResource Read GetStatesInstance;
  end;

implementation


{ --------------------------------------------------------------------
  TGetResponse
  --------------------------------------------------------------------}


Procedure TGetResponse.SetcurrentStateVersion(AIndex : Integer; AValue : string); 

begin
  If (FcurrentStateVersion=AValue) then exit;
  FcurrentStateVersion:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TGetResponse.Setdata(AIndex : Integer; AValue : string); 

begin
  If (Fdata=AValue) then exit;
  Fdata:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TGetResponse.Setkind(AIndex : Integer; AValue : string); 

begin
  If (Fkind=AValue) then exit;
  Fkind:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TGetResponse.SetstateKey(AIndex : Integer; AValue : integer); 

begin
  If (FstateKey=AValue) then exit;
  FstateKey:=AValue;
  MarkPropertyChanged(AIndex);
end;





{ --------------------------------------------------------------------
  TListResponse
  --------------------------------------------------------------------}


Procedure TListResponse.Setitems(AIndex : Integer; AValue : TListResponseitems); 

begin
  If (Fitems=AValue) then exit;
  Fitems:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TListResponse.Setkind(AIndex : Integer; AValue : string); 

begin
  If (Fkind=AValue) then exit;
  Fkind:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TListResponse.SetmaximumKeyCount(AIndex : Integer; AValue : integer); 

begin
  If (FmaximumKeyCount=AValue) then exit;
  FmaximumKeyCount:=AValue;
  MarkPropertyChanged(AIndex);
end;





{ --------------------------------------------------------------------
  TListResponseitems
  --------------------------------------------------------------------}




{ --------------------------------------------------------------------
  TUpdateRequest
  --------------------------------------------------------------------}


Procedure TUpdateRequest.Setdata(AIndex : Integer; AValue : string); 

begin
  If (Fdata=AValue) then exit;
  Fdata:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TUpdateRequest.Setkind(AIndex : Integer; AValue : string); 

begin
  If (Fkind=AValue) then exit;
  Fkind:=AValue;
  MarkPropertyChanged(AIndex);
end;





{ --------------------------------------------------------------------
  TWriteResult
  --------------------------------------------------------------------}


Procedure TWriteResult.SetcurrentStateVersion(AIndex : Integer; AValue : string); 

begin
  If (FcurrentStateVersion=AValue) then exit;
  FcurrentStateVersion:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TWriteResult.Setkind(AIndex : Integer; AValue : string); 

begin
  If (Fkind=AValue) then exit;
  Fkind:=AValue;
  MarkPropertyChanged(AIndex);
end;



Procedure TWriteResult.SetstateKey(AIndex : Integer; AValue : integer); 

begin
  If (FstateKey=AValue) then exit;
  FstateKey:=AValue;
  MarkPropertyChanged(AIndex);
end;





{ --------------------------------------------------------------------
  TStatesResource
  --------------------------------------------------------------------}


Class Function TStatesResource.ResourceName : String;

begin
  Result:='states';
end;

Class Function TStatesResource.DefaultAPI : TGoogleAPIClass;

begin
  Result:=TappstateAPI;
end;

Function TStatesResource.Clear(stateKey: integer; AQuery : string = '') : TWriteResult;

Const
  _HTTPMethod = 'POST';
  _Path       = 'states/{stateKey}/clear';
  _Methodid   = 'appstate.states.clear';

Var
  _P : String;

begin
  _P:=SubstitutePath(_Path,['stateKey',stateKey]);
  Result:=ServiceCall(_HTTPMethod,_P,AQuery,Nil,TWriteResult) as TWriteResult;
end;


Function TStatesResource.Clear(stateKey: integer; AQuery : TStatesclearOptions) : TWriteResult;

Var
  _Q : String;

begin
  _Q:='';
  AddToQuery(_Q,'currentDataVersion',AQuery.currentDataVersion);
  Result:=Clear(stateKey,_Q);
end;

Procedure TStatesResource.Delete(stateKey: integer);

Const
  _HTTPMethod = 'DELETE';
  _Path       = 'states/{stateKey}';
  _Methodid   = 'appstate.states.delete';

Var
  _P : String;

begin
  _P:=SubstitutePath(_Path,['stateKey',stateKey]);
  ServiceCall(_HTTPMethod,_P,'',Nil,Nil);
end;

Function TStatesResource.Get(stateKey: integer) : TGetResponse;

Const
  _HTTPMethod = 'GET';
  _Path       = 'states/{stateKey}';
  _Methodid   = 'appstate.states.get';

Var
  _P : String;

begin
  _P:=SubstitutePath(_Path,['stateKey',stateKey]);
  Result:=ServiceCall(_HTTPMethod,_P,'',Nil,TGetResponse) as TGetResponse;
end;

Function TStatesResource.List(AQuery : string = '') : TListResponse;

Const
  _HTTPMethod = 'GET';
  _Path       = 'states';
  _Methodid   = 'appstate.states.list';

begin
  Result:=ServiceCall(_HTTPMethod,_Path,AQuery,Nil,TListResponse) as TListResponse;
end;


Function TStatesResource.List(AQuery : TStateslistOptions) : TListResponse;

Var
  _Q : String;

begin
  _Q:='';
  AddToQuery(_Q,'includeData',AQuery.includeData);
  Result:=List(_Q);
end;

Function TStatesResource.Update(stateKey: integer; aUpdateRequest : TUpdateRequest; AQuery : string = '') : TWriteResult;

Const
  _HTTPMethod = 'PUT';
  _Path       = 'states/{stateKey}';
  _Methodid   = 'appstate.states.update';

Var
  _P : String;

begin
  _P:=SubstitutePath(_Path,['stateKey',stateKey]);
  Result:=ServiceCall(_HTTPMethod,_P,AQuery,aUpdateRequest,TWriteResult) as TWriteResult;
end;


Function TStatesResource.Update(stateKey: integer; aUpdateRequest : TUpdateRequest; AQuery : TStatesupdateOptions) : TWriteResult;

Var
  _Q : String;

begin
  _Q:='';
  AddToQuery(_Q,'currentStateVersion',AQuery.currentStateVersion);
  Result:=Update(stateKey,aUpdateRequest,_Q);
end;



{ --------------------------------------------------------------------
  TAppstateAPI
  --------------------------------------------------------------------}

Class Function TAppstateAPI.APIName : String;

begin
  Result:='appstate';
end;

Class Function TAppstateAPI.APIVersion : String;

begin
  Result:='v1';
end;

Class Function TAppstateAPI.APIRevision : String;

begin
  Result:='20150428';
end;

Class Function TAppstateAPI.APIID : String;

begin
  Result:='appstate:v1';
end;

Class Function TAppstateAPI.APITitle : String;

begin
  Result:='Google App State API';
end;

Class Function TAppstateAPI.APIDescription : String;

begin
  Result:='The Google App State API.';
end;

Class Function TAppstateAPI.APIOwnerDomain : String;

begin
  Result:='google.com';
end;

Class Function TAppstateAPI.APIOwnerName : String;

begin
  Result:='Google';
end;

Class Function TAppstateAPI.APIIcon16 : String;

begin
  Result:='http://www.google.com/images/icons/product/search-16.gif';
end;

Class Function TAppstateAPI.APIIcon32 : String;

begin
  Result:='http://www.google.com/images/icons/product/search-32.gif';
end;

Class Function TAppstateAPI.APIdocumentationLink : String;

begin
  Result:='https://developers.google.com/games/services/web/api/states';
end;

Class Function TAppstateAPI.APIrootUrl : string;

begin
  Result:='https://www.googleapis.com/';
end;

Class Function TAppstateAPI.APIbasePath : string;

begin
  Result:='/appstate/v1/';
end;

Class Function TAppstateAPI.APIbaseURL : String;

begin
  Result:='https://www.googleapis.com/appstate/v1/';
end;

Class Function TAppstateAPI.APIProtocol : string;

begin
  Result:='rest';
end;

Class Function TAppstateAPI.APIservicePath : string;

begin
  Result:='appstate/v1/';
end;

Class Function TAppstateAPI.APIbatchPath : String;

begin
  Result:='batch';
end;

Class Function TAppstateAPI.APIAuthScopes : TScopeInfoArray;

begin
  SetLength(Result,1);
  Result[0].Name:='https://www.googleapis.com/auth/appstate';
  Result[0].Description:='View and manage your data for this application';
  
end;

Class Function TAppstateAPI.APINeedsAuth : Boolean;

begin
  Result:=True;
end;

Class Procedure TAppstateAPI.RegisterAPIResources;

begin
  TGetResponse.RegisterObject;
  TListResponse.RegisterObject;
  TListResponseitems.RegisterObject;
  TUpdateRequest.RegisterObject;
  TWriteResult.RegisterObject;
end;


Function TAppstateAPI.GetStatesInstance : TStatesResource;

begin
  if (FStatesInstance=Nil) then
    FStatesInstance:=CreateStatesResource;
  Result:=FStatesInstance;
end;

Function TAppstateAPI.CreateStatesResource : TStatesResource;

begin
  Result:=CreateStatesResource(Self);
end;


Function TAppstateAPI.CreateStatesResource(AOwner : TComponent) : TStatesResource;

begin
  Result:=TStatesResource.Create(AOwner);
  Result.API:=Self;
end;



initialization
  TAppstateAPI.RegisterAPI;
end.
