function varargout = STORMfinderBeta(varargin)
% STORMFINDERBETA MATLAB code for STORMfinderBeta.fig
%      STORMFINDERBETA, by itself, creates a new STORMFINDERBETA or raises the existing
%      singleton*.
%
%      H = STORMFINDERBETA returns the handle to a new STORMFINDERBETA or the handle to
%      the existing singleton*.
%
%      STORMFINDERBETA('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in STORMFINDERBETA.M with the given input arguments.
%
%      STORMFINDERBETA('Property','Value',...) creates a new STORMFINDERBETA or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before STORMfinderBeta_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to STORMfinderBeta_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% -------------------------------------------------------------------------
% Outputs
% parfile_temp.ini  -- .ini parameters being used by the system 
% parfile_temp.xml 
% parfile_temp_1frame.xml
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help STORMfinderBeta

% Last Modified by GUIDE v2.5 02-Feb-2013 12:09:40

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @STORMfinderBeta_OpeningFcn, ...
                   'gui_OutputFcn',  @STORMfinderBeta_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before STORMfinderBeta is made visible.
function STORMfinderBeta_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to STORMfinderBeta (see VARARGIN)

% Choose default command line output for STORMfinderBeta
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% STARTUP
% addpath(genpath('..')); % adds the whole Matlab_STORM directory to path.
% alterantively, this can be specified by the matlab startup script.  
 addpath(genpath('.'));
global defaultDataPath  defaultInsightPath

% If any daxfile has been loaded, open it along with opening the GUI.  
try
LoadFile_Callback(hObject, eventdata, handles)
catch er
    % disp(er.message);
    disp('please load a dax file');
end
handles.axes1; 
axis off; 
% UIWAIT makes STORMfinderBeta wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = STORMfinderBeta_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function FindDots_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to FindDots (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global impars daxfile mlist  % shared Globals
global defaultInsightPath inifile ; % for InsightM 
global defaultDaoSTORM xmlfile  % for DaoSTORM
global FitPars

    FitMethod = get(handles.FitMethod,'Value');
   
    k = strfind(daxfile,filesep);
    fpath = daxfile(1:k(end));
    daxroot = regexprep(daxfile(k(end)+1:end),'.dax','');
    
	if FitMethod == 1 % InsightM  
        if isempty(defaultInsightPath)
            error(['defaultInsightPath not found.  ',...
                'Please set the global variable defaultInsightPath ',...
                'to specify the location of insightM.exe in the ',...
                'Insight3 folder on your computer.']);
        end
        insight = defaultInsightPath; 
        
        % InsightM /.ini files don't have a max frames parameter, so
        % instead we write a new dax menufile that has only 1 frame.  
        
        % if no inifile has been loaded, use default values 
        if isempty(inifile)
            ReadParameterFile(FitMethod) % make default file the inifile
        end
        
       % write temp daxfile
        mov_temp = 'mov_temp.dax';
        daxtemp = [fpath, mov_temp];
        ftemp = fopen(daxtemp,'w+');
        fwrite(ftemp,impars.Im(:),'*uint16',0,'b');
        fclose(ftemp);

        % write temp inf file 
        InfoFile_temp = impars.infofile;
        InfoFile_temp.number_of_frames = 1;
        InfoFile_temp.localName = 'mov_temp.inf';
        InfoFile_temp.localPath = fpath;
        WriteInfoFiles(InfoFile_temp,'verbose',false);
         
        
        ccall = ['!', insight,' ',daxtemp,' ',inifile];
        % ccall = ['!', insight,' ',daxtemp,' ',inifile,  '  && exit &'];
        disp(ccall); 
        eval(ccall); 
        binfile = regexprep([fpath,'mov_temp.dax'],'\.dax','_list.bin');
            
        
	elseif FitMethod == 2    
        % load parameter files if missing
        if isempty(xmlfile)
            ReadParameterFile(FitMethod) % make default file the 'xmlfile'
        end
        if isempty(defaultDaoSTORM)
            error(['defaultDaoSTORM not found.  ',...
                'Please set the global variable defaultDaoSTORM ',...
                'to specify the location of mufit_analysis.py in the ',...
                'DaoSTORM folder on your computer and its dll paths.',...
                'See startup_example in \Templates folder']);
        end
          
        % update xmlfile to current frame 
            % save a new xmlfile which has 1frame appended onto the default one.
            xmlfile_temp = make_temp_parameters(handles,'1frame');
            parameters = {'<start_frame type="int">',...
                            '<max_frame type="int">',...
                            '<drift_correction type="int">'};
            new_values = {num2str(impars.cframe),...
                          num2str(impars.cframe+1),...
                          '0'}; 
            modify_script(xmlfile,xmlfile_temp,parameters,new_values,'<');     
         
        % need to delete any existing bin menufile before we overwrite, or
        % DaoSTORM tries to pick up analysis where it left off.  
         binfile = regexprep([fpath,'mov_temp.dax'],'\.dax','_mlist.bin'); 
         % system(['del ',binfile]);
         system(['del ',binfile,' >',fpath,'\jnk.txt']); 
         % the > jnk.txt hides the output.  
        
        % Call DaoSTORM.     
        system([defaultDaoSTORM,' ',daxfile,' ',binfile,' ',xmlfile_temp]);
        
            
    elseif FitMethod == 3
        TempPars = FitPars;
        TempPars.startFrame = mat2str(impars.cframe);
        TempPars.endFrame = mat2str(impars.cframe+1); 
        mlist = GPUmultifitDax(daxfile,TempPars);           
    end 
    
    if FitMethod~=3
        mlist = ReadMasterMoleculeList(binfile,'verbose',false);
    end
handles.axes1;  cla; 
imagesc(impars.Im(:,:,1)'); 
caxis([impars.cmin,impars.cmax]); colormap gray;
set(handles.title1,'String',daxfile); % ,'interpreter','none'); 
hold on;   plot(mlist.x(:),mlist.y(:),'yo','MarkerSize',20);
axis off;
% rectangle(mlist.x(:),mlist.y(:),mlist.w(:),mlist.w(:));



% --------------------------------------------------------------------
function Plotdots3D_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to Plotdots3D (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global mlist impars
try
    figure(2); clf; 
    plot3(mlist.y(:),mlist.x(:),mlist.z(:),'k.','MarkerSize',10);
    grid on;
    xlabel('y'); ylabel('x'); zlabel('z'); 
    xlim([0,impars.w]); ylim([0,impars.h]);
catch er
    disp(er.message);
    disp('no molecules found to plot!');
end



% --- Executes on button press in LoadFile.
function LoadFile_Callback(hObject, eventdata, handles)
% hObject    handle to LoadFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global daxfile impars
% Read info menufile
    iminfo = ReadInfoFile(daxfile);
    impars.h = iminfo.frame_dimensions(1);
    impars.w = iminfo.frame_dimensions(2);
    impars.infofile = iminfo; 
% setup default intensities
    fid = fopen(daxfile);
    Im = fread(fid, impars.h*impars.w, '*uint16',0,'b');
    fclose(fid);
    impars.cmax = max(Im(:));
    impars.cmin = min(Im(:));
% set up framer slider
    impars.cframe = 1; % reset to 1
    % str2double(get(handles.currframe,'String'));
    fid = fopen(daxfile);
    fseek(fid,0,'eof');
    fend = ftell(fid);
    fclose(fid);
    TFrames = fend/(16/8)/(impars.h*impars.w);  % total number of frames
    set(handles.FrameSlider,'Min',1)
    set(handles.FrameSlider,'Max',TFrames);
    set(handles.FrameSlider,'Value',impars.cframe); 
    set(handles.FrameSlider,'SliderStep',[1/TFrames,50/TFrames]);
    UpdateFrame(handles);

function UpdateFrame(handles)
    global daxfile impars
    % shorthand, load 
    cframe = impars.cframe; 
    h = impars.h;
    w = impars.w;
    fid = fopen(daxfile);
    L = 1; % number of frames to read in
    fseek(fid,(h*w*(cframe-1))*16/8,'bof'); % bits/(bytes per bit) 
    Im = fread(fid, h*w*L, '*uint16',0,'b');
    fclose(fid);
    Im = reshape(Im,w,h,L);
    handles.axes1; cla;
    imagesc(Im(:,:,1)'); caxis([impars.cmin,impars.cmax]); colormap gray;
     axis off; 
    set(handles.title1,'String',daxfile);
    % the transpose here is merely to match insight.  
    impars.Im = Im; 

 

function [FitPars,parameters] = ReadParameterFile(FitMethod)
% loads contents of inifile or xmlfile into data structure FitPars
% depending on whether fit method is insightM or DaoSTORM respectively.  
% if no inifile or xmlfile has been loaded yet, load default files.  
% 
global inifile xmlfile gpufile defaultIniFile defaultXmlFile defaultGPUmFile
  % clear fitPars  
if FitMethod == 1
    if isempty(inifile)
        inifile = defaultIniFile; % '..\Parameters\647zcal_storm2.ini';
         disp('no inifile found to load, using default file');
         disp(inifile); 
        disp('to load a file, drag and drop it into matlab'); 
    end
        parameters = {
            'min height=',...
            'max height=',...
            'default background=',...
            'min width=',...
            'max width=',...
            'default width=',...
            'axial ratio tolerance=',...
            'Fit ROI=',...
            'displacement=',...
            'start frame='...
            'allow drift=',...
            'number of molecules in each correlation time step (XY)=',...
            'number of molecules in each correlation time step (Z)=',...
            'minimum time step size (frame)=',...
            'maximum time step size (frame)=',...
            'xy grid size (nm) in xy correlation=',...
            'xy grid size (nm) in z correlation=',...
            'points for moving average in generating drift correlation (XY)=',...
            'points for moving average in generating drift correlation (Z)=',...
            'z method=',...
            'z calibration expression=',...
            'z calibration outlier rejection percentile=',...
            'z calibration start=',...
            'z calibration end=',...
            'z calibration step=',...
            };

        % Get values from loaded inifile
            target_values = read_parameterfile(inifile,parameters,'');
        % save these values into global FitPars;   
            Pfields = {'minheight','maxheight','bkd','minwidth','maxwidth',...
                'initwidth','maxaxratio','fitROI','displacement','startFrame','CorDrift',...
                'xymols','zmols','minframes','maxframes','xygridxy','xygridz',...
                'movAxy','movAz','Fit3D','zcaltxt','zop','zstart','zend','zstep'};
            FitPars = cell2struct(target_values,Pfields,2);
            
elseif FitMethod == 2
    if isempty(xmlfile)
        xmlfile = defaultXmlFile; %  ;
        disp('no xmlfile parameter file found to load.')
        disp(['using default file',xmlfile]);
        disp('to load a file, drag and drop into matlab'); 
    end
    parameters = {
        '<model type="string">',...    method
        '<threshold type="float">'...  threshold
        '<iterations type="int">',...  maxits
        '<baseline type="float">',...   bkd
        '<pixel_size type="float">',... ppnm
        '<sigma type="float">',...      initwidth
        '<descriptor type="string">',... descriptor
        '<radius type="float">',...  displacement
        '<start_frame type="int">',... startFrame
        '<max_frame type="int">',... endFrame
        '<drift_correction type="int">',... %  CorDrift
        '<frame_step type="int">',... dframes
        '<d_scale type="int">',...dscales
        '<do_zfit type="int">',... Fit3D
        '<cutoff type="float">',... zcutoff
        '<min_z type="float">',...  zstart 
        '<max_z type="float">',...  zend
        '<wx_wo type="float">',...  wx0
        '<wx_c type="float">',...  gx
        '<wx_d type="float">',...  zrx
        '<wxA type="float">',...  Ax
        '<wxB type="float">',... Bx
        '<wxC type="float">',...  Cx
        '<wxD type="float">',...  Dx
        '<wy_wo type="float">',...  wy0
        '<wy_c type="float">',...  gy
        '<wy_d type="float">',...  zry
        '<wyA type="float">',...  Ay
        '<wyB type="float">',...  By
        '<wyC type="float">',...  Cy
        '<wyD type="float">',...  Dy
         };
     
    % Read in current parameter values from xmlfile
      target_values = read_parameterfile(xmlfile,parameters,'<');
    % save these values into global FitPars;
      Pfields = {'method','threshold','maxits','bkd','ppnm','initwidth',...
          'descriptor','displacement','startFrame','endFrame','CorDrift',...
          'dframes','dscale','Fit3D','zcutoff','zstart','zend','wx0','gx',...
          'zrx','Ax','Bx','Cx','Dx','wy0','gy','zry','Ay','By','Cy','Dy'};
      FitPars = cell2struct(target_values,Pfields,2);  
      
elseif FitMethod == 3  
    if isempty(gpufile)
        disp('no gpu parameter file found, loading defaults');
        gpufile = defaultGPUmFile;
    end
    load(gpufile);
    FitPars = GPUmultiPars;
    parameters = ''; 
end      

% save('C:\Users\Alistair\Documents\Projects\General_STORM\Test_data\test3.mat');




function parfile = make_temp_parameters(handles,temp)
% append 
global xmlfile inifile gpufile
FitMethod = get(handles.FitMethod,'Value');
if FitMethod == 1
    k = strfind(inifile,'.ini');
    if isempty(strfind(inifile,temp))
        parfile = [inifile(1:k-1),'_',temp,'.ini'];
    else
        parfile = inifile;
    end
elseif FitMethod == 2
    k = strfind(xmlfile,'.xml');
    if isempty(strfind(xmlfile,temp))
        parfile = [xmlfile(1:k-1),'_',temp,'.xml'];
    else
        parfile = xmlfile;
    end
elseif FitMethod == 3
     k = strfind(gpufile,'.mat');
    if isempty(strfind(gpufile,temp))
        parfile = [gpufile(1:k-1),'_temp','.mat'];
    else
        parfile = gpufile;
    end
end
% save('C:\Users\Alistair\Documents\Projects\General_STORM\Test_data\test.mat');
% load('C:\Users\Alistair\Documents\Projects\General_STORM\Test_data\test.mat');
    
    
    


% --- Executes on button press in FitParameters.
function FitParameters_Callback(hObject, eventdata, handles)
% hObject    handle to FitParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global FitPars inifile xmlfile gpufile
% disp('loading inifile');
% disp(inifile);
 FitMethod = get(handles.FitMethod,'Value');
 [FitPars,parameters] = ReadParameterFile(FitMethod); 
 parfile = make_temp_parameters(handles,'temp'); % if _temp.ini / .xml parameter files have not been made, make them.
%  disp('parfile = ');
%  disp(parfile)
 if FitMethod == 1 % InsightM
    f = GUIFitParameters;
    waitfor(f); % need to wait until parameter selection is closed. 
    new_values = struct2cell(FitPars)';
                                                disp('new_values:'); disp(new_values);
    modify_script(inifile,parfile,parameters,new_values,'');   
    inifile = parfile;
 %   disp(inifile);
 elseif FitMethod == 2    % DaoSTORM   
    f = GUIDaoParameters;
    waitfor(f); % need to wait until parameter selection is closed.   
    new_values = struct2cell(FitPars)';
    modify_script(xmlfile,parfile,parameters,new_values,'<');
    xmlfile = parfile; 
 elseif FitMethod == 3
    f = GUIgpuParameters;
    waitfor(f);
    GPUmultiPars = FitPars;
    gpufile = parfile; 
    save(gpufile,'GPUmultiPars');
end
% save('C:\Users\Alistair\Documents\Projects\General_STORM\Test_data\test2.mat');
% load('C:\Users\Alistair\Documents\Projects\General_STORM\Test_data\test2.mat');




% --- Executes on selection change in FitMethod.
function FitMethod_Callback(hObject, eventdata, handles)
% hObject    handle to FitMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global FitPars xmlfile inifile
 FitMethod = get(handles.FitMethod,'Value');
 FitPars = ReadParameterFile(FitMethod);
% Important that FitPars matches the current Fitting method.  



% --- Executes on slider movement.
function FrameSlider_Callback(hObject, eventdata, handles)
% hObject    handle to FrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global impars
impars.cframe = round(get(handles.FrameSlider,'Value'));
set(handles.currframe,'String',num2str(impars.cframe));
UpdateFrame(handles);


% --------------------------------------------------------------------
function ManualContrast_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to ManualContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global impars

dlg_title = 'Manual Contrast';
num_lines = 1;
prompt = {
    'Min Intensity',...
    'Max Intensity'};

default_opts = {
     num2str(impars.cmin),...
     num2str(impars.cmax)};
 
default_opts = inputdlg(prompt,dlg_title,num_lines,default_opts);
impars.cmin = str2double(default_opts{1});
impars.cmax = str2double(default_opts{2});
UpdateFrame(handles);

% --------------------------------------------------------------------
function AutoContrast_ClickedCallback(hObject, eventdata, handles)
% hObject    handle to AutoContrast (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global impars
impars.cmax = max(impars.Im(:));
impars.cmin = min(impars.Im(:));
UpdateFrame(handles);



function currframe_Callback(hObject, eventdata, handles)
% hObject    handle to currframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global impars;
impars.cframe = str2double(get(handles.currframe,'String'));
UpdateFrame(handles);










% --------------------------------------------------------------------
function MenuSavePars_Callback(hObject, eventdata, handles)
% hObject    handle to MenuSavePars (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
  
global inifile xmlfile
    FitMethod = get(handles.FitMethod,'Value');
    [FitPars,parameters] = ReadParameterFile(FitMethod);  % load current parameters in FitPars
    [savename, savepath] = uiputfile; % get file path and save name
    % save current parameters with menufile name / directory specified above
    if FitMethod == 1
modify_script(inifile,[savepath,savename],parameters,struct2cell(FitPars),'');   
    elseif FitMethod == 2
modify_script(xmlfile,[savepath,savename],parameters,struct2cell(FitPars),''); 
    elseif FitMethod == 3
        GPUmultiPars = FitPars; 
        save([savepath,savename],'GPUmultiPars');
    end



% --------------------------------------------------------------------
function MenuAnalyzeCurrent_Callback(hObject, eventdata, handles)
% hObject    handle to MenuAnalyzeCurrent (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global daxfile inifile xmlfile gpufile
 FitMethod = get(handles.FitMethod,'Value');
if FitMethod == 1
 RunDotFinder('daxfile',daxfile,'parsfile',inifile,'method','insight');
elseif FitMethod == 2
 RunDotFinder('daxfile',daxfile,'parsfile',xmlfile,'method','DaoSTORM'); 
elseif FitMethod == 3
 RunDotFinder('daxfile',daxfile,'parsfile',gpufile,'method','GPUmultifit'); 
end
% --------------------------------------------------------------------
function MenuAnalyzeRegion_Callback(hObject, eventdata, handles)
% hObject    handle to MenuAnalyzeRegion (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
disp('sorry, function not available yet'); 

% --------------------------------------------------------------------
function MenuAnalyzeAll_Callback(hObject, eventdata, handles)
% hObject    handle to MenuAnalyzeAll (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global Dprompt Dopts daxfile inifile xmlfile gpufile
FitMethod = get(handles.FitMethod,'Value');
if FitMethod == 1
    parsfile = inifile;
    method = 'insight';
    partype = '.ini';
elseif FitMethod == 2
    parsfile = regexprep(xmlfile,'_1frame',''); % remove temp flag.  
    method = 'DaoSTORM';
    partype = '.xml';
elseif FitMethod == 3
    parsfile = gpufile;
    method = 'GPUmultifit';
    partype = '.mat';
end


dlg_title = 'Run all dax files in folder';
num_lines = 1;
try
Dopts = inputdlg(Dprompt,dlg_title,num_lines,Dopts);
catch er
    disp('...menu built.  select again to run');
    Dprompt = {
        'batch size';
        'all dax files containing string'; %  
        'parameter file or file root'; % 
        'overwrite existing?' };
    Dopts = {
        '3',...
        '',...
        parsfile,...
        'true'}; 
    Dopts = inputdlg(Dprompt,dlg_title,num_lines,Dopts);
end

% If a parameter file with file ending is specified, call RunDotFinder with
% that specific parameter file.  Otherwise, assume it is parameter root and
% find automatically any parameter file with that root in the name. 
if isempty(strfind(Dopts{3},partype))
    parflag = 'parsroot';
else
    parflag = 'parsfile';
end
    
k = strfind(daxfile,filesep);
fpath = daxfile(1:k(end));
RunDotFinder('path',fpath,'batchsize',eval(Dopts{1}),'daxroot',Dopts{2},...
     parflag,Dopts{3},'overwrite',eval(Dopts{4}),'method',method);

%% if DaoSTORM needs to use non_temp parameters!! 




% I think these have been deleted {
function currentpath_Callback(hObject, eventdata, handles)

function currentpath_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
%  }




% --- Executes during object creation, after setting all properties.
function FrameSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end

% --- Executes during object creation, after setting all properties.
function currframe_CreateFcn(hObject, eventdata, handles)
% hObject    handle to currframe (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function FitMethod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FitMethod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --------------------------------------------------------------------
function MenuFile_Callback(hObject, eventdata, handles)
% hObject    handle to MenuFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function MenuAnalysis_Callback(hObject, eventdata, handles)
% hObject    handle to MenuAnalysis (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function ComputeZcal_Callback(hObject, eventdata, handles)
% hObject    handle to ComputeZcal (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

global daxfile inifile

 AutoZcal(daxfile,'inifile',inifile);
