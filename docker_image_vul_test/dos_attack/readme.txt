# to perform attack on the container which is build on this directory use follow below steps : 
1) build the image by following command : 
	docker build -t dosperform .
2) run a container for this image using below command : 
	docker run -itd -p50010:5000 --name dosattack dosperform
3) make a attack using hey module which is available in the linux
	hey -n 10000 -c 100 http://localhost:50010/

