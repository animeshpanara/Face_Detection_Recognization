function varargout = Multiplefacedetection(varargin)
% MULTIPLEFACEDETECTION MATLAB code for Multiplefacedetection.fig
%      MULTIPLEFACEDETECTION, by itself, creates a new MULTIPLEFACEDETECTION or raises the existing
%      singleton*.
%
%      H = MULTIPLEFACEDETECTION returns the handle to a new MULTIPLEFACEDETECTION or the handle to
%      the existing singleton*.
%
%      MULTIPLEFACEDETECTION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in MULTIPLEFACEDETECTION.M with the given input arguments.
%
%      MULTIPLEFACEDETECTION('Property','Value',...) creates a new MULTIPLEFACEDETECTION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Multiplefacedetection_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Multiplefacedetection_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Multiplefacedetection

% Last Modified by GUIDE v2.5 16-Apr-2017 23:37:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Multiplefacedetection_OpeningFcn, ...
                   'gui_OutputFcn',  @Multiplefacedetection_OutputFcn, ...
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


% --- Executes just before Multiplefacedetection is made visible.
function Multiplefacedetection_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Multiplefacedetection (see VARARGIN)

% Choose default command line output for Multiplefacedetection
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Multiplefacedetection wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = Multiplefacedetection_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in start.
function start_Callback(hObject, eventdata, handles)
% hObject    handle to start (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global x;
x=webcam();
frame=snapshot(x);
frameSize=size(frame);
facedetector = vision.CascadeObjectDetector;
X=vision.VideoPlayer('Position',[100 100 [frameSize(2),frameSize(1)]+100]);
while(1)                                         
    img = snapshot(x);
    bbox = step(facedetector, img);
    hello = insertObjectAnnotation(img,'rectangle',bbox,'Face');
    step(X,hello);
end


% --- Executes on button press in Stop.
function Stop_Callback(hObject, eventdata, handles)
% hObject    handle to Stop (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in detect.
function detect_Callback(hObject, eventdata, handles)
% hObject    handle to detect (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = inputdlg('enter no. of faces to be detected:')
answer=answer{1};
answer=str2num(answer);
cam=webcam();

frame = snapshot(cam);
frameSize = size(frame);
himage=image(zeros(frameSize(1),frameSize(2), 3),'parent', handles.axes1);
NotYet = false;
preview(cam,himage);

faceDetector = vision.CascadeObjectDetector;

pause(5);
while ~NotYet
    I = snapshot(cam);
    faceDetector.MergeThreshold=5;
    bboxes = step(faceDetector,I);
    if size(bboxes,1)==answer
        NotYet = true;
    break;
    end
end
closePreview(cam);
%clear('cam');

IFaces = insertObjectAnnotation(I, 'rectangle', bboxes, 'Face');
figure, imshow(IFaces), title('Detected faces');

faceGallery = imageSet('gallery', 'recursive');
galleryNames = {faceGallery.Description};

trainingFeatures = zeros(2,10404);
featureCount = 1;
for i=1:size(faceGallery,2)
    for j = 1:faceGallery(i).Count        
        sizeNormalizedImage = imresize(rgb2gray(read(faceGallery(i),j)),[150 150]);
        trainingFeatures(featureCount,:) = extractHOGFeatures(sizeNormalizedImage);
        trainingLabel{featureCount} = faceGallery(i).Description;   
        featureCount = featureCount + 1;
    end
    personIndex{i} = faceGallery(i).Description;
end

Img = cell(1,size(bboxes,1));

for i = 1:size(bboxes,1)
     J= imcrop(I,[bboxes(i,1)-20 bboxes(i,2)-20 bboxes(i,3)+20 bboxes(i,4)+20]);
     scale=150/size(J,1);
     Img{i}=imresize(J,scale);
end

% Create Classifier 
faceClassifier = fitcecoc(trainingFeatures,trainingLabel)
 figure;
for  i= 1: length(Img)
        queryImage = Img{i};
        sizeNormalizedImage = imresize(rgb2gray(queryImage),[150 150]);
        %figure;imshow(sizeNormalizedImage)
        queryFeatures = extractHOGFeatures(sizeNormalizedImage);
        [personLabel] = predict(faceClassifier,queryFeatures);
        booleanIndex = strcmp(personLabel, personIndex);
        integerIndex = find(booleanIndex);
        
        subplot(2,2,i)
        imshow(queryImage);title(personLabel);
 end
 %imshow(~zeros(frameSize(1),frameSize(2), 3),'parent', handles.axes1);

% --- Executes on button press in train.
function train_Callback(hObject, eventdata, handles)
% hObject    handle to train (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
answer = inputdlg('Enter name:');
if isempty(answer)
else
    answer=answer{1};    
    cd gallery
    mkdir(answer);
    cam=webcam();
    frame = snapshot(cam);
    frameSize = size(frame);
    himage=image(zeros(frameSize(1),frameSize(2), 3),'parent', handles.axes1);
    preview(cam,himage);
    NotYet = 0;
    faceDetector = vision.CascadeObjectDetector;
    while NotYet<50
        pause(0.1);
        I = snapshot(cam);
        disp('took a snapshot. checking to find a face ....')
        bboxes = step(faceDetector, I);
        if ~isempty(bboxes)
             NotYet = NotYet+1;
             disp('face found!');
             J= imcrop(I,[bboxes(1)-20 bboxes(2)-20 bboxes(3)+20 bboxes(4)+20]);
             scale=150/size(J,1);
             J=imresize(J,scale);
             pathname='C:\abhi\facedetection\gallery\';
             pathname=strcat(pathname,strcat(answer,'\'))
             imwrite(J,[pathname, 'data',num2str(NotYet),'.jpg'])
        end
        disp('no face detected :(, repeating...');
    end
    closePreview(cam);
    clear('cam');
    cd ..
end
