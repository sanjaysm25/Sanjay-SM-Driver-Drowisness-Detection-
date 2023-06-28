clc;
clear all;
close all;


[filename, folder] = uigetfile({'*.jpg;*.jpeg;*.png;*.bmp'}, 'Select Image');
if isequal(filename, 0)
    disp('Image selection cancelled');
    return;
end

imagePath = fullfile(folder, filename);
Input = imread(imagePath);

if (size(Input, 3) == 3)
    GrayImage = rgb2gray(Input);
else
    GrayImage = Input;
end

faceDetector = vision.CascadeObjectDetector;
BB = step(faceDetector, GrayImage);

if (isempty(BB))
    msgbox('No faces are detected', 'Warning', 'warn', 'none');
    return;
else
    numFaces = size(BB, 1);  

    for i = 1:numFaces
        FaceImage = imcrop(GrayImage, BB(i, :));

        RGB = insertObjectAnnotation(Input, 'rectangle', BB(i, :), ['Face ', num2str(i)], 'Color', 'blue');
        figure;
        imshow(RGB);
    end
end


EyePair = vision.CascadeObjectDetector('EyePairBig');
BB_Pair = step(EyePair, FaceImage);

if (isempty(BB_Pair))
    msgbox('Eye is not detected', 'Warning', 'warn', 'none');
    return;
end

BB_Pair(1, 1) = BB(1, 1) + BB_Pair(1, 1);
BB_Pair(1, 2) = BB(1, 2) + BB_Pair(1, 2);
EyePair_Image = imcrop(GrayImage, BB_Pair(1, :));
RGB = insertObjectAnnotation(Input, 'rectangle', BB_Pair(1, :), 'Eye Pair', 'Color', 'green');
figure;
imshow(RGB);


LeftEye_Image = EyePair_Image(:, 1:round(BB_Pair(1, 3) / 2));
RightEye_Image = EyePair_Image(:, round(BB_Pair(1, 3) / 2):end);

Nose_Detect = vision.CascadeObjectDetector('Nose', 'MergeThreshold', 16);
BB_N = step(Nose_Detect, FaceImage);

if (isempty(BB_N))
    msgbox('Nose is not detected', 'Warning', 'warn', 'none');
    return;
end

BB_N(1, 1) = BB_N(1, 1) + BB(1, 1);
BB_N(1, 2) = BB_N(1, 2) + BB(1, 2);
Nose_Image = imcrop(GrayImage, BB_N(1, :));
RGB = insertObjectAnnotation(Input, 'rectangle', BB_N(1, :), 'Nose', 'Color', 'magenta');
figure;
imshow(RGB);


Mouth_Detect = vision.CascadeObjectDetector('Mouth', 'MergeThreshold', 16);
BB_M = step(Mouth_Detect, FaceImage);

if (isempty(BB_M))
    msgbox('Mouth is not detected', 'Warning', 'warn', 'none');
    return;
end

for l = 1:size(BB_M, 1)
    BB_M(l, 1) = BB_M(l, 1) + BB(1, 1);
    BB_M(l, 2) = BB_M(l, 2) + BB(1, 2);

    if (BB_M(l, 2) > BB_N(1, 2))
        BB_Mouth = BB_M(l, :);
    end
end

Mouth_Image = imcrop(GrayImage, BB_Mouth);
RGB = insertObjectAnnotation(Input, 'rectangle', BB_Mouth, 'Mouth', 'Color', 'white');
figure;
imshow(RGB);

out = FuzzyLogic(RightEye_Image, LeftEye_Image);

if (out == 1)
    
    h = msgbox('The driver is drowsy', 'Warning', 'warn', 'none');
    set(h, 'Color', 'r');

    hText = findobj(h, 'Type', 'Text');
    set(hText, 'FontSize', 14);  
    
    jFrame = get(handle(h), 'JavaFrame');
    
   
    numBlinks = 10;
    blinkInterval = 0.1; 

    for i = 1:numBlinks
        
        jFrame.fHG2Client.getWindow.setVisible(false);
        
        pause(blinkInterval);
        
       
        jFrame.fHG2Client.getWindow.setVisible(true);
        
        pause(blinkInterval);
    end

    [audioData, sampleRate] = audioread('alarm.wav');
    
   
    player = audioplayer(audioData, sampleRate);
    
   
    play(player);
    
else
    msgbox('The driver is not drowsy', 'Safe', 'help', 'none');
end


function out = FuzzyLogic(Image1, Image2)
  
    if size(Image1, 3) == 3
        Image1 = im2gray(Image1);
    end

    if size(Image2, 3) == 3
        Image2 = im2gray(Image2);
    end

    BW_Image1 = ~im2bw(Image1, 0.5);
    figure;
    imshow(BW_Image1);
    [centers_R, radii_R, metric_R] = imfindcircles(BW_Image1, [10 20]);
    centersStrong5_R = centers_R(:,:);
    radiiStrong5_R = radii_R(:);
    metricStrong5_R = metric_R(:);
    viscircles(centersStrong5_R, radiiStrong5_R, 'EdgeColor', 'b');

    figure;
    imshow(Image2);
    BW_Image2 = ~im2bw(Image2, graythresh(Image2));
    [centers_L, radii_L, metric_L] = imfindcircles(BW_Image2, [10 20]);
    centersStrong5_L = centers_L(:,:);
    radiiStrong5_L = radii_L(:);
    metricStrong5_L = metric_L(:);
    viscircles(centersStrong5_L, radiiStrong5_L, 'EdgeColor', 'b');

    if (isempty(radii_R) && isempty(radii_L))
        beep;
        pause(1);
        out = 1;
    else
        out = 0;
    end
end
