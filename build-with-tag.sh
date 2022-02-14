#! /usr/bin/env sh
git=0
docker=0
name="banzaicloud"
image="kafka"

while test $# -gt 0
do
    case "$1" in
        --git-push)
            echo "git-push=enabled"
            git=1
            ;;
        --docker-push)
            echo "docker-push=enabled"
            docker=1
            ;;
        --name)
            name=$2
            shift
            echo "name=$name"
            ;;
        --image)
            image=$2
            shift
            echo "image=$image"
            ;;
    esac
    shift
done

git fetch --all
git merge

scalas=$(awk '/scala_version=/' < ./Dockerfile | cut -c 19-)
# I guess the first occurence is enough as it doesn't make much sense I think to use
# different scala and kafka versions between the images.
scala=$(echo $scalas | awk '{split($0,a," "); print a[1]; exit}')
kafka=$(awk '/kafka_version=/{print; exit}' < ./Dockerfile | cut -c 19-)
major=$(awk -F. '{print $1}' < ./VERSION)
minor=$(awk -F. '{print $2}' < ./VERSION)
patch=$(awk -F. '{print $3}' < ./VERSION)
build=$(awk -F. '{print $4}' < ./VERSION)
build=$((build+1))
version="$major.$minor.$patch.$build"
tag="$scala-$kafka-bzc"

echo "$version" > ./VERSION

if [ $git -gt 0 ]
then
  branch=$(git rev-parse --abbrev-ref HEAD)
  git add -A
  git commit -m "version: $version"
  git push origin "$branch"
fi

docker build -t "$name"/"$image":"$tag"-latest .
docker tag "$name"/"$image":"$tag"-latest "$name"/"$image":"$tag"."$build"

if [ $docker -gt 0 ]
then
  docker push "$name"/"$image":"$tag"-latest
  docker push "$name"/"$image":"$tag"."$build"
fi
