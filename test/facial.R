library(httr)
set_config(use_proxy(url="proxy.friend.no", port=8080))
devtools::install_github("swarm-lab/ROpenCVLite")
devtools::install_github("swarm-lab/Rvision")



library(ROpenCVLite)
library(Rvision)

my_stream <- stream(0)   # 0 will start your default webcam in general. 
my_stream
my_selfie <- readNext(my_stream)
plot(my_selfie)
release(my_stream)

# https://github.com/stoltzmaniac/ML-Image-Processing-R/tree/master/Face%20Detection