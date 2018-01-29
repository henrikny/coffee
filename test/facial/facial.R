# https://github.com/stoltzmaniac/ML-Image-Processing-R/tree/master/Face%20Detection
# https://github.com/informramiz/opencv-face-recognition-python
# https://github.com/davidsandberg/facenet
# https://github.com/cmusatyalab/openface

library(httr)
set_config(use_proxy(url="proxy.friend.no", port=8080))
devtools::install_github("swarm-lab/ROpenCVLite")
devtools::install_github("swarm-lab/Rvision")


library(ROpenCVLite)
library(Rvision)
library(EBImage)

my_stream <- stream(0)   # 0 will start your default webcam in general. 
my_stream
my_selfie <- readNext(my_stream)
release(my_stream)
plot(my_selfie)
str(my_selfie)
dim(my_selfie)
as.list(my_selfie)[[1]]

x <- as.array(my_selfie)
str(x)
y <- EBImage::Image(x, colormode = "Color", dim = c(720, 1280, 3))
y <- normalize(y)
y <- rotate(y, angle = 90)
display(y, method = "raster", all = TRUE)
y

z <- imageData(x)
zz <- Image(z, colormode = "Color")
zz <- normalize(zz)
zz <- rotate(zz, angle = 90)
display(zz, method = "raster", all = TRUE, interpolate = TRUE)
zz

## matrices corresponding to red, green and blue color channels
r <- zz[,,3]
g <- zz[,,2]
b <- zz[,,1]
img <- rgbImage(r, g, b)
display(img, method = "raster", all = TRUE)





## colorMode example
xx = readImage(system.file('images', 'nuclei.tif', package='EBImage'))
xx = xx[,,1:3]
xx
display(xx, title='Cell nuclei', method = "raster", all = TRUE)
display(xx, title='Cell nuclei', method = "raster", all = FALSE)
colorMode(xx) = Color
display(xx, title='Cell nuclei in RGB', method = "raster")



# The main.R file:
# Calls my user-defined function
# Runs the Python script:
# Reads new image into R
# Displays both images

# Take a picture and save it
img = webcamImage(rollFrames = 10, 
                  showImage = FALSE,
                  saveImageToWD = 'originalWebcamShot.png')

# Run Python script to detect faces, draw rectangles, return new image
system('python3 facialRecognition.py')

# Read in new image
img.face = readImg("modifiedWebcamShot.png")

# Display images
imshow(img)
imshow(img.face)

