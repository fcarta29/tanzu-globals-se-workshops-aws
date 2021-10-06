build:
	TAG=`git rev-parse --short=8 HEAD`; \
	docker build --rm -f build-eduk8s-tanzu-workshop.dockerfile -t fcarta29/eduk8s-tanzu-workshop:$$TAG .; \
	docker tag fcarta29/eduk8s-tanzu-workshop:$$TAG fcarta29/eduk8s-tanzu-workshop:latest
	#docker build --rm -f build-eduk8s-tanzu-workshop.dockerfile -t harbor.tanzu.frankcarta.com/builders/eduk8s-tanzu-workshop:$$TAG .; \
	#docker tag harbor.tanzu.frankcarta.com/builders/eduk8s-tanzu-workshop:$$TAG harbor.tanzu.frankcarta.com/builders/eduk8s-tanzu-workshop:latest


clean:
	docker stop build-eduk8s-tanzu-workshop
	docker rm build-eduk8s-tanzu-workshop

rebuild: clean build

run:
	docker run --name build-eduk8s-tanzu-workshop -td harbor.tanzu.frankcarta.com/builders/eduk8s-tanzu-workshop:latest
	docker exec -it build-eduk8s-tanzu-workshop bash -l
join:
	docker exec -it build-eduk8s-tanzu-workshop bash -l
start:
	docker start build-eduk8s-tanzu-workshop
stop:
	docker stop build-eduk8s-tanzu-workshop

push:
	TAG=`git rev-parse --short=8 HEAD`; \
	docker push fcarta29/eduk8s-tanzu-workshop:$$TAG; \
	docker push fcarta29/eduk8s-tanzu-workshop:latest
	#docker push harbor.tanzu.frankcarta.com/builders/eduk8s-tanzu-workshop:$$TAG; \
	#docker push harbor.tanzu.frankcarta.com/builders/eduk8s-tanzu-workshop:latest

default: build
