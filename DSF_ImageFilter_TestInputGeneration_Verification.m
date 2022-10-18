% reading image
c =imread("42474-national-park-icon.png");
g = 1; % gaussian or median
%conversion into gray scale
c = im2gray(c);
n = load("noisy_img.mat");
% padding around image give 34x34 image
d = zeros(34);
if(g == 1)
    d(2:33,2:33) = c;
else
    d(2:33,2:33) = n.f;
end
d = uint8(d);
%conversion into binary to make coe file
b = de2bi(d',"left-msb");

d = double(d);
if(g == 1)
    for i=2:33
        for j=2:33
            fil_mat(i-1,j-1) = (1/16)*(d(i-1,j-1)+2*d(i-1,j)+d(i-1,j+1)+2*d(i,j-1)+4*d(i,j)+2*d(i,j+1)+d(i+1,j-1)+2*d(i+1,j)+d(i+1,j+1));
        end
    end
else
    for i=2:33
        for j=2:33
            fil_mat(i-1,j-1) = median([d(i-1,j-1) d(i-1,j) d(i-1,j+1) d(i,j-1) d(i,j) d(i,j+1) d(i+1,j-1) d(i+1,j) d(i+1,j+1)]);
        end
    end
end
fil_mat = uint8(fil_mat);

% hardware simulation result
fil_img = readmatrix("filtered_image.txt")';
% constructing 32x32 image from 1024 pixel values
for i = 1:32;
    fil_op(i,:) = uint8(fil_img(1+32*(i-1):32*i));
end
%plots
subplot(2,2,1)
imshow(c)
title('Original Image')
subplot(2,2,2)
imshow(n.f)
title('Input Image - Noisy')
subplot(2,2,3)
imshow(fil_mat)
title('Filtered Image-Matlab')
subplot(2,2,4)
imshow(fil_op)
title('Filtered Image-Hardware')