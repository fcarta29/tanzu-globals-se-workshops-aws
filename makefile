build:
	TAG=`git rev-parse --short=8 HEAD`; \
	docker build --rm -f build-tanzu-globals-se-workshops.dockerfile -t harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:$$TAG .; \
	docker tag harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:$$TAG harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:latest

clean:
	docker stop build-tanzu-globals-se-workshops
	docker rm build-tanzu-globals-se-workshops

rebuild: clean build

run:
	docker run --name build-tanzu-globals-se-workshops -v $$PWD/deploy:/deploy -v $$PWD/config/kube.conf:/root/.kube/config -td harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:latest
	docker exec -it build-tanzu-globals-se-workshops bash -l
demo: 
	docker run --name build-tanzu-globals-se-workshops -p 8080-8090:8080-8090 -v $$PWD/deploy:/deploy -v $$PWD/config/kube.conf:/root/.kube/config -td harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:latest
	docker exec -it build-tanzu-globals-se-workshops bash -l
join:
	docker exec -it build-tanzu-globals-se-workshops bash -l
start:
	docker start build-tanzu-globals-se-workshops
stop:
	docker stop build-tanzu-globals-se-workshops

push:
	TAG=`git rev-parse --short=8 HEAD`; \
	docker push harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:$$TAG; \
	docker push harbor.tanzu.frankcarta.com/builders/tanzu-globals-se-workshop:latest

default: build
