aws ecr get-login-password --region ap-northeast-2 --profile leakautomation-docker-deploy | docker login --username AWS --password-stdin $1

docker build -t leakautomation .

docker tag leakautomation:latest $1/leakautomation:latest

docker push $1/leakautomation:latest