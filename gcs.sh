
%%bash
gcloud auth login
gcloud config set project my-project-nov02


echo "deb http://packages.cloud.google.com/apt gcsfuse-bionic main" > /etc/apt/sources.list.d/gcsfuse.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -apt -qq update
apt -qq install gcsfuse
mkdir -p /gcs
gcsfuse mjwbucket1 /gcs


curl -L https://image-net.org/data/ILSVRC/2012/ILSVRC2012_img_train.tar | gsutil cp - gs://mjwbucket1/data/ILSVRC2012_img_train.tar


gsutil ls -lh gs://mjwbucket1/data
