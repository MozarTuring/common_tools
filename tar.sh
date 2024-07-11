dir_name=$(dirname $1)

base_name=$(basename $1)

cd $dir_name


tar -czvf $base_name.tar.gz $base_name